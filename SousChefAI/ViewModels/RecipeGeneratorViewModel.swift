//
//  RecipeGeneratorViewModel.swift
//  SousChefAI
//
//  ViewModel for recipe generation and filtering
//

import Foundation
import Combine

@MainActor
final class RecipeGeneratorViewModel: ObservableObject {
    
    @Published var recipes: [Recipe] = []
    @Published var filteredRecipes: [Recipe] = []
    @Published var isGenerating = false
    @Published var error: Error?
    @Published var selectedFilter: RecipeFilter = .all
    
    private let recipeService: RecipeService
    private let repository: FirestoreRepository
    
    nonisolated init(recipeService: RecipeService = GeminiRecipeService(),
                     repository: FirestoreRepository = FirestoreRepository()) {
        self.recipeService = recipeService
        self.repository = repository
    }
    
    // MARK: - Recipe Generation
    
    func generateRecipes(inventory: [Ingredient], profile: UserProfile) async {
        isGenerating = true
        error = nil
        
        do {
            let generatedRecipes = try await recipeService.generateRecipes(
                inventory: inventory,
                profile: profile
            )
            
            recipes = generatedRecipes.sorted { $0.matchScore > $1.matchScore }
            applyFilter()
        } catch {
            self.error = error
        }
        
        isGenerating = false
    }
    
    // MARK: - Filtering
    
    func applyFilter() {
        switch selectedFilter {
        case .all:
            filteredRecipes = recipes
            
        case .scavenger:
            filteredRecipes = recipes.filter { $0.category == .scavenger }
            
        case .upgrader:
            filteredRecipes = recipes.filter { $0.category == .upgrader }
            
        case .highMatch:
            filteredRecipes = recipes.filter { $0.matchScore >= 0.8 }
        }
    }
    
    func setFilter(_ filter: RecipeFilter) {
        selectedFilter = filter
        applyFilter()
    }
    
    // MARK: - Recipe Scaling
    
    func scaleRecipe(_ recipe: Recipe, for ingredient: Ingredient, quantity: String) async {
        do {
            let scaledRecipe = try await recipeService.scaleRecipe(
                recipe,
                for: ingredient,
                quantity: quantity
            )
            
            // Update the recipe in the list
            if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
                recipes[index] = scaledRecipe
                applyFilter()
            }
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Favorites
    
    func saveRecipe(_ recipe: Recipe) async {
        do {
            try await repository.saveRecipe(recipe)
        } catch {
            self.error = error
        }
    }
}

// MARK: - Recipe Filter

enum RecipeFilter: String, CaseIterable, Identifiable {
    case all = "All Recipes"
    case scavenger = "The Scavenger"
    case upgrader = "The Upgrader"
    case highMatch = "High Match"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .scavenger: return "checkmark.circle.fill"
        case .upgrader: return "cart.badge.plus"
        case .highMatch: return "star.fill"
        }
    }
    
    var description: String {
        switch self {
        case .all:
            return "Show all recipes"
        case .scavenger:
            return "Uses only your ingredients"
        case .upgrader:
            return "Needs 1-2 additional items"
        case .highMatch:
            return "80%+ ingredient match"
        }
    }
}
