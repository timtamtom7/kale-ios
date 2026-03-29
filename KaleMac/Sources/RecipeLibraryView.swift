import SwiftUI

// MARK: - Shared Recipe Model

struct SharedRecipe: Identifiable, Codable {
    let id: UUID
    let recipe: Meal
    let sharedBy: String
    let sharedByEmoji: String
    let sharedAt: Date
    var likes: Int
    var isLiked: Bool
    var collection: String

    init(id: UUID = UUID(), recipe: Meal, sharedBy: String, sharedByEmoji: String = "👤", sharedAt: Date = Date(), likes: Int = 0, isLiked: Bool = false, collection: String = "Community") {
        self.id = id
        self.recipe = recipe
        self.sharedBy = sharedBy
        self.sharedByEmoji = sharedByEmoji
        self.sharedAt = sharedAt
        self.likes = likes
        self.isLiked = isLiked
        self.collection = collection
    }
}

struct RecipeCollection: Identifiable, Codable {
    let id: UUID
    var name: String
    var emoji: String
    var recipes: [SharedRecipe]
    var isPublic: Bool

    init(id: UUID = UUID(), name: String, emoji: String = "📁", recipes: [SharedRecipe] = [], isPublic: Bool = false) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.recipes = recipes
        self.isPublic = isPublic
    }
}

// MARK: - Recipe Library View

struct RecipeLibraryView: View {
    @Binding var recipes: [Meal]
    @State private var searchText = ""
    @State private var selectedCuisine: String? = nil
    @State private var selectedMealType: String? = nil
    @State private var selectedDiet: String? = nil
    @State private var showingAddRecipe = false
    @State private var editingRecipe: Meal? = nil
    @State private var showingShareSheet = false
    @State private var shareRecipe: Meal? = nil
    @State private var showingImportSheet = false
    @State private var sharedRecipes: [SharedRecipe] = []
    @State private var collections: [RecipeCollection] = []
    @State private var selectedTab: RecipeTab = .myRecipes

    enum RecipeTab: String, CaseIterable {
        case myRecipes = "My Recipes"
        case community = "Community"
        case collections = "Collections"
    }

    var filteredRecipes: [Meal] {
        recipes.filter { recipe in
            let matchesSearch = searchText.isEmpty ||
                recipe.name.localizedCaseInsensitiveContains(searchText)
            let matchesCuisine = selectedCuisine == nil ||
                recipe.tags.contains { $0.localizedCaseInsensitiveContains(selectedCuisine!) }
            let matchesMealType = selectedMealType == nil ||
                recipe.tags.contains { $0.localizedCaseInsensitiveContains(selectedMealType!) }
            let matchesDiet = selectedDiet == nil ||
                recipe.tags.contains { $0.localizedCaseInsensitiveContains(selectedDiet!) }

            return matchesSearch && matchesCuisine && matchesMealType && matchesDiet
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            // Tab bar
            Picker("View", selection: $selectedTab) {
                ForEach(RecipeTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Content based on tab
            switch selectedTab {
            case .myRecipes:
                myRecipesView
            case .community:
                communityView
            case .collections:
                collectionsView
            }
        }
        .sheet(isPresented: $showingAddRecipe) {
            RecipeEditorView(recipes: $recipes, recipe: nil)
        }
        .sheet(item: $editingRecipe) { recipe in
            RecipeEditorView(recipes: $recipes, recipe: recipe)
        }
        .sheet(item: $shareRecipe) { recipe in
            ShareRecipeSheet(recipe: recipe, collections: $collections, onShare: {
                shareRecipe = nil
            })
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportRecipeSheet(sharedRecipes: $sharedRecipes)
        }
        .onAppear {
            loadSampleCommunityData()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("Recipe Library")
                .font(.largeTitle.bold())

            Spacer()

            if selectedTab == .myRecipes {
                Button {
                    showingImportSheet = true
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)
            }

            Button {
                showingAddRecipe = true
            } label: {
                Label("New Recipe", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Theme.cream)
    }

    // MARK: - My Recipes

    private var myRecipesView: some View {
        VStack(spacing: 0) {
            // Search and filters
            searchAndFilters

            // Recipe grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(filteredRecipes) { recipe in
                        RecipeCardView(recipe: recipe, onShare: {
                            shareRecipe = recipe
                        })
                        .onTapGesture {
                            editingRecipe = recipe
                        }
                    }
                }
                .padding()
            }
            .background(Theme.surface)
        }
    }

    private var searchAndFilters: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search recipes...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "Cuisine", selection: $selectedCuisine, options: ["Italian", "Mexican", "Asian", "American", "Mediterranean"])
                    FilterChip(title: "Meal", selection: $selectedMealType, options: ["Breakfast", "Lunch", "Dinner", "Snacks"])
                    FilterChip(title: "Diet", selection: $selectedDiet, options: ["Vegetarian", "Vegan", "High-Protein", "Low-Carb", "Gluten-Free"])

                    if selectedCuisine != nil || selectedMealType != nil || selectedDiet != nil {
                        Button("Clear All") {
                            selectedCuisine = nil
                            selectedMealType = nil
                            selectedDiet = nil
                        }
                        .font(.caption)
                        .foregroundStyle(Theme.tomato)
                    }
                }
            }
        }
        .padding()
        .background(Theme.surface)
    }

    // MARK: - Community

    private var communityView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Shared by other Kale users")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    showingImportSheet = true
                } label: {
                    Label("Import Recipe", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Theme.surface)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(sharedRecipes) { shared in
                        CommunityRecipeCard(shared: shared, onImport: {
                            importRecipe(shared)
                        }, onLike: {
                            toggleLike(shared)
                        })
                    }
                }
                .padding()
            }
            .background(Theme.surface)
        }
    }

    // MARK: - Collections

    private var collectionsView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Your recipe collections")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    createNewCollection()
                } label: {
                    Label("New Collection", systemImage: "folder.badge.plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Theme.surface)

            if collections.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "folder")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("No collections yet")
                        .font(.headline)
                    Text("Create a collection to organize shared recipes")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(collections) { collection in
                            CollectionCard(collection: collection)
                        }
                    }
                    .padding()
                }
                .background(Theme.surface)
            }
        }
    }

    // MARK: - Actions

    private func importRecipe(_ shared: SharedRecipe) {
        recipes.append(shared.recipe)
    }

    private func toggleLike(_ shared: SharedRecipe) {
        if let index = sharedRecipes.firstIndex(where: { $0.id == shared.id }) {
            sharedRecipes[index].isLiked.toggle()
            sharedRecipes[index].likes += sharedRecipes[index].isLiked ? 1 : -1
        }
    }

    private func createNewCollection() {
        let newCollection = RecipeCollection(name: "New Collection", emoji: "📁")
        collections.append(newCollection)
    }

    private func loadSampleCommunityData() {
        guard sharedRecipes.isEmpty else { return }
        sharedRecipes = [
            SharedRecipe(recipe: Meal.sampleRecipes[0], sharedBy: "ChefMaria", sharedByEmoji: "👩‍🍳", likes: 42, collection: "Italian"),
            SharedRecipe(recipe: Meal.sampleRecipes[1], sharedBy: "HealthyEats", sharedByEmoji: "🥗", likes: 28, collection: "Healthy"),
            SharedRecipe(recipe: Meal.sampleRecipes[2], sharedBy: "SalmonLover", sharedByEmoji: "🐟", likes: 35, collection: "Seafood")
        ]
    }
}

// MARK: - Community Recipe Card

struct CommunityRecipeCard: View {
    let shared: SharedRecipe
    let onImport: () -> Void
    let onLike: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with sharer info
            HStack {
                Text(shared.sharedByEmoji)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 0) {
                    Text("by \(shared.sharedBy)")
                        .font(.caption.weight(.medium))
                    Text(shared.recipe.tags.first ?? "")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(shared.collection)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.kaleGreen.opacity(0.2))
                    .foregroundStyle(Theme.kaleGreen)
                    .clipShape(Capsule())
            }

            // Recipe info
            VStack(alignment: .leading, spacing: 4) {
                Text(shared.recipe.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Label("\(shared.recipe.cookTime)m", systemImage: "clock")
                    Label("\(shared.recipe.nutrition.calories) cal", systemImage: "flame")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Divider()

            // Actions
            HStack {
                Button {
                    onLike()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: shared.isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(shared.isLiked ? .red : .secondary)
                        Text("\(shared.likes)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Import") {
                    onImport()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var shareText: String {
        "\(shared.recipe.name) - \(shared.recipe.tags.joined(separator: ", ")). Shared from KaleMac 🍏"
    }
}

// MARK: - Collection Card

struct CollectionCard: View {
    let collection: RecipeCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(collection.emoji)
                    .font(.title2)
                Text(collection.name)
                    .font(.headline)
                Spacer()
                if collection.isPublic {
                    Image(systemName: "globe")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("\(collection.recipes.count) recipes")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !collection.recipes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(collection.recipes.prefix(3)) { shared in
                            Text(shared.recipe.name)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.avocado.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Share Recipe Sheet

struct ShareRecipeSheet: View {
    let recipe: Meal
    @Binding var collections: [RecipeCollection]
    let onShare: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCollection: String = "Community"
    @State private var makePublic = false

    private let collectionOptions = ["Community", "Weeknight Dinners", "Healthy Lunches", "Family Favorites"]

    var body: some View {
        VStack(spacing: 20) {
            Text("Share Recipe")
                .font(.title2.bold())

            Text("Share \"\(recipe.name)\" with others")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Collection")
                    .font(.subheadline.weight(.medium))

                Picker("Collection", selection: $selectedCollection) {
                    ForEach(collectionOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            Toggle("Share to public community", isOn: $makePublic)
                .font(.subheadline)

            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Share") {
                    addToCollection()
                    onShare()
                }
                .buttonStyle(.borderedProminent)
            }

            // Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Share preview:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(sharePreview)
                    .font(.caption)
                    .padding()
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(24)
        .frame(width: 400)
    }

    private var sharePreview: String {
        "\(recipe.name)\n\(recipe.tags.joined(separator: ", "))\n\(recipe.nutrition.calories) cal | \(recipe.cookTime) min\n\nShared from KaleMac 🍏"
    }

    private func addToCollection() {
        // In a real app, this would add to the selected collection
    }
}

// MARK: - Import Recipe Sheet

struct ImportRecipeSheet: View {
    @Binding var sharedRecipes: [SharedRecipe]
    @Environment(\.dismiss) private var dismiss

    @State private var importCode = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Import Recipe")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 8) {
                Text("Enter recipe share code")
                    .font(.subheadline.weight(.medium))

                TextField("KALE-XXXX-XXXX", text: $importCode)
                    .textFieldStyle(.roundedBorder)
            }

            Text("Or paste a shared recipe link below")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: .constant(""))
                .frame(height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )

            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Import") {
                    // In a real app, this would parse the code/link and import
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(importCode.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}

// MARK: - Recipe Card View (Updated)

struct RecipeCardView: View {
    let recipe: Meal
    var onShare: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Food icon placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.primaryGradient)
                    .frame(height: 100)

                Image(systemName: "fork.knife")
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.8))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Label("\(recipe.cookTime)m", systemImage: "clock")
                    Label("\(recipe.servings)", systemImage: "person.2")
                    Label("\(recipe.nutrition.calories) cal", systemImage: "flame")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                // Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(recipe.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 9))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.avocado.opacity(0.2))
                                .foregroundStyle(Theme.kaleGreen)
                                .clipShape(Capsule())
                        }
                    }
                }

                // Share button
                if let onShare = onShare {
                    Button {
                        onShare()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct FilterChip: View {
    let title: String
    @Binding var selection: String?
    let options: [String]

    @State private var showingPopover = false

    var body: some View {
        Button {
            showingPopover.toggle()
        } label: {
            HStack(spacing: 4) {
                Text(selection ?? title)
                    .font(.caption)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selection != nil ? Theme.kaleGreen : Color(nsColor: .controlBackgroundColor))
            .foregroundStyle(selection != nil ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingPopover) {
            VStack(alignment: .leading, spacing: 4) {
                Button("All \(title)s") {
                    selection = nil
                    showingPopover = false
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()

                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection = option
                        showingPopover = false
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
            .padding(4)
            .frame(width: 150)
        }
    }
}

struct RecipeEditorView: View {
    @Binding var recipes: [Meal]
    let recipe: Meal?
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var cookTime = 30
    @State private var servings = 2
    @State private var tags = ""
    @State private var calories = 0
    @State private var protein = 0
    @State private var carbs = 0
    @State private var fat = 0
    @State private var instructions = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Recipe Name", text: $name)
                    Stepper("Cook Time: \(cookTime) min", value: $cookTime, in: 5...180, step: 5)
                    Stepper("Servings: \(servings)", value: $servings, in: 1...12)
                    TextField("Tags (comma separated)", text: $tags)
                }

                Section("Nutrition (per serving)") {
                    Stepper("Calories: \(calories)", value: $calories, in: 0...2000, step: 50)
                    Stepper("Protein: \(protein)g", value: $protein, in: 0...100, step: 5)
                    Stepper("Carbs: \(carbs)g", value: $carbs, in: 0...200, step: 10)
                    Stepper("Fat: \(fat)g", value: $fat, in: 0...100, step: 5)
                }

                Section("Instructions") {
                    TextEditor(text: $instructions)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(recipe == nil ? "New Recipe" : "Edit Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecipe()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let recipe = recipe {
                    name = recipe.name
                    cookTime = recipe.cookTime
                    servings = recipe.servings
                    tags = recipe.tags.joined(separator: ", ")
                    calories = recipe.nutrition.calories
                    protein = recipe.nutrition.protein
                    carbs = recipe.nutrition.carbs
                    fat = recipe.nutrition.fat
                    instructions = recipe.instructions.joined(separator: "\n")
                }
            }
        }
    }

    private func saveRecipe() {
        let nutrition = NutritionInfo(calories: calories, protein: protein, carbs: carbs, fat: fat)
        let newRecipe = Meal(
            id: recipe?.id ?? UUID(),
            name: name,
            cookTime: cookTime,
            servings: servings,
            tags: tags.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) },
            ingredients: recipe?.ingredients ?? [],
            nutrition: nutrition,
            instructions: instructions.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }
        )

        if let index = recipes.firstIndex(where: { $0.id == recipe?.id }) {
            recipes[index] = newRecipe
        } else {
            recipes.append(newRecipe)
        }
    }
}
