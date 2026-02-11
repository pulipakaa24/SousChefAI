//
//  FirestoreRepository.swift
//  SousChefAI
//
//  Repository pattern for Firebase Firestore data persistence
//  Note: Requires Firebase SDK to be added via Swift Package Manager
//

import Foundation
import Combine

/// Repository for managing user data in Firestore
@MainActor
final class FirestoreRepository: ObservableObject {
    
    // Uncomment when Firebase package is added
    // private let db = Firestore.firestore()
    
    @Published var currentUser: UserProfile?
    @Published var currentInventory: [Ingredient] = []
    @Published var savedRecipes: [Recipe] = []
    
    private var userId: String?
    
    nonisolated init() {
        // Initialize with current user ID from Firebase Auth
        // self.userId = Auth.auth().currentUser?.uid
    }
    
    // MARK: - User Profile
    
    /// Fetches the user profile from Firestore
    func fetchUserProfile(userId: String) async throws {
        self.userId = userId
        
        // When Firebase is added, use this:
        /*
        let document = try await db.collection("users").document(userId).getDocument()
        
        if let data = document.data() {
            currentUser = try Firestore.Decoder().decode(UserProfile.self, from: data)
        } else {
            // Create default profile
            let newProfile = UserProfile(id: userId)
            try await saveUserProfile(newProfile)
            currentUser = newProfile
        }
        */
        
        // Temporary fallback
        currentUser = UserProfile(id: userId)
    }
    
    /// Saves the user profile to Firestore
    func saveUserProfile(_ profile: UserProfile) async throws {
        guard userId != nil else { return }
        
        // When Firebase is added, use this:
        /*
        let data = try Firestore.Encoder().encode(profile)
        try await db.collection("users").document(userId).setData(data)
        */
        
        currentUser = profile
    }
    
    /// Updates dietary restrictions
    func updateDietaryRestrictions(_ restrictions: [String]) async throws {
        guard var profile = currentUser else { return }
        profile.dietaryRestrictions = restrictions
        try await saveUserProfile(profile)
    }
    
    /// Updates nutrition goals
    func updateNutritionGoals(_ goals: String) async throws {
        guard var profile = currentUser else { return }
        profile.nutritionGoals = goals
        try await saveUserProfile(profile)
    }
    
    // MARK: - Inventory Management
    
    /// Fetches current inventory from Firestore
    func fetchInventory() async throws {
        guard userId != nil else { return }
        
        // When Firebase is added, use this:
        /*
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("inventory")
            .getDocuments()
        
        currentInventory = try snapshot.documents.compactMap { document in
            try Firestore.Decoder().decode(Ingredient.self, from: document.data())
        }
        */
        
        // Temporary fallback
        currentInventory = []
    }
    
    /// Saves inventory to Firestore
    func saveInventory(_ ingredients: [Ingredient]) async throws {
        guard userId != nil else { return }
        
        // When Firebase is added, use this:
        /*
        let batch = db.batch()
        let inventoryRef = db.collection("users").document(userId).collection("inventory")
        
        // Delete existing inventory
        let existingDocs = try await inventoryRef.getDocuments()
        for doc in existingDocs.documents {
            batch.deleteDocument(doc.reference)
        }
        
        // Add new inventory
        for ingredient in ingredients {
            let docRef = inventoryRef.document(ingredient.id)
            let data = try Firestore.Encoder().encode(ingredient)
            batch.setData(data, forDocument: docRef)
        }
        
        try await batch.commit()
        */
        
        currentInventory = ingredients
    }
    
    /// Adds a single ingredient to inventory
    func addIngredient(_ ingredient: Ingredient) async throws {
        guard userId != nil else { return }
        
        // When Firebase is added, use this:
        /*
        let data = try Firestore.Encoder().encode(ingredient)
        try await db.collection("users")
            .document(userId)
            .collection("inventory")
            .document(ingredient.id)
            .setData(data)
        */
        
        currentInventory.append(ingredient)
    }
    
    /// Removes an ingredient from inventory
    func removeIngredient(_ ingredientId: String) async throws {
        guard userId != nil else { return }
        
        // When Firebase is added, use this:
        /*
        try await db.collection("users")
            .document(userId)
            .collection("inventory")
            .document(ingredientId)
            .delete()
        */
        
        currentInventory.removeAll { $0.id == ingredientId }
    }
    
    /// Updates an ingredient in inventory
    func updateIngredient(_ ingredient: Ingredient) async throws {
        guard userId != nil else { return }
        
        // When Firebase is added, use this:
        /*
        let data = try Firestore.Encoder().encode(ingredient)
        try await db.collection("users")
            .document(userId)
            .collection("inventory")
            .document(ingredient.id)
            .updateData(data)
        */
        
        if let index = currentInventory.firstIndex(where: { $0.id == ingredient.id }) {
            currentInventory[index] = ingredient
        }
    }
    
    // MARK: - Recipe Management
    
    /// Saves a recipe to user's favorites
    func saveRecipe(_ recipe: Recipe) async throws {
        guard userId != nil else { return }
        
        // When Firebase is added, use this:
        /*
        let data = try Firestore.Encoder().encode(recipe)
        try await db.collection("users")
            .document(userId)
            .collection("savedRecipes")
            .document(recipe.id)
            .setData(data)
        */
        
        if !savedRecipes.contains(where: { $0.id == recipe.id }) {
            savedRecipes.append(recipe)
        }
    }
    
    /// Fetches saved recipes
    func fetchSavedRecipes() async throws {
        guard userId != nil else { return }
        
        // When Firebase is added, use this:
        /*
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("savedRecipes")
            .getDocuments()
        
        savedRecipes = try snapshot.documents.compactMap { document in
            try Firestore.Decoder().decode(Recipe.self, from: document.data())
        }
        */
        
        // Temporary fallback
        savedRecipes = []
    }
    
    /// Deletes a saved recipe
    func deleteRecipe(_ recipeId: String) async throws {
        guard userId != nil else { return }
        
        // When Firebase is added, use this:
        /*
        try await db.collection("users")
            .document(userId)
            .collection("savedRecipes")
            .document(recipeId)
            .delete()
        */
        
        savedRecipes.removeAll { $0.id == recipeId }
    }
    
    // MARK: - Pantry Staples
    
    /// Updates pantry staples (ingredients always available)
    func updatePantryStaples(_ staples: [Ingredient]) async throws {
        guard var profile = currentUser else { return }
        profile.pantryStaples = staples
        try await saveUserProfile(profile)
    }
}
