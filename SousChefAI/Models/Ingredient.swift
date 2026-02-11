//
//  Ingredient.swift
//  SousChefAI
//
//  Core data model for ingredients detected or managed by the user
//

import Foundation

struct Ingredient: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var estimatedQuantity: String
    var confidence: Double
    
    init(id: String = UUID().uuidString, 
         name: String, 
         estimatedQuantity: String, 
         confidence: Double = 1.0) {
        self.id = id
        self.name = name
        self.estimatedQuantity = estimatedQuantity
        self.confidence = confidence
    }
    
    /// Indicates if the detection confidence is low and requires user verification
    var needsVerification: Bool {
        confidence < 0.7
    }
}
