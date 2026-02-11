//
//  RecipeGeneratorView.swift
//  SousChefAI
//
//  View for generating and displaying recipe suggestions
//

import SwiftUI

struct RecipeGeneratorView: View {
    @StateObject private var viewModel = RecipeGeneratorViewModel()
    @State private var selectedRecipe: Recipe?
    @State private var showingScaleSheet = false
    
    let inventory: [Ingredient]
    let userProfile: UserProfile
    
    var body: some View {
        Group {
            if viewModel.isGenerating {
                loadingView
            } else if viewModel.filteredRecipes.isEmpty && !viewModel.recipes.isEmpty {
                emptyFilterView
            } else if viewModel.filteredRecipes.isEmpty {
                emptyStateView
            } else {
                recipeListView
            }
        }
        .navigationTitle("Recipe Ideas")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(RecipeFilter.allCases) { filter in
                        Button {
                            viewModel.setFilter(filter)
                        } label: {
                            Label(filter.rawValue, systemImage: filter.icon)
                        }
                    }
                } label: {
                    Label("Filter", systemImage: viewModel.selectedFilter.icon)
                }
            }
        }
        .task {
            await viewModel.generateRecipes(inventory: inventory, profile: userProfile)
        }
        .sheet(item: $selectedRecipe) { recipe in
            RecipeDetailView(recipe: recipe) {
                Task {
                    await viewModel.saveRecipe(recipe)
                }
            }
        }
    }
    
    // MARK: - Views
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Generating recipes...")
                .font(.headline)
            
            Text("Analyzing your ingredients and preferences")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var emptyFilterView: some View {
        ContentUnavailableView(
            "No recipes match this filter",
            systemImage: "line.3.horizontal.decrease.circle",
            description: Text("Try selecting a different filter to see more recipes")
        )
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No recipes generated",
            systemImage: "fork.knife.circle",
            description: Text("We couldn't generate recipes with your current ingredients. Try adding more items.")
        )
    }
    
    private var recipeListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Filter description
                filterDescriptionBanner
                
                // Recipe cards
                ForEach(viewModel.filteredRecipes) { recipe in
                    RecipeCard(recipe: recipe)
                        .onTapGesture {
                            selectedRecipe = recipe
                        }
                }
            }
            .padding()
        }
    }
    
    private var filterDescriptionBanner: some View {
        HStack {
            Image(systemName: viewModel.selectedFilter.icon)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.selectedFilter.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(viewModel.selectedFilter.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(viewModel.filteredRecipes.count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.blue)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Recipe Card

struct RecipeCard: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if let time = recipe.estimatedTime {
                        Label(time, systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Match score badge
                VStack(spacing: 4) {
                    Text("\(Int(recipe.matchScore * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(matchScoreColor)
                    
                    Text("Match")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Description
            Text(recipe.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            
            Divider()
            
            // Footer
            HStack {
                // Category badge
                Label(recipe.category.rawValue, systemImage: categoryIcon)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(categoryColor)
                    .clipShape(Capsule())
                
                Spacer()
                
                // Missing ingredients indicator
                if !recipe.missingIngredients.isEmpty {
                    Label("\(recipe.missingIngredients.count) missing", systemImage: "cart")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                
                if let servings = recipe.servings {
                    Label("\(servings) servings", systemImage: "person.2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var matchScoreColor: Color {
        if recipe.matchScore >= 0.8 {
            return .green
        } else if recipe.matchScore >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var categoryColor: Color {
        switch recipe.category {
        case .scavenger:
            return .green
        case .upgrader:
            return .blue
        case .shopping:
            return .orange
        }
    }
    
    private var categoryIcon: String {
        switch recipe.category {
        case .scavenger:
            return "checkmark.circle.fill"
        case .upgrader:
            return "cart.badge.plus"
        case .shopping:
            return "cart.fill"
        }
    }
}

// MARK: - Recipe Detail View

struct RecipeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var showingCookingMode = false
    
    let recipe: Recipe
    let onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recipe.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(recipe.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            if let time = recipe.estimatedTime {
                                Label(time, systemImage: "clock")
                            }
                            
                            if let servings = recipe.servings {
                                Label("\(servings) servings", systemImage: "person.2")
                            }
                            
                            Spacer()
                            
                            Text("\(Int(recipe.matchScore * 100))% match")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Missing ingredients
                    if !recipe.missingIngredients.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Missing Ingredients")
                                .font(.headline)
                            
                            ForEach(recipe.missingIngredients) { ingredient in
                                HStack {
                                    Image(systemName: "cart")
                                        .foregroundStyle(.orange)
                                    Text(ingredient.name)
                                    Spacer()
                                    Text(ingredient.estimatedQuantity)
                                        .foregroundStyle(.secondary)
                                }
                                .font(.subheadline)
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Cooking steps
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instructions")
                            .font(.headline)
                        
                        ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                
                                Text(step)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Start cooking button
                    Button {
                        showingCookingMode = true
                    } label: {
                        Label("Start Cooking", systemImage: "play.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        onSave()
                    } label: {
                        Label("Save", systemImage: "heart")
                    }
                }
            }
            .sheet(isPresented: $showingCookingMode) {
                CookingModeView(recipe: recipe)
            }
        }
    }
}

#Preview {
    NavigationStack {
        RecipeGeneratorView(
            inventory: [
                Ingredient(name: "Tomatoes", estimatedQuantity: "3 medium", confidence: 0.95),
                Ingredient(name: "Eggs", estimatedQuantity: "6 large", confidence: 0.88)
            ],
            userProfile: UserProfile()
        )
    }
}
