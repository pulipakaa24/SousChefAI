//
//  GeminiRecipeService.swift
//  SousChefAI
//
//  Concrete implementation using Google Gemini API for recipe generation
//  Note: Requires GoogleGenerativeAI SDK to be added via Swift Package Manager
//

import Foundation

/// Google Gemini implementation for recipe generation and cooking guidance
final class GeminiRecipeService: RecipeService, @unchecked Sendable {
    
    private let apiKey: String
    
    // Note: Uncomment when GoogleGenerativeAI package is added
    // private let model: GenerativeModel
    
    nonisolated init(apiKey: String = AppConfig.geminiAPIKey) {
        self.apiKey = apiKey
        
        // Initialize Gemini model when package is available
        // self.model = GenerativeModel(name: "gemini-2.0-flash-exp", apiKey: apiKey)
    }
    
    // MARK: - RecipeService Protocol Implementation
    
    func generateRecipes(inventory: [Ingredient], profile: UserProfile) async throws -> [Recipe] {
        guard apiKey != "INSERT_KEY_HERE" else {
            throw RecipeServiceError.apiKeyMissing
        }
        
        let prompt = buildRecipeGenerationPrompt(inventory: inventory, profile: profile)
        
        // When GoogleGenerativeAI is added, use this:
        // let response = try await model.generateContent(prompt)
        // return try parseRecipesFromResponse(response.text ?? "")
        
        // Temporary fallback using REST API
        return try await generateRecipesViaREST(prompt: prompt)
    }
    
    func scaleRecipe(_ recipe: Recipe, for ingredient: Ingredient, quantity: String) async throws -> Recipe {
        guard apiKey != "INSERT_KEY_HERE" else {
            throw RecipeServiceError.apiKeyMissing
        }
        
        let prompt = buildScalingPrompt(recipe: recipe, ingredient: ingredient, quantity: quantity)
        
        return try await scaleRecipeViaREST(prompt: prompt, originalRecipe: recipe)
    }
    
    func provideCookingGuidance(for step: String, context: String?) async throws -> String {
        guard apiKey != "INSERT_KEY_HERE" else {
            throw RecipeServiceError.apiKeyMissing
        }
        
        let prompt = buildGuidancePrompt(step: step, context: context)
        
        return try await generateGuidanceViaREST(prompt: prompt)
    }
    
    // MARK: - Prompt Building
    
    private func buildRecipeGenerationPrompt(inventory: [Ingredient], profile: UserProfile) -> String {
        let inventoryList = inventory.map { "- \($0.name): \($0.estimatedQuantity)" }.joined(separator: "\n")
        
        let restrictions = profile.dietaryRestrictions.isEmpty
            ? "None"
            : profile.dietaryRestrictions.joined(separator: ", ")
        
        let nutritionGoals = profile.nutritionGoals.isEmpty
            ? "No specific goals"
            : profile.nutritionGoals
        
        return """
        You are a professional chef AI assistant. Generate creative, practical recipes based on available ingredients.
        
        AVAILABLE INGREDIENTS:
        \(inventoryList)
        
        USER PREFERENCES:
        - Dietary Restrictions: \(restrictions)
        - Nutrition Goals: \(nutritionGoals)
        
        INSTRUCTIONS:
        1. Generate 5-7 recipe ideas that can be made with these ingredients
        2. Categorize recipes as:
           - "The Scavenger": Uses ONLY available ingredients (no shopping needed)
           - "The Upgrader": Requires 1-2 additional common ingredients
        3. For each recipe, provide:
           - Title (creative and appetizing)
           - Brief description
           - List of missing ingredients (if any)
           - Step-by-step cooking instructions
           - Match score (0.0-1.0) based on ingredient availability
           - Estimated time
           - Servings
        4. Respect ALL dietary restrictions strictly
        5. Prioritize recipes with higher match scores
        
        RESPOND ONLY WITH VALID JSON in this exact format:
        {
          "recipes": [
            {
              "title": "Recipe Name",
              "description": "Brief description",
              "missingIngredients": [
                {
                  "name": "ingredient name",
                  "estimatedQuantity": "quantity",
                  "confidence": 1.0
                }
              ],
              "steps": ["Step 1", "Step 2", ...],
              "matchScore": 0.95,
              "estimatedTime": "30 minutes",
              "servings": 4
            }
          ]
        }
        """
    }
    
    private func buildScalingPrompt(recipe: Recipe, ingredient: Ingredient, quantity: String) -> String {
        """
        Scale this recipe based on a limiting ingredient quantity.
        
        ORIGINAL RECIPE:
        Title: \(recipe.title)
        Servings: \(recipe.servings ?? 4)
        
        STEPS:
        \(recipe.steps.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n"))
        
        LIMITING INGREDIENT:
        \(ingredient.name): I only have \(quantity)
        
        INSTRUCTIONS:
        1. Calculate the scaled portions for all ingredients
        2. Adjust cooking times if necessary
        3. Update servings count
        4. Maintain the same step structure but update quantities
        
        RESPOND WITH JSON:
        {
          "title": "Recipe Name",
          "description": "Updated description with new servings",
          "missingIngredients": [...],
          "steps": ["Updated steps with scaled quantities"],
          "matchScore": 0.95,
          "estimatedTime": "updated time",
          "servings": updated_count
        }
        """
    }
    
    private func buildGuidancePrompt(step: String, context: String?) -> String {
        var prompt = """
        You are a cooking assistant providing real-time guidance.
        
        CURRENT STEP: \(step)
        """
        
        if let context = context {
            prompt += "\n\nVISUAL CONTEXT: \(context)"
        }
        
        prompt += """
        
        Provide brief, actionable guidance for this cooking step.
        If the context indicates the step is complete, confirm it.
        If there are issues, suggest corrections.
        Keep response under 50 words.
        """
        
        return prompt
    }
    
    // MARK: - REST API Helpers
    
    private func generateRecipesViaREST(prompt: String) async throws -> [Recipe] {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=\(apiKey)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 8192
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw RecipeServiceError.generationFailed("HTTP error")
        }
        
        return try parseGeminiResponse(data)
    }
    
    private func scaleRecipeViaREST(prompt: String, originalRecipe: Recipe) async throws -> Recipe {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=\(apiKey)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let recipes = try parseGeminiResponse(data)
        
        return recipes.first ?? originalRecipe
    }
    
    private func generateGuidanceViaREST(prompt: String) async throws -> String {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=\(apiKey)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw RecipeServiceError.decodingError
        }
        
        return text
    }
    
    private func parseGeminiResponse(_ data: Data) throws -> [Recipe] {
        // Parse Gemini API response structure
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw RecipeServiceError.decodingError
        }
        
        // Extract JSON from markdown code blocks if present
        let cleanedText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleanedText.data(using: .utf8),
              let recipeResponse = try? JSONDecoder().decode(GeminiRecipeResponse.self, from: jsonData) else {
            throw RecipeServiceError.decodingError
        }
        
        return recipeResponse.recipes.map { geminiRecipe in
            Recipe(
                title: geminiRecipe.title,
                description: geminiRecipe.description,
                missingIngredients: geminiRecipe.missingIngredients,
                steps: geminiRecipe.steps,
                matchScore: geminiRecipe.matchScore,
                estimatedTime: geminiRecipe.estimatedTime,
                servings: geminiRecipe.servings
            )
        }
    }
}

// MARK: - Response Models

private struct GeminiRecipeResponse: Codable {
    let recipes: [GeminiRecipe]
}

private struct GeminiRecipe: Codable {
    let title: String
    let description: String
    let missingIngredients: [Ingredient]
    let steps: [String]
    let matchScore: Double
    let estimatedTime: String?
    let servings: Int?
}
