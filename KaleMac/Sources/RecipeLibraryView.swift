import SwiftUI

struct RecipeLibraryView: View {
    @Binding var recipes: [Meal]
    @State private var searchText = ""
    @State private var selectedCuisine: String? = nil
    @State private var selectedMealType: String? = nil
    @State private var selectedDiet: String? = nil
    @State private var showingAddRecipe = false
    @State private var editingRecipe: Meal? = nil

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
            HStack {
                Text("Recipe Library")
                    .font(.largeTitle.bold())

                Spacer()

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

            // Search and filters
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

            // Recipe grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(filteredRecipes) { recipe in
                        RecipeCardView(recipe: recipe)
                            .onTapGesture {
                                editingRecipe = recipe
                            }
                    }
                }
                .padding()
            }
            .background(Theme.surface)
        }
        .sheet(isPresented: $showingAddRecipe) {
            RecipeEditorView(recipes: $recipes, recipe: nil)
        }
        .sheet(item: $editingRecipe) { recipe in
            RecipeEditorView(recipes: $recipes, recipe: recipe)
        }
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

struct RecipeCardView: View {
    let recipe: Meal

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
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
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
