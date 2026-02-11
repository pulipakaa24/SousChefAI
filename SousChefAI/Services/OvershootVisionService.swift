//
//  OvershootVisionService.swift
//  SousChefAI
//
//  Concrete implementation of VisionService using Overshoot API
//  Provides low-latency real-time video inference for ingredient detection
//

import Foundation
@preconcurrency import CoreVideo
import UIKit

/// Overshoot API implementation for vision-based ingredient detection
final class OvershootVisionService: VisionService, @unchecked Sendable {
    
    private let apiKey: String
    private let webSocketURL: URL
    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession
    
    nonisolated init(apiKey: String = AppConfig.overshootAPIKey,
                     webSocketURL: String = AppConfig.overshootWebSocketURL) {
        self.apiKey = apiKey
        guard let url = URL(string: webSocketURL) else {
            fatalError("Invalid WebSocket URL: \(webSocketURL)")
        }
        self.webSocketURL = url
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - VisionService Protocol Implementation
    
    func detectIngredients(from stream: AsyncStream<CVPixelBuffer>) async throws -> [Ingredient] {
        guard apiKey != "INSERT_KEY_HERE" else {
            throw VisionServiceError.apiKeyMissing
        }
        
        // Connect to WebSocket
        try await connectWebSocket()
        
        var detectedIngredients: [String: Ingredient] = [:]
        
        // Process frames from stream
        for await pixelBuffer in stream {
            do {
                let frameIngredients = try await processFrame(pixelBuffer)
                
                // Merge results (keep highest confidence for each ingredient)
                for ingredient in frameIngredients {
                    if let existing = detectedIngredients[ingredient.name] {
                        if ingredient.confidence > existing.confidence {
                            detectedIngredients[ingredient.name] = ingredient
                        }
                    } else {
                        detectedIngredients[ingredient.name] = ingredient
                    }
                }
                
                // Limit to max ingredients
                if detectedIngredients.count >= AppConfig.maxIngredientsPerScan {
                    break
                }
            } catch {
                print("Error processing frame: \(error)")
                continue
            }
        }
        
        disconnectWebSocket()
        
        return Array(detectedIngredients.values)
            .filter { $0.confidence >= AppConfig.minConfidenceThreshold }
            .sorted { $0.confidence > $1.confidence }
    }
    
    func detectIngredients(from pixelBuffer: CVPixelBuffer) async throws -> [Ingredient] {
        guard apiKey != "INSERT_KEY_HERE" else {
            throw VisionServiceError.apiKeyMissing
        }
        
        // For single frame, use REST API instead of WebSocket
        return try await detectIngredientsViaREST(pixelBuffer)
    }
    
    func analyzeCookingProgress(from stream: AsyncStream<CVPixelBuffer>, for step: String) async throws -> CookingProgress {
        guard apiKey != "INSERT_KEY_HERE" else {
            throw VisionServiceError.apiKeyMissing
        }
        
        // Connect to WebSocket for real-time monitoring
        try await connectWebSocket()
        
        var latestProgress = CookingProgress(isComplete: false, confidence: 0.0, feedback: "Analyzing...")
        
        // Monitor frames for cooking completion
        for await pixelBuffer in stream {
            do {
                let progress = try await analyzeCookingFrame(pixelBuffer, step: step)
                latestProgress = progress
                
                if progress.isComplete && progress.confidence > 0.8 {
                    disconnectWebSocket()
                    return progress
                }
            } catch {
                print("Error analyzing cooking frame: \(error)")
                continue
            }
        }
        
        disconnectWebSocket()
        return latestProgress
    }
    
    // MARK: - Private Helper Methods
    
    private func connectWebSocket() async throws {
        var request = URLRequest(url: webSocketURL)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        
        // Wait for connection
        try await Task.sleep(for: .milliseconds(500))
    }
    
    private func disconnectWebSocket() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
    private func processFrame(_ pixelBuffer: CVPixelBuffer) async throws -> [Ingredient] {
        // Convert pixel buffer to JPEG data
        guard let imageData = pixelBufferToJPEG(pixelBuffer) else {
            throw VisionServiceError.invalidResponse
        }
        
        // Create WebSocket message
        let message = OvershootRequest(
            type: "detect_ingredients",
            image: imageData.base64EncodedString(),
            timestamp: Date().timeIntervalSince1970
        )
        
        // Send frame via WebSocket
        let messageData = try JSONEncoder().encode(message)
        let messageString = String(data: messageData, encoding: .utf8)!
        
        try await webSocketTask?.send(.string(messageString))
        
        // Receive response
        guard let response = try await receiveWebSocketMessage() else {
            return []
        }
        
        return parseIngredients(from: response)
    }
    
    private func analyzeCookingFrame(_ pixelBuffer: CVPixelBuffer, step: String) async throws -> CookingProgress {
        guard let imageData = pixelBufferToJPEG(pixelBuffer) else {
            throw VisionServiceError.invalidResponse
        }
        
        let message = OvershootRequest(
            type: "analyze_cooking",
            image: imageData.base64EncodedString(),
            timestamp: Date().timeIntervalSince1970,
            context: step
        )
        
        let messageData = try JSONEncoder().encode(message)
        let messageString = String(data: messageData, encoding: .utf8)!
        
        try await webSocketTask?.send(.string(messageString))
        
        guard let response = try await receiveWebSocketMessage() else {
            return CookingProgress(isComplete: false, confidence: 0.0, feedback: "No response")
        }
        
        return parseCookingProgress(from: response)
    }
    
    private func receiveWebSocketMessage() async throws -> OvershootResponse? {
        guard let message = try await webSocketTask?.receive() else {
            return nil
        }
        
        switch message {
        case .string(let text):
            guard let data = text.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(OvershootResponse.self, from: data)
        case .data(let data):
            return try? JSONDecoder().decode(OvershootResponse.self, from: data)
        @unknown default:
            return nil
        }
    }
    
    private func detectIngredientsViaREST(_ pixelBuffer: CVPixelBuffer) async throws -> [Ingredient] {
        // Fallback REST API implementation
        // This would be used for single-frame detection
        
        guard let imageData = pixelBufferToJPEG(pixelBuffer) else {
            throw VisionServiceError.invalidResponse
        }
        
        var request = URLRequest(url: URL(string: "https://api.overshoot.ai/v1/detect")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = OvershootRequest(
            type: "detect_ingredients",
            image: imageData.base64EncodedString(),
            timestamp: Date().timeIntervalSince1970
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(OvershootResponse.self, from: data)
        
        return parseIngredients(from: response)
    }
    
    private func parseIngredients(from response: OvershootResponse) -> [Ingredient] {
        guard let detections = response.detections else { return [] }
        
        return detections.map { detection in
            Ingredient(
                name: detection.label,
                estimatedQuantity: detection.quantity ?? "Unknown",
                confidence: detection.confidence
            )
        }
    }
    
    private func parseCookingProgress(from response: OvershootResponse) -> CookingProgress {
        CookingProgress(
            isComplete: response.isComplete ?? false,
            confidence: response.confidence ?? 0.0,
            feedback: response.feedback ?? "Processing..."
        )
    }
    
    private func pixelBufferToJPEG(_ pixelBuffer: CVPixelBuffer) -> Data? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        let uiImage = UIImage(cgImage: cgImage)
        return uiImage.jpegData(compressionQuality: 0.8)
    }
}

// MARK: - Overshoot API Models

private struct OvershootRequest: Codable {
    let type: String
    let image: String
    let timestamp: TimeInterval
    var context: String?
}

private struct OvershootResponse: Codable {
    let detections: [Detection]?
    let isComplete: Bool?
    let confidence: Double?
    let feedback: String?
    
    struct Detection: Codable {
        let label: String
        let confidence: Double
        let quantity: String?
        let boundingBox: BoundingBox?
    }
    
    struct BoundingBox: Codable {
        let x: Double
        let y: Double
        let width: Double
        let height: Double
    }
}
