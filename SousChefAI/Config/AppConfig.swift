//
//  AppConfig.swift
//  SousChefAI
//
//  Centralized configuration for API keys and service endpoints
//

import Foundation

enum AppConfig {
    // MARK: - Overshoot Vision API
    /// Overshoot API key for real-time video inference
    /// [INSERT_OVERSHOOT_API_KEY_HERE]
    static let overshootAPIKey = "INSERT_KEY_HERE"
    static let overshootWebSocketURL = "wss://api.overshoot.ai/v1/stream" // Placeholder URL
    
    // MARK: - Google Gemini API
    /// Google Gemini API key for recipe generation and reasoning
    /// [INSERT_GEMINI_API_KEY_HERE]
    static let geminiAPIKey = "INSERT_KEY_HERE"
    
    // MARK: - Firebase Configuration
    /// Firebase configuration will be loaded from GoogleService-Info.plist
    /// [INSERT_FIREBASE_GOOGLESERVICE-INFO.PLIST_SETUP_HERE]
    /// Instructions:
    /// 1. Download GoogleService-Info.plist from Firebase Console
    /// 2. Add it to the Xcode project root
    /// 3. Ensure it's added to the target
    
    // MARK: - Feature Flags
    static let enableRealTimeDetection = true
    static let enableCookingMode = true
    static let maxIngredientsPerScan = 50
    static let minConfidenceThreshold = 0.5
}
