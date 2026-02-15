//
//  ScannerViewModel.swift
//  SousChefAI
//
//  ViewModel for the scanner view with real-time ingredient detection
//

import Foundation
import SwiftUI
import CoreVideo
import AVFoundation
import Combine

@MainActor
final class ScannerViewModel: ObservableObject {
    
    @Published var detectedIngredients: [Ingredient] = []
    @Published var isScanning = false
    @Published var error: Error?
    @Published var scanProgress: String = "Ready to scan"
    
    private let visionService: VisionService
    private let cameraManager: CameraManager
    private var scanTask: Task<Void, Never>?
    
    nonisolated init(visionService: VisionService = ARVisionService(),
                     cameraManager: CameraManager = CameraManager()) {
        self.visionService = visionService
        self.cameraManager = cameraManager
    }
    
    // MARK: - Camera Management
    
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
    
    // MARK: - Scanning
    
    func startScanning() {
        guard !isScanning else { return }
        
        isScanning = true
        detectedIngredients.removeAll()
        scanProgress = "Scanning ingredients..."
        
        scanTask = Task {
            do {
                let stream = cameraManager.frameStream()
                let ingredients = try await visionService.detectIngredients(from: stream)
                
                updateDetectedIngredients(ingredients)
                scanProgress = "Scan complete! Found \(ingredients.count) ingredients"
            } catch {
                self.error = error
                scanProgress = "Scan failed"
            }
            
            isScanning = false
        }
    }
    
    func stopScanning() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
        scanProgress = detectedIngredients.isEmpty ? "Ready to scan" : "Scan captured"
    }
    
    // MARK: - Real-time Detection Mode
    
    func startRealTimeDetection() {
        guard !isScanning else { return }
        
        isScanning = true
        scanProgress = "Detecting in real-time..."
        
        scanTask = Task {
            let stream = cameraManager.frameStream()
            
            for await frame in stream {
                guard !Task.isCancelled else { break }
                
                do {
                    // Process individual frames
                    let ingredients = try await visionService.detectIngredients(from: frame)
                    updateDetectedIngredients(ingredients, mergeMode: true)
                    
                    scanProgress = "Detected \(detectedIngredients.count) items"
                } catch {
                    // Continue on errors in real-time mode
                    continue
                }
                
                // Throttle to avoid overwhelming the API
                try? await Task.sleep(for: .seconds(1))
            }
            
            isScanning = false
        }
    }
    
    // MARK: - Ingredient Management
    
    private func updateDetectedIngredients(_ newIngredients: [Ingredient], mergeMode: Bool = false) {
        if mergeMode {
            // Merge with existing ingredients, keeping higher confidence
            var merged = detectedIngredients.reduce(into: [String: Ingredient]()) { dict, ingredient in
                dict[ingredient.name] = ingredient
            }
            
            for ingredient in newIngredients {
                if let existing = merged[ingredient.name] {
                    if ingredient.confidence > existing.confidence {
                        merged[ingredient.name] = ingredient
                    }
                } else {
                    merged[ingredient.name] = ingredient
                }
            }
            
            detectedIngredients = Array(merged.values).sorted { $0.confidence > $1.confidence }
        } else {
            detectedIngredients = newIngredients
        }
    }
    
    func addIngredient(_ ingredient: Ingredient) {
        if !detectedIngredients.contains(where: { $0.id == ingredient.id }) {
            detectedIngredients.append(ingredient)
        }
    }
    
    func removeIngredient(_ ingredient: Ingredient) {
        detectedIngredients.removeAll { $0.id == ingredient.id }
    }
    
    func updateIngredient(_ ingredient: Ingredient) {
        if let index = detectedIngredients.firstIndex(where: { $0.id == ingredient.id }) {
            detectedIngredients[index] = ingredient
        }
    }
    
    // MARK: - Manual Entry
    
    func addManualIngredient(name: String, quantity: String) {
        let ingredient = Ingredient(
            name: name,
            estimatedQuantity: quantity,
            confidence: 1.0
        )
        detectedIngredients.append(ingredient)
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        stopScanning()
        stopCamera()
    }
}
