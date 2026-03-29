import Foundation

// MARK: - Optimization Settings

struct OptimizationSettings: Codable, Equatable {
    var goal: OptimizationGoal = .balanced
    var maxPrepTimePerDay: Int = 90 // minutes
    var varietyWeight: Double = 0.3
    var nutritionWeight: Double = 0.4
    var efficiencyWeight: Double = 0.3
    var avoidRepeats: Bool = true
    var useLeftovers: Bool = true
    var familySize: Int = 2

    enum OptimizationGoal: String, Codable, CaseIterable {
        case balanced = "Balanced"
        case highProtein = "High Protein"
        case lowCalorie = "Low Calorie"
        case variety = "Max Variety"
        case quickMeals = "Quick Meals"
        case budget = "Budget Friendly"
    }
}

// MARK: - Optimization Result

struct OptimizationResult: Equatable {
    let weekPlan: WeekPlan
    let insights: [String]
    let score: Double
}

// MARK: - Meal Plan Optimizer

final class MealPlanOptimizer {
    static let shared = MealPlanOptimizer()

    private init() {}

    // MARK: - Public API

    /// Generate an optimized weekly meal plan
    func generateWeekPlan(
        startingFrom startDate: Date,
        preferences: MealPreferences,
        settings: OptimizationSettings,
        availableRecipes: [Meal] = Meal.sampleRecipes
    ) -> OptimizationResult {
        var insights: [String] = []
        var score = 0.0

        // Build weekly nutrition targets
        let dailyCalorieTarget = preferences.calorieTarget.lowerBound
        let dailyProteinTarget = preferences.proteinTarget
        let dailyCarbsTarget = preferences.carbsTarget
        let dailyFatTarget = preferences.fatTarget

        // Initialize day plans
        var days: [DayPlan] = []
        var usedMeals: Set<String> = []
        var leftovers: [Meal] = []

        let calendar = Calendar.current

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }

            var dayPlan = DayPlan(date: date)

            // Check for leftovers from previous day
            if settings.useLeftovers && !leftovers.isEmpty {
                let leftoverSuggestion = AIRecipeService.shared.suggestLeftoverMeals(from: leftovers)
                if let leftoverMeal = leftoverSuggestion.first {
                    insights.append("\(formatDate(date)): Uses leftover chicken from Wednesday")
                    dayPlan.meals[.lunch] = leftoverMeal.meal
                    leftovers.removeAll()
                }
            }

            // Assign meals for each meal type
            for mealType in MealType.allCases {
                if dayPlan.meals[mealType]?.name != mealType.rawValue { continue } // Already assigned

                let candidates = availableRecipes.filter { recipe in
                    isValidCandidate(recipe, for: mealType, usedMeals: usedMeals, settings: settings, preferences: preferences)
                }

                guard let selected = selectBestCandidate(
                    candidates,
                    for: mealType,
                    day: date,
                    settings: settings,
                    preferences: preferences,
                    usedMeals: usedMeals
                ) else { continue }

                // Adjust servings for family
                var meal = selected
                meal.servings = settings.familySize

                dayPlan.meals[mealType] = meal
                usedMeals.insert(selected.name)

                // Track leftovers (cooked more than eaten)
                if selected.servings < settings.familySize {
                    leftovers.append(selected)
                }
            }

            // Validate daily nutrition
            let dailyNutrition = calculateDayNutrition(dayPlan)
            let dayInsight = validateDailyNutrition(dailyNutrition,
                                                     calorieTarget: dailyCalorieTarget,
                                                     proteinTarget: dailyProteinTarget,
                                                     carbsTarget: dailyCarbsTarget,
                                                     fatTarget: dailyFatTarget)
            if let insight = dayInsight {
                insights.append(insight)
            }

            days.append(dayPlan)
        }

        // Calculate overall score
        score = calculatePlanScore(days: days, settings: settings, preferences: preferences)

        // Add variety insights
        let varietyScore = calculateVarietyScore(usedMeals: usedMeals, totalRecipes: availableRecipes.count)
        if varietyScore > 0.7 {
            insights.append("Great variety! You have \(usedMeals.count) different meals planned.")
        }

        // Add prep time insight
        let totalPrepTime = days.flatMap { $0.meals.values }.reduce(0) { $0 + $1.cookTime }
        if totalPrepTime / 7 < 30 {
            insights.append("Efficient week: average \(totalPrepTime / 7) min prep per day")
        }

        let weekPlan = WeekPlan(startDate: startDate, days: days)
        return OptimizationResult(weekPlan: weekPlan, insights: insights, score: score)
    }

    /// Re-optimize a specific day in an existing plan
    func optimizeDay(
        in existingPlan: inout WeekPlan,
        dayIndex: Int,
        preferences: MealPreferences,
        settings: OptimizationSettings,
        availableRecipes: [Meal] = Meal.sampleRecipes
    ) -> String? {
        guard dayIndex < existingPlan.days.count else { return nil }

        var usedMeals = Set<String>()
        for (idx, day) in existingPlan.days.enumerated() where idx != dayIndex {
            for meal in day.meals.values {
                usedMeals.insert(meal.name)
            }
        }

        let date = existingPlan.days[dayIndex].date
        var dayPlan = DayPlan(date: date)

        var insight: String? = nil

        for mealType in MealType.allCases {
            let candidates = availableRecipes.filter { recipe in
                isValidCandidate(recipe, for: mealType, usedMeals: usedMeals, settings: settings, preferences: preferences)
            }

            if let selected = selectBestCandidate(candidates, for: mealType, day: date, settings: settings, preferences: preferences, usedMeals: usedMeals) {
                dayPlan.meals[mealType] = selected
                usedMeals.insert(selected.name)
            }
        }

        existingPlan.days[dayIndex] = dayPlan

        // Generate insight about the change
        let totalCalories = dayPlan.meals.values.reduce(0) { $0 + $1.nutrition.calories }
        if totalCalories < preferences.calorieTarget.lowerBound {
            insight = "Day optimized: \(totalCalories) cal — consider adding a snack"
        } else {
            insight = "Day optimized with balanced macros"
        }

        return insight
    }

    // MARK: - Private Helpers

    private func isValidCandidate(
        _ recipe: Meal,
        for mealType: MealType,
        usedMeals: Set<String>,
        settings: OptimizationSettings,
        preferences: MealPreferences
    ) -> Bool {
        // Check if already used (unless repeats allowed)
        if settings.avoidRepeats && usedMeals.contains(recipe.name) {
            return false
        }

        // Check prep time constraint
        if recipe.cookTime > settings.maxPrepTimePerDay {
            return false
        }

        // Check dietary restrictions
        for restriction in preferences.dietaryRestrictions {
            if recipe.tags.contains(restriction) == false && restriction != "Vegetarian" {
                // Don't exclude vegetarian meals for non-vegetarians
            }
            if recipe.tags.contains(restriction) {
                return true
            }
        }

        // Check excluded ingredients
        let ingredientNames = Set(recipe.ingredients.map { $0.name.lowercased() })
        if !ingredientNames.isDisjoint(with: preferences.excludedIngredients.map { $0.lowercased() }) {
            return false
        }

        // Match meal type
        if matchesMealType(recipe.tags, mealType: mealType) {
            return true
        }

        return true
    }

    private func selectBestCandidate(
        _ candidates: [Meal],
        for mealType: MealType,
        day: Date,
        settings: OptimizationSettings,
        preferences: MealPreferences,
        usedMeals: Set<String>
    ) -> Meal? {
        guard !candidates.isEmpty else { return nil }

        let scored = candidates.map { recipe -> (Meal, Double) in
            var score = 0.0

            switch settings.goal {
            case .balanced:
                score += nutritionScore(recipe, preferences: preferences) * settings.nutritionWeight
                score += varietyScore(recipe, usedMeals: usedMeals) * settings.varietyWeight
                score += efficiencyScore(recipe) * settings.efficiencyWeight

            case .highProtein:
                score = Double(recipe.nutrition.protein) / 50.0

            case .lowCalorie:
                score = 1.0 / max(Double(recipe.nutrition.calories), 1.0)

            case .variety:
                score = varietyScore(recipe, usedMeals: usedMeals)

            case .quickMeals:
                score = 1.0 / max(Double(recipe.cookTime), 1.0)

            case .budget:
                score = efficiencyScore(recipe)
            }

            return (recipe, score)
        }

        return scored.max(by: { $0.1 < $1.1 })?.0
    }

    private func nutritionScore(_ recipe: Meal, preferences: MealPreferences) -> Double {
        var score = 1.0

        let proteinRatio = Double(recipe.nutrition.protein) / Double(preferences.proteinTarget)
        let carbRatio = Double(recipe.nutrition.carbs) / Double(preferences.carbsTarget)
        let fatRatio = Double(recipe.nutrition.fat) / Double(preferences.fatTarget)

        // Closer to target = higher score
        score *= (1.0 - abs(1.0 - proteinRatio)) * 0.4
        score *= (1.0 - abs(1.0 - carbRatio)) * 0.3
        score *= (1.0 - abs(1.0 - fatRatio)) * 0.3

        return max(score, 0.1)
    }

    private func varietyScore(_ recipe: Meal, usedMeals: Set<String>) -> Double {
        if usedMeals.isEmpty { return 1.0 }

        let existingTags = Set(Meal.sampleRecipes
            .filter { usedMeals.contains($0.name) }
            .flatMap { $0.tags })

        let recipeTags = Set(recipe.tags)
        let overlap = recipeTags.intersection(existingTags)

        // Higher score for less overlap (more variety)
        return 1.0 - (Double(overlap.count) / max(Double(recipeTags.count), 1.0))
    }

    private func efficiencyScore(_ recipe: Meal) -> Double {
        // Higher score for meals that use common/shared ingredients efficiently
        let uniqueIngredients = Set(recipe.ingredients.map { $0.category })
        return Double(uniqueIngredients.count) / Double(GroceryCategory.allCases.count)
    }

    private func calculateDayNutrition(_ dayPlan: DayPlan) -> NutritionInfo {
        var total = NutritionInfo()
        for meal in dayPlan.meals.values {
            total.calories += meal.nutrition.calories
            total.protein += meal.nutrition.protein
            total.carbs += meal.nutrition.carbs
            total.fat += meal.nutrition.fat
        }
        return total
    }

    private func validateDailyNutrition(
        _ nutrition: NutritionInfo,
        calorieTarget: Int,
        proteinTarget: Int,
        carbsTarget: Int,
        fatTarget: Int
    ) -> String? {
        if nutrition.calories < calorieTarget - 300 {
            return "Low calories today (\(nutrition.calories)) — add a snack"
        }
        if nutrition.protein < proteinTarget / 2 {
            return "Low protein (\(nutrition.protein)g) — consider adding protein"
        }
        if nutrition.calories > calorieTarget + 400 {
            return "High calories today (\(nutrition.calories))"
        }
        return nil
    }

    private func calculatePlanScore(days: [DayPlan], settings: OptimizationSettings, preferences: MealPreferences) -> Double {
        var totalScore = 0.0

        for day in days {
            let nutrition = calculateDayNutrition(day)
            totalScore += nutritionScore(nutrition, preferences: preferences)
        }

        return totalScore / Double(max(days.count, 1))
    }

    private func nutritionScore(_ nutrition: NutritionInfo, preferences: MealPreferences) -> Double {
        var score = 1.0

        let proteinRatio = Double(nutrition.protein) / Double(preferences.proteinTarget)
        let carbRatio = Double(nutrition.carbs) / Double(preferences.carbsTarget)
        let fatRatio = Double(nutrition.fat) / Double(preferences.fatTarget)

        score *= (1.0 - abs(1.0 - proteinRatio)) * 0.4
        score *= (1.0 - abs(1.0 - carbRatio)) * 0.3
        score *= (1.0 - abs(1.0 - fatRatio)) * 0.3

        return max(score, 0.1)
    }

    private func matchesMealType(_ tags: [String], mealType: MealType) -> Bool {
        switch mealType {
        case .breakfast: return tags.contains("Breakfast") || tags.contains("Quick")
        case .lunch: return tags.contains("Lunch") || tags.contains("Healthy")
        case .dinner: return tags.contains("Dinner")
        case .snacks: return tags.contains("Snacks") || tags.contains("Quick")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

// MARK: - Fix: Meal sampleRecipes reference

extension Meal {
    static var optimizedSampleRecipes: [Meal] {
        return Meal.sampleRecipes
    }
}
