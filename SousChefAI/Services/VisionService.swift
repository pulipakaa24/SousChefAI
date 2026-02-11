//
//  VisionService.swift
//  SousChefAI
//
//  Protocol-based vision service for ingredient detection
//  Allows swapping between different AI providers
//

import Foundation
@preconcurrency import CoreVideo

/// Protocol for vision-based ingredient detection services
protocol VisionService: Sendable {
    /// Detects ingredients from a stream of video frames
    /// - Parameter stream: Async stream of pixel buffers from camera
    /// - Returns: Array of detected ingredients with confidence scores
    func detectIngredients(from stream: AsyncStream<CVPixelBuffer>) async throws -> [Ingredient]
    
    /// Detects ingredients from a single image
    /// - Parameter pixelBuffer: Single frame to analyze
    /// - Returns: Array of detected ingredients with confidence scores
    func detectIngredients(from pixelBuffer: CVPixelBuffer) async throws -> [Ingredient]
    
    /// Analyzes cooking progress for a given step
    /// - Parameters:
    ///   - stream: Video stream of current cooking
    ///   - step: The cooking step to monitor
    /// - Returns: Progress update and completion detection
    func analyzeCookingProgress(from stream: AsyncStream<CVPixelBuffer>, for step: String) async throws -> CookingProgress
}

/// Represents cooking progress analysis
struct CookingProgress: Sendable {
    let isComplete: Bool
    let confidence: Double
    let feedback: String
}

enum VisionServiceError: Error, LocalizedError {
    case connectionFailed
    case invalidResponse
    case apiKeyMissing
    case networkError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Failed to connect to vision service"
        case .invalidResponse:
            return "Received invalid response from vision service"
        case .apiKeyMissing:
            return "Vision service API key not configured"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
