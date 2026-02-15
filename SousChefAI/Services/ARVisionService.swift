//
//  ARVisionService.swift
//  SousChefAI
//
//  AR-based vision service using RealityKit and ARKit
//  Provides real-time plane detection and raycasting capabilities
//

import Foundation
import SwiftUI
import RealityKit
import ARKit
@preconcurrency import CoreVideo

/// AR-based implementation for vision and spatial scanning
final class ARVisionService: VisionService, @unchecked Sendable {
    
    nonisolated init() {}
    
    // MARK: - VisionService Protocol Implementation
    
    nonisolated func detectIngredients(from stream: AsyncStream<CVPixelBuffer>) async throws -> [Ingredient] {
        // Mock implementation - in a real app, this would use ML models
        // to detect ingredients from AR camera frames
        var detectedIngredients: [Ingredient] = []
        var frameCount = 0
        
        for await pixelBuffer in stream {
            frameCount += 1
            
            // Process every 30th frame to reduce processing load
            if frameCount % 30 == 0 {
                let ingredients = try await processARFrame(pixelBuffer)
                
                // Merge results
                for ingredient in ingredients {
                    if !detectedIngredients.contains(where: { $0.name == ingredient.name }) {
                        detectedIngredients.append(ingredient)
                    }
                }
                
                // Stop after collecting enough ingredients
                if detectedIngredients.count >= AppConfig.maxIngredientsPerScan {
                    break
                }
            }
        }
        
        return detectedIngredients
            .filter { $0.confidence >= AppConfig.minConfidenceThreshold }
            .sorted { $0.confidence > $1.confidence }
    }
    
    nonisolated func detectIngredients(from pixelBuffer: CVPixelBuffer) async throws -> [Ingredient] {
        return try await processARFrame(pixelBuffer)
    }
    
    nonisolated func analyzeCookingProgress(from stream: AsyncStream<CVPixelBuffer>, for step: String) async throws -> CookingProgress {
        // Mock implementation for cooking progress monitoring
        return CookingProgress(
            isComplete: false,
            confidence: 0.5,
            feedback: "Monitoring cooking progress..."
        )
    }
    
    // MARK: - Private Helper Methods
    
    nonisolated private func processARFrame(_ pixelBuffer: CVPixelBuffer) async throws -> [Ingredient] {
        // Mock ingredient detection
        // In a real implementation, this would use Vision framework or ML models
        // to detect objects in the AR camera feed
        
        // For now, return empty array - actual detection would happen here
        return []
    }
}

/// SwiftUI wrapper for ARView with plane detection and raycasting
struct ARViewContainer: UIViewRepresentable {
    @Binding var detectedPlanes: Int
    @Binding var lastRaycastResult: String
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        
        // Enable plane detection for horizontal and vertical surfaces
        configuration.planeDetection = [.horizontal, .vertical]
        
        // Enable scene reconstruction for better spatial understanding
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        // Enable debug options to visualize detected planes
        arView.debugOptions = [.showSceneUnderstanding, .showWorldOrigin]
        
        // Set the coordinator as the session delegate
        arView.session.delegate = context.coordinator
        
        // Run the AR session
        arView.session.run(configuration)
        
        // Add tap gesture for raycasting
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        context.coordinator.arView = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Update UI if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(detectedPlanes: $detectedPlanes, lastRaycastResult: $lastRaycastResult)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, ARSessionDelegate {
        @Binding var detectedPlanes: Int
        @Binding var lastRaycastResult: String
        weak var arView: ARView?
        private var detectedPlaneAnchors: Set<UUID> = []
        
        init(detectedPlanes: Binding<Int>, lastRaycastResult: Binding<String>) {
            _detectedPlanes = detectedPlanes
            _lastRaycastResult = lastRaycastResult
        }
        
        // MARK: - ARSessionDelegate Methods
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    detectedPlaneAnchors.insert(planeAnchor.identifier)
                    DispatchQueue.main.async {
                        self.detectedPlanes = self.detectedPlaneAnchors.count
                    }
                }
            }
        }
        
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            // Planes are being updated as AR refines understanding
        }
        
        func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    detectedPlaneAnchors.remove(planeAnchor.identifier)
                    DispatchQueue.main.async {
                        self.detectedPlanes = self.detectedPlaneAnchors.count
                    }
                }
            }
        }
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            print("AR Session failed: \(error.localizedDescription)")
        }
        
        // MARK: - Raycasting
        
        /// Performs a raycast from screen center to detect planes
        func performRaycast(from point: CGPoint, in view: ARView) -> ARRaycastResult? {
            // Create raycast query targeting estimated planes
            guard let query = view.makeRaycastQuery(
                from: point,
                allowing: .estimatedPlane,
                alignment: .any
            ) else {
                return nil
            }
            
            // Perform the raycast
            let results = view.session.raycast(query)
            return results.first
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            
            let location = gesture.location(in: arView)
            
            if let result = performRaycast(from: location, in: arView) {
                let position = result.worldTransform.columns.3
                let resultString = String(format: "Hit at: (%.2f, %.2f, %.2f)", position.x, position.y, position.z)
                
                DispatchQueue.main.async {
                    self.lastRaycastResult = resultString
                }
                
                // Place a visual marker at the hit location
                placeMarker(at: result.worldTransform, in: arView)
            } else {
                DispatchQueue.main.async {
                    self.lastRaycastResult = "No surface detected"
                }
            }
        }
        
        private func placeMarker(at transform: simd_float4x4, in arView: ARView) {
            // Create a small sphere to visualize the raycast hit
            let sphere = MeshResource.generateSphere(radius: 0.02)
            let material = SimpleMaterial(color: .green, isMetallic: false)
            let modelEntity = ModelEntity(mesh: sphere, materials: [material])
            
            // Create an anchor at the hit position
            let anchorEntity = AnchorEntity(world: transform)
            anchorEntity.addChild(modelEntity)
            
            arView.scene.addAnchor(anchorEntity)
        }
    }
}
