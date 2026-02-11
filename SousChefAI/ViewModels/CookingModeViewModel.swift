//
//  CookingModeViewModel.swift
//  SousChefAI
//
//  ViewModel for live cooking guidance with AI monitoring
//

import Foundation
import AVFoundation
import CoreVideo
import Combine
import UIKit

@MainActor
final class CookingModeViewModel: ObservableObject {
    
    @Published var currentStepIndex = 0
    @Published var isMonitoring = false
    @Published var feedback: String = "Ready to start"
    @Published var stepComplete = false
    @Published var confidence: Double = 0.0
    @Published var error: Error?
    
    let recipe: Recipe
    private let visionService: VisionService
    private let recipeService: RecipeService
    private let cameraManager: CameraManager
    private var monitoringTask: Task<Void, Never>?
    
    var currentStep: String {
        guard currentStepIndex < recipe.steps.count else {
            return "Recipe complete!"
        }
        return recipe.steps[currentStepIndex]
    }
    
    var progress: Double {
        guard !recipe.steps.isEmpty else { return 0 }
        return Double(currentStepIndex) / Double(recipe.steps.count)
    }
    
    var isComplete: Bool {
        currentStepIndex >= recipe.steps.count
    }
    
    nonisolated init(recipe: Recipe,
                     visionService: VisionService = OvershootVisionService(),
                     recipeService: RecipeService = GeminiRecipeService(),
                     cameraManager: CameraManager = CameraManager()) {
        self.recipe = recipe
        self.visionService = visionService
        self.recipeService = recipeService
        self.cameraManager = cameraManager
    }
    
    // MARK: - Camera Setup
    
    func setupCamera() async {
        do {
            try await cameraManager.setupSession()
        } catch {
            self.error = error
        }
    }
    
    func startCamera() {
        cameraManager.startSession()
    }
    
    func stopCamera() {
        cameraManager.stopSession()
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        cameraManager.previewLayer()
    }
    
    // MARK: - Step Navigation
    
    func nextStep() {
        guard currentStepIndex < recipe.steps.count else { return }
        
        currentStepIndex += 1
        stepComplete = false
        confidence = 0.0
        feedback = currentStepIndex < recipe.steps.count ? "Starting next step..." : "Recipe complete!"
        
        if !isComplete && isMonitoring {
            // Restart monitoring for new step
            stopMonitoring()
            startMonitoring()
        }
    }
    
    func previousStep() {
        guard currentStepIndex > 0 else { return }
        
        currentStepIndex -= 1
        stepComplete = false
        confidence = 0.0
        feedback = "Returned to previous step"
        
        if isMonitoring {
            stopMonitoring()
            startMonitoring()
        }
    }
    
    // MARK: - AI Monitoring
    
    func startMonitoring() {
        guard !isComplete, !isMonitoring else { return }
        
        isMonitoring = true
        feedback = "Monitoring your cooking..."
        
        monitoringTask = Task {
            do {
                let stream = cameraManager.frameStream()
                let progress = try await visionService.analyzeCookingProgress(
                    from: stream,
                    for: currentStep
                )
                
                handleProgress(progress)
            } catch {
                self.error = error
                feedback = "Monitoring paused"
                isMonitoring = false
            }
        }
    }
    
    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
        isMonitoring = false
        feedback = "Monitoring stopped"
    }
    
    private func handleProgress(_ progress: CookingProgress) {
        confidence = progress.confidence
        feedback = progress.feedback
        stepComplete = progress.isComplete
        
        if progress.isComplete && progress.confidence > 0.8 {
            // Play haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Speak the feedback using text-to-speech
            speakFeedback("Step complete! \(progress.feedback)")
        }
    }
    
    // MARK: - Text Guidance
    
    func getTextGuidance() async {
        do {
            let guidance = try await recipeService.provideCookingGuidance(
                for: currentStep,
                context: feedback
            )
            feedback = guidance
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Text-to-Speech
    
    private func speakFeedback(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
    
    func speakCurrentStep() {
        speakFeedback(currentStep)
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        stopMonitoring()
        stopCamera()
    }
}
