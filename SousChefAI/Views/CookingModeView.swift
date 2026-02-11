//
//  CookingModeView.swift
//  SousChefAI
//
//  Live cooking mode with AI-powered visual monitoring and guidance
//

import SwiftUI
import AVFoundation

struct CookingModeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CookingModeViewModel
    @State private var showingAllSteps = false
    
    init(recipe: Recipe) {
        _viewModel = StateObject(wrappedValue: CookingModeViewModel(recipe: recipe))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Camera preview background
                if viewModel.isMonitoring {
                    CameraPreviewView(previewLayer: viewModel.getPreviewLayer())
                        .ignoresSafeArea()
                        .opacity(0.3)
                }
                
                // Main content
                VStack(spacing: 0) {
                    // Progress bar
                    progressBar
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Current step card
                            currentStepCard
                            
                            // AI feedback card
                            if viewModel.isMonitoring {
                                aiFeedbackCard
                            }
                            
                            // Controls
                            controlButtons
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Cooking Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Exit") {
                        viewModel.cleanup()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAllSteps = true
                    } label: {
                        Label("All Steps", systemImage: "list.bullet")
                    }
                }
            }
            .task {
                await viewModel.setupCamera()
                viewModel.startCamera()
            }
            .onDisappear {
                viewModel.cleanup()
            }
            .sheet(isPresented: $showingAllSteps) {
                AllStepsSheet(
                    steps: viewModel.recipe.steps,
                    currentStep: viewModel.currentStepIndex
                )
            }
        }
    }
    
    // MARK: - UI Components
    
    private var progressBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Step \(viewModel.currentStepIndex + 1) of \(viewModel.recipe.steps.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(Int(viewModel.progress * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            }
            
            ProgressView(value: viewModel.progress)
                .tint(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var currentStepCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Current Step")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                Spacer()
                
                if viewModel.stepComplete {
                    Label("Complete", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            
            Text(viewModel.currentStep)
                .font(.title3)
                .fontWeight(.semibold)
                .fixedSize(horizontal: false, vertical: true)
            
            // Speak button
            Button {
                viewModel.speakCurrentStep()
            } label: {
                Label("Read Aloud", systemImage: "speaker.wave.2.fill")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var aiFeedbackCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                
                Text("AI Assistant")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                Spacer()
                
                if viewModel.confidence > 0 {
                    Text("\(Int(viewModel.confidence * 100))%")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(confidenceColor)
                        .clipShape(Capsule())
                }
            }
            
            Text(viewModel.feedback)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            
            if viewModel.isMonitoring {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Monitoring...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var controlButtons: some View {
        VStack(spacing: 12) {
            // AI monitoring toggle
            if !viewModel.isComplete {
                if viewModel.isMonitoring {
                    Button {
                        viewModel.stopMonitoring()
                    } label: {
                        Label("Stop AI Monitoring", systemImage: "eye.slash.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else {
                    Button {
                        viewModel.startMonitoring()
                    } label: {
                        Label("Start AI Monitoring", systemImage: "eye.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            
            // Navigation buttons
            HStack(spacing: 12) {
                Button {
                    viewModel.previousStep()
                } label: {
                    Label("Previous", systemImage: "arrow.left")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(viewModel.currentStepIndex == 0)
                
                if viewModel.isComplete {
                    Button {
                        viewModel.cleanup()
                        dismiss()
                    } label: {
                        Label("Finish", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else {
                    Button {
                        viewModel.nextStep()
                    } label: {
                        Label("Next Step", systemImage: "arrow.right")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.stepComplete ? Color.green : Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }
    
    private var confidenceColor: Color {
        if viewModel.confidence >= 0.8 {
            return .green
        } else if viewModel.confidence >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - All Steps Sheet

struct AllStepsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let steps: [String]
    let currentStep: Int
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        // Step number
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(index == currentStep ? Color.blue : Color.gray)
                            .clipShape(Circle())
                        
                        // Step text
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if index == currentStep {
                                Text("Current Step")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            } else if index < currentStep {
                                Text("Completed")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("All Steps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CookingModeView(recipe: Recipe(
        title: "Scrambled Eggs",
        description: "Simple and delicious scrambled eggs",
        steps: [
            "Crack 3 eggs into a bowl",
            "Add a splash of milk and whisk until combined",
            "Heat butter in a non-stick pan over medium heat",
            "Pour eggs into the pan",
            "Gently stir with a spatula until soft curds form",
            "Season with salt and pepper",
            "Serve immediately while hot"
        ],
        matchScore: 0.95
    ))
}
