import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var recipes: [Meal] = Meal.sampleRecipes
    @State private var weekPlan = WeekPlan(startDate: Date())
    @State private var groceryItems: [GroceryItem] = []
    @State private var selectedMeal: Meal?
    @State private var showingRecipePicker = false
    @State private var currentEditingDay: DayPlan?
    @State private var currentEditingMealType: MealType?

    var body: some View {
        TabView(selection: $selectedTab) {
            WeeklyPlanView(
                weekPlan: $weekPlan,
                recipes: recipes,
                selectedMeal: $selectedMeal,
                showingRecipePicker: $showingRecipePicker,
                currentEditingDay: $currentEditingDay,
                currentEditingMealType: $currentEditingMealType
            )
            .tabItem {
                Label("Meal Plan", systemImage: "calendar")
            }
            .tag(0)

            RecipeLibraryView(recipes: $recipes)
                .tabItem {
                    Label("Recipes", systemImage: "book.fill")
                }
                .tag(1)

            GroceryListView(groceryItems: $groceryItems)
                .tabItem {
                    Label("Grocery", systemImage: "cart.fill")
                }
                .tag(2)

            NutritionView(weekPlan: weekPlan)
                .tabItem {
                    Label("Nutrition", systemImage: "chart.bar.fill")
                }
                .tag(3)
        }
        .tint(Theme.kaleGreen)
        .onChange(of: weekPlan) { _, _ in
            updateGroceryList()
        }
        .sheet(isPresented: $showingRecipePicker) {
            RecipePickerView(
                recipes: recipes,
                selectedMeal: $selectedMeal,
                onSelect: { meal in
                    assignMeal(meal)
                }
            )
        }
    }

    private func updateGroceryList() {
        var items: [GroceryItem] = []

        for day in weekPlan.days {
            for (mealType, meal) in day.meals {
                // Skip sentinel/unassigned meals
                if meal.name == mealType.rawValue && meal.cookTime == 0 { continue }
                for ingredient in meal.ingredients {
                    if let existingIndex = items.firstIndex(where: { $0.name == ingredient.name && !$0.isChecked }) {
                        items[existingIndex].quantity += ingredient.quantity
                    } else {
                        items.append(GroceryItem(
                            name: ingredient.name,
                            quantity: ingredient.quantity,
                            unit: ingredient.unit,
                            category: ingredient.category,
                            fromMeal: meal.name
                        ))
                    }
                }
            }
        }

        // Preserve checked state for existing items
        for (index, item) in items.enumerated() {
            if let existingItem = groceryItems.first(where: { $0.name == item.name && $0.isChecked }) {
                items[index].isChecked = true
            }
        }

        groceryItems = items
    }

    private func assignMeal(_ meal: Meal) {
        guard let day = currentEditingDay,
              let mealType = currentEditingMealType,
              let dayIndex = weekPlan.days.firstIndex(where: { $0.id == day.id }) else {
            return
        }

        weekPlan.days[dayIndex].meals[mealType] = meal
        selectedMeal = nil
        currentEditingDay = nil
        currentEditingMealType = nil
    }
}

struct RecipePickerView: View {
    let recipes: [Meal]
    @Binding var selectedMeal: Meal?
    let onSelect: (Meal) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var filteredRecipes: [Meal] {
        if searchText.isEmpty {
            return recipes
        }
        return recipes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search recipes...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding()

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(filteredRecipes) { recipe in
                            Button {
                                onSelect(recipe)
                                dismiss()
                            } label: {
                                RecipePickerCard(recipe: recipe)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Select Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
}

struct RecipePickerCard: View {
    let recipe: Meal

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.primaryGradient)
                    .frame(width: 50, height: 50)

                Image(systemName: "fork.knife")
                    .font(.title3)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    Label("\(recipe.cookTime)m", systemImage: "clock")
                    Label("\(recipe.nutrition.calories) cal", systemImage: "flame")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(Theme.kaleGreen)
        }
        .padding()
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
