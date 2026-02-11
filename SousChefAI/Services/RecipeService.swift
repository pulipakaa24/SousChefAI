//
//  RecipeService.swift
//  SousChefAI
//
//  Protocol for recipe generation and AI reasoning services
//

import Foundation

/// Protocol for AI-powered recipe generation
protocol RecipeService: Sendable {
    /// Generates recipes based on available ingredients and user preferences
    /// - Parameters:
    ///   - inventory: Available ingredients
    ///   - profile: User dietary preferences and restrictions
    /// - Returns: Array of recipe suggestions with match scores
    func generateRecipes(inventory: [Ingredient], profile: UserProfile) async throws -> [Recipe]
    
    /// Scales a recipe based on a limiting ingredient quantity
    /// - Parameters:
    ///   - recipe: The recipe to scale
    ///   - ingredient: The limiting ingredient
    ///   - quantity: Available quantity of the limiting ingredient
    /// - Returns: Scaled recipe with adjusted portions
    func scaleRecipe(_ recipe: Recipe, for ingredient: Ingredient, quantity: String) async throws -> Recipe
    
    /// Provides real-time cooking guidance
    /// - Parameters:
    ///   - step: Current cooking step
    ///   - context: Additional context (e.g., visual feedback)
    /// - Returns: Guidance text
    func provideCookingGuidance(for step: String, context: String?) async throws -> String
}

enum RecipeServiceError: Error, LocalizedError {
    case apiKeyMissing
    case invalidRequest
    case generationFailed(String)
    case networkError(Error)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "Recipe service API key not configured"
        case .invalidRequest:
            return "Invalid recipe generation request"
        case .generationFailed(let reason):
            return "Recipe generation failed: \(reason)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to parse recipe response"
        }
    }
}
