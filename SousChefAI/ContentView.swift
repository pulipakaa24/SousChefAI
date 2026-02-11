//
//  ContentView.swift
//  SousChefAI
//
//  Created by Aditya Pulipaka on 2/11/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var repository: FirestoreRepository
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Scanner Tab
            ScannerView()
                .tabItem {
                    Label("Scan", systemImage: "camera.fill")
                }
                .tag(0)
            
            // Inventory Tab
            NavigationStack {
                inventoryPlaceholder
            }
            .tabItem {
                Label("Inventory", systemImage: "square.grid.2x2")
            }
            .tag(1)
            
            // Saved Recipes Tab
            NavigationStack {
                savedRecipesPlaceholder
            }
            .tabItem {
                Label("Recipes", systemImage: "book.fill")
            }
            .tag(2)
            
            // Profile Tab
            NavigationStack {
                profileView
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(3)
        }
    }
    
    // MARK: - Placeholder Views
    
    private var inventoryPlaceholder: some View {
        List {
            if repository.currentInventory.isEmpty {
                ContentUnavailableView(
                    "No Ingredients",
                    systemImage: "refrigerator",
                    description: Text("Scan your fridge to get started")
                )
            } else {
                ForEach(repository.currentInventory) { ingredient in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(ingredient.name)
                                .font(.headline)
                            Text(ingredient.estimatedQuantity)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(Int(ingredient.confidence * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("My Inventory")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    selectedTab = 0
                } label: {
                    Label("Scan", systemImage: "camera")
                }
            }
        }
    }
    
    private var savedRecipesPlaceholder: some View {
        List {
            if repository.savedRecipes.isEmpty {
                ContentUnavailableView(
                    "No Saved Recipes",
                    systemImage: "book",
                    description: Text("Save recipes from the recipe generator")
                )
            } else {
                ForEach(repository.savedRecipes) { recipe in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recipe.title)
                            .font(.headline)
                        Text(recipe.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Saved Recipes")
    }
    
    private var profileView: some View {
        Form {
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Preferences") {
                NavigationLink {
                    dietaryPreferencesView
                } label: {
                    HStack {
                        Label("Dietary Restrictions", systemImage: "leaf")
                        Spacer()
                        if let profile = repository.currentUser,
                           !profile.dietaryRestrictions.isEmpty {
                            Text("\(profile.dietaryRestrictions.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                NavigationLink {
                    nutritionGoalsView
                } label: {
                    Label("Nutrition Goals", systemImage: "heart")
                }
            }
            
            Section("API Configuration") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Overshoot API")
                        .font(.headline)
                    Text(AppConfig.overshootAPIKey == "INSERT_KEY_HERE" ? "Not configured" : "Configured")
                        .font(.caption)
                        .foregroundStyle(AppConfig.overshootAPIKey == "INSERT_KEY_HERE" ? .red : .green)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gemini API")
                        .font(.headline)
                    Text(AppConfig.geminiAPIKey == "INSERT_KEY_HERE" ? "Not configured" : "Configured")
                        .font(.caption)
                        .foregroundStyle(AppConfig.geminiAPIKey == "INSERT_KEY_HERE" ? .red : .green)
                }
            }
            
            Section {
                Link(destination: URL(string: "https://github.com/yourusername/souschef")!) {
                    Label("View on GitHub", systemImage: "link")
                }
            }
        }
        .navigationTitle("Profile")
    }
    
    private var dietaryPreferencesView: some View {
        Form {
            Section {
                ForEach(UserProfile.commonRestrictions, id: \.self) { restriction in
                    HStack {
                        Text(restriction)
                        Spacer()
                        if repository.currentUser?.dietaryRestrictions.contains(restriction) ?? false {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleRestriction(restriction)
                    }
                }
            }
        }
        .navigationTitle("Dietary Restrictions")
    }
    
    private var nutritionGoalsView: some View {
        Form {
            Section {
                TextField("Enter your nutrition goals", 
                         text: Binding(
                            get: { repository.currentUser?.nutritionGoals ?? "" },
                            set: { newValue in
                                Task {
                                    try? await repository.updateNutritionGoals(newValue)
                                }
                            }
                         ),
                         axis: .vertical)
                .lineLimit(5...10)
            } header: {
                Text("Goals")
            } footer: {
                Text("e.g., High protein, Low carb, Balanced diet")
            }
        }
        .navigationTitle("Nutrition Goals")
    }
    
    // MARK: - Actions
    
    private func toggleRestriction(_ restriction: String) {
        Task {
            guard var profile = repository.currentUser else { return }
            
            if profile.dietaryRestrictions.contains(restriction) {
                profile.dietaryRestrictions.removeAll { $0 == restriction }
            } else {
                profile.dietaryRestrictions.append(restriction)
            }
            
            try? await repository.updateDietaryRestrictions(profile.dietaryRestrictions)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FirestoreRepository())
}
