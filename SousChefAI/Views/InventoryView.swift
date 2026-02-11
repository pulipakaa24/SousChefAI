//
//  InventoryView.swift
//  SousChefAI
//
//  View for reviewing and editing detected ingredients before recipe generation
//

import SwiftUI

struct InventoryView: View {
    @StateObject private var repository = FirestoreRepository()
    @State private var ingredients: [Ingredient]
    @State private var dietaryRestrictions: Set<String> = []
    @State private var nutritionGoals = ""
    @State private var showingRecipeGenerator = false
    @State private var showingPreferences = false
    @State private var editingIngredient: Ingredient?
    
    init(ingredients: [Ingredient]) {
        _ingredients = State(initialValue: ingredients)
    }
    
    var body: some View {
        List {
            // Preferences Section
            Section {
                Button {
                    showingPreferences = true
                } label: {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Dietary Preferences")
                                .font(.headline)
                            
                            if dietaryRestrictions.isEmpty {
                                Text("Not set")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(dietaryRestrictions.sorted().joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            // Ingredients Section
            Section {
                ForEach(ingredients) { ingredient in
                    IngredientRow(ingredient: ingredient) {
                        editingIngredient = ingredient
                    } onDelete: {
                        deleteIngredient(ingredient)
                    }
                }
            } header: {
                HStack {
                    Text("Detected Ingredients")
                    Spacer()
                    Text("\(ingredients.count) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("Tap an ingredient to edit quantity or remove it. Items with yellow indicators have low confidence and should be verified.")
                    .font(.caption)
            }
        }
        .navigationTitle("Your Inventory")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingRecipeGenerator = true
                } label: {
                    Label("Generate Recipes", systemImage: "sparkles")
                        .fontWeight(.semibold)
                }
                .disabled(ingredients.isEmpty)
            }
        }
        .sheet(isPresented: $showingPreferences) {
            PreferencesSheet(
                dietaryRestrictions: $dietaryRestrictions,
                nutritionGoals: $nutritionGoals
            )
        }
        .sheet(item: $editingIngredient) { ingredient in
            EditIngredientSheet(ingredient: ingredient) { updated in
                updateIngredient(updated)
            }
        }
        .navigationDestination(isPresented: $showingRecipeGenerator) {
            RecipeGeneratorView(
                inventory: ingredients,
                userProfile: createUserProfile()
            )
        }
        .task {
            await loadUserPreferences()
        }
    }
    
    // MARK: - Actions
    
    private func deleteIngredient(_ ingredient: Ingredient) {
        withAnimation {
            ingredients.removeAll { $0.id == ingredient.id }
        }
    }
    
    private func updateIngredient(_ updated: Ingredient) {
        if let index = ingredients.firstIndex(where: { $0.id == updated.id }) {
            ingredients[index] = updated
        }
    }
    
    private func createUserProfile() -> UserProfile {
        UserProfile(
            dietaryRestrictions: Array(dietaryRestrictions),
            nutritionGoals: nutritionGoals,
            pantryStaples: []
        )
    }
    
    private func loadUserPreferences() async {
        if let profile = repository.currentUser {
            dietaryRestrictions = Set(profile.dietaryRestrictions)
            nutritionGoals = profile.nutritionGoals
        }
    }
}

// MARK: - Ingredient Row

struct IngredientRow: View {
    let ingredient: Ingredient
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(ingredient.needsVerification ? Color.orange : Color.green)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Text(ingredient.estimatedQuantity)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if ingredient.needsVerification {
                        Text("• Low confidence")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            Spacer()
            
            // Confidence badge
            Text("\(Int(ingredient.confidence * 100))%")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ingredient.needsVerification ? Color.orange : Color.green)
                .clipShape(Capsule())
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Preferences Sheet

struct PreferencesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var dietaryRestrictions: Set<String>
    @Binding var nutritionGoals: String
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Dietary Restrictions") {
                    ForEach(UserProfile.commonRestrictions, id: \.self) { restriction in
                        Toggle(restriction, isOn: Binding(
                            get: { dietaryRestrictions.contains(restriction) },
                            set: { isOn in
                                if isOn {
                                    dietaryRestrictions.insert(restriction)
                                } else {
                                    dietaryRestrictions.remove(restriction)
                                }
                            }
                        ))
                    }
                }
                
                Section("Nutrition Goals") {
                    TextField("E.g., High protein, Low carb", text: $nutritionGoals, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Edit Ingredient Sheet

struct EditIngredientSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var quantity: String
    
    let ingredient: Ingredient
    let onSave: (Ingredient) -> Void
    
    init(ingredient: Ingredient, onSave: @escaping (Ingredient) -> Void) {
        self.ingredient = ingredient
        self.onSave = onSave
        _name = State(initialValue: ingredient.name)
        _quantity = State(initialValue: ingredient.estimatedQuantity)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Ingredient Details") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Quantity", text: $quantity)
                }
                
                Section {
                    HStack {
                        Text("Detection Confidence")
                        Spacer()
                        Text("\(Int(ingredient.confidence * 100))%")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = ingredient
                        updated.name = name
                        updated.estimatedQuantity = quantity
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(name.isEmpty || quantity.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        InventoryView(ingredients: [
            Ingredient(name: "Tomatoes", estimatedQuantity: "3 medium", confidence: 0.95),
            Ingredient(name: "Cheese", estimatedQuantity: "200g", confidence: 0.65),
            Ingredient(name: "Eggs", estimatedQuantity: "6 large", confidence: 0.88)
        ])
    }
}
