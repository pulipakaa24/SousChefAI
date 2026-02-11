//
//  UserProfile.swift
//  SousChefAI
//
//  User profile model for dietary preferences and pantry staples
//

import Foundation

struct UserProfile: Identifiable, Codable {
    let id: String
    var dietaryRestrictions: [String]
    var nutritionGoals: String
    var pantryStaples: [Ingredient]
    
    init(id: String = UUID().uuidString,
         dietaryRestrictions: [String] = [],
         nutritionGoals: String = "",
         pantryStaples: [Ingredient] = []) {
        self.id = id
        self.dietaryRestrictions = dietaryRestrictions
        self.nutritionGoals = nutritionGoals
        self.pantryStaples = pantryStaples
    }
    
    /// Common dietary restrictions for quick selection
    static let commonRestrictions = [
        "Vegan",
        "Vegetarian",
        "Gluten-Free",
        "Dairy-Free",
        "Keto",
        "Paleo",
        "Nut Allergy",
        "Shellfish Allergy"
    ]
}
