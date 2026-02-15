//
//  ScannerView.swift
//  SousChefAI
//
//  AR camera view for scanning and detecting ingredients in real-time
//

import SwiftUI
import ARKit
import RealityKit

struct ScannerView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @State private var showingInventory = false
    @State private var showingManualEntry = false
    @State private var detectedPlanes = 0
    @State private var lastRaycastResult = ""
    @State private var showARView = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // AR camera preview or regular camera
                if showARView {
                    ARViewContainer(
                        detectedPlanes: $detectedPlanes,
                        lastRaycastResult: $lastRaycastResult
                    )
                    .ignoresSafeArea()
                } else {
                    CameraPreviewView(previewLayer: viewModel.getPreviewLayer())
                        .ignoresSafeArea()
                }
                
                // Overlay UI
                VStack {
                    // Top status bar
                    statusBar
                        .padding()
                    
                    // AR Debug info (only when AR is active)
                    if showARView {
                        arDebugInfo
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Detected ingredients list
                    if !viewModel.detectedIngredients.isEmpty {
                        detectedIngredientsOverlay
                    }
                    
                    // Bottom controls
                    controlsBar
                        .padding()
                }
            }
            .navigationTitle(showARView ? "AR Scanner" : "Camera Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingManualEntry = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
            .task {
                if !showARView {
                    await viewModel.setupCamera()
                    viewModel.startCamera()
                }
            }
            .onDisappear {
                viewModel.cleanup()
            }
            .alert("Camera Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
            .sheet(isPresented: $showingManualEntry) {
                ManualIngredientEntry { name, quantity in
                    viewModel.addManualIngredient(name: name, quantity: quantity)
                }
            }
            .navigationDestination(isPresented: $showingInventory) {
                InventoryView(ingredients: viewModel.detectedIngredients)
            }
        }
    }
    
    // MARK: - UI Components
    
    private var statusBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(showARView ? "AR Mode Active" : viewModel.scanProgress)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                if viewModel.isScanning {
                    ProgressView()
                        .tint(.white)
                }
            }
            
            Spacer()
            
            Text("\(viewModel.detectedIngredients.count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var arDebugInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Detected Planes: \(detectedPlanes)")
                .font(.caption)
                .foregroundStyle(.white)
            
            if !lastRaycastResult.isEmpty {
                Text(lastRaycastResult)
                    .font(.caption2)
                    .foregroundStyle(.white)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var detectedIngredientsOverlay: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.detectedIngredients.prefix(5)) { ingredient in
                    IngredientChip(ingredient: ingredient)
                }
                
                if viewModel.detectedIngredients.count > 5 {
                    Text("+\(viewModel.detectedIngredients.count - 5) more")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }
    
    private var controlsBar: some View {
        VStack(spacing: 16) {
            // AR Toggle button
            if !viewModel.isScanning {
                Button {
                    withAnimation {
                        showARView.toggle()
                        if !showARView {
                            viewModel.startCamera()
                        } else {
                            viewModel.stopCamera()
                        }
                    }
                } label: {
                    Label(showARView ? "Exit AR Mode" : "Start AR Scan", systemImage: showARView ? "camera.fill" : "arkit")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(showARView ? Color.orange : Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            
            // Main scanning action button (only in non-AR mode)
            if !showARView {
                if viewModel.isScanning {
                    Button {
                        viewModel.stopScanning()
                    } label: {
                        Label("Stop Scanning", systemImage: "stop.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                } else {
                    Button {
                        viewModel.startScanning()
                    } label: {
                        Label("Detect Ingredients", systemImage: "camera.viewfinder")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            
            // Secondary actions
            if !viewModel.detectedIngredients.isEmpty {
                Button {
                    showingInventory = true
                } label: {
                    Label("Continue to Inventory", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Camera Preview

struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            previewLayer.frame = uiView.bounds
        }
    }
}

// MARK: - Ingredient Chip

struct IngredientChip: View {
    let ingredient: Ingredient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(ingredient.name)
                .font(.caption)
                .fontWeight(.semibold)
            
            Text(ingredient.estimatedQuantity)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(ingredient.needsVerification ? Color.orange.opacity(0.9) : Color.green.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Manual Entry Sheet

struct ManualIngredientEntry: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var quantity = ""
    
    let onAdd: (String, String) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Ingredient Details") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Quantity (e.g., 2 cups, 500g)", text: $quantity)
                }
            }
            .navigationTitle("Add Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(name, quantity)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ScannerView()
}
