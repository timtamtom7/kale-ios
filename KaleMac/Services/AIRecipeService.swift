import Foundation
import NaturalLanguage

// MARK: - Supporting Types

struct MealPreferences: Codable, Equatable {
    var dietaryRestrictions: Set<String> = []
    var cuisinePreferences: Set<String> = []
    var excludedIngredients: Set<String> = []
    var calorieTarget: ClosedRange<Int> = 0...2500
    var proteinTarget: Int = 50
    var carbsTarget: Int = 250
    var fatTarget: Int = 65
    var preferredPrepTime: Int? = nil // minutes, nil = no preference
    var weeklyHistory: [String] = [] // meal names already eaten this week

    init(
        dietaryRestrictions: Set<String> = [],
        cuisinePreferences: Set<String> = [],
        excludedIngredients: Set<String> = [],
        calorieTarget: ClosedRange<Int> = 0...2500,
        proteinTarget: Int = 50,
        carbsTarget: Int = 250,
        fatTarget: Int = 65,
        preferredPrepTime: Int? = nil,
        weeklyHistory: [String] = []
    ) {
        self.dietaryRestrictions = dietaryRestrictions
        self.cuisinePreferences = cuisinePreferences
        self.excludedIngredients = excludedIngredients
        self.calorieTarget = calorieTarget
        self.proteinTarget = proteinTarget
        self.carbsTarget = carbsTarget
        self.fatTarget = fatTarget
        self.preferredPrepTime = preferredPrepTime
        self.weeklyHistory = weeklyHistory
    }
}

struct MealSuggestion: Identifiable, Equatable {
    let id: UUID
    let meal: Meal
    let reason: String
    let matchScore: Double
    let tags: [String]

    init(id: UUID = UUID(), meal: Meal, reason: String, matchScore: Double = 0.5, tags: [String] = []) {
        self.id = id
        self.meal = meal
        self.reason = reason
        self.matchScore = matchScore
        self.tags = tags
    }
}

// MARK: - AI Recipe Service

final class AIRecipeService {
    static let shared = AIRecipeService()

    private let tagEmbedder = NLTagger(tagSchemes: [.nameType, .lexicalClass])

    private init() {}

    // MARK: - Public API

    /// Returns contextual meal suggestions for a given day
    func suggestMeals(for day: Date, preferences: MealPreferences) -> [MealSuggestion] {
        let recipes = Meal.sampleRecipes

        // 1. Filter out already-eaten meals
        let available = recipes.filter { !preferences.weeklyHistory.contains($0.name) }

        // 2. Score each recipe
        let scored = available.map { recipe -> (Meal, Double, String) in
            let (score, reason) = scoreRecipe(recipe, against: preferences, day: day)
            return (recipe, score, reason)
        }

        // 3. Sort by score descending
        let sorted = scored.sorted { $0.1 > $1.1 }

        // 4. Return top suggestions
        return sorted.prefix(3).map { meal, score, reason in
            let tags = generateSuggestionTags(for: meal, preferences: preferences)
            return MealSuggestion(meal: meal, reason: reason, matchScore: score, tags: tags)
        }
    }

    /// Returns suggestions for a specific meal type on a given day
    func suggestMeal(for mealType: MealType, day: Date, preferences: MealPreferences) -> MealSuggestion? {
        let recipes = Meal.sampleRecipes.filter { $0.tags.contains(mealType.rawValue) || matchesMealTypeTag($0.tags, mealType: mealType) }
        let available = recipes.filter { !preferences.weeklyHistory.contains($0.name) }

        let scored = available.map { recipe -> (Meal, Double, String) in
            let (score, reason) = scoreRecipe(recipe, against: preferences, day: day)
            return (recipe, score, reason)
        }

        guard let best = scored.max(by: { $0.1 < $1.1 }) else { return nil }
        return MealSuggestion(meal: best.0, reason: best.2, matchScore: best.1, tags: generateSuggestionTags(for: best.0, preferences: preferences))
    }

    /// Suggests meals that use leftover ingredients
    func suggestLeftoverMeals(from previousMeals: [Meal]) -> [MealSuggestion] {
        let recipes = Meal.sampleRecipes
        var suggestions: [MealSuggestion] = []

        for previousMeal in previousMeals {
            for recipe in recipes {
                let sharedIngredients = Set(previousMeal.ingredients.map { $0.name.lowercased() })
                    .intersection(Set(recipe.ingredients.map { $0.name.lowercased() }))

                if !sharedIngredients.isEmpty {
                    let reason = "Uses leftover \(sharedIngredients.formatted()) from \(previousMeal.name)"
                    suggestions.append(MealSuggestion(
                        meal: recipe,
                        reason: reason,
                        matchScore: Double(sharedIngredients.count) / Double(max(recipe.ingredients.count, 1)),
                        tags: ["leftover-friendly"]
                    ))
                }
            }
        }

        return suggestions.sorted { $0.matchScore > $1.matchScore }.prefix(3).map { $0 }
    }

    // MARK: - Private Helpers

    private func scoreRecipe(_ recipe: Meal, against preferences: MealPreferences, day: Date) -> (Double, String) {
        var score = 0.5
        var reasons: [String] = []

        // Tag matching
        let matchingCuisines = recipe.tags.filter { preferences.cuisinePreferences.contains($0) }
        if !matchingCuisines.isEmpty {
            score += 0.15
            reasons.append("Matches your \(matchingCuisines.formatted()) preference")
        }

        // Protein balance
        if recipe.nutrition.protein > preferences.proteinTarget / 3 {
            score += 0.1
            reasons.append("Good protein content (\(recipe.nutrition.protein)g)")
        }

        // Calorie fit
        if preferences.calorieTarget.contains(recipe.nutrition.calories) {
            score += 0.1
        } else if recipe.nutrition.calories < preferences.calorieTarget.lowerBound {
            score -= 0.05
        } else {
            score -= 0.1
        }

        // Prep time preference
        if let prefTime = preferences.preferredPrepTime {
            if recipe.cookTime <= prefTime {
                score += 0.1
                reasons.append("Quick prep (\(recipe.cookTime)m)")
            }
        }

        // Fish suggestion if no fish eaten recently
        if recipe.tags.contains("Omega-3") && !preferences.weeklyHistory.contains(where: { $0.lowercased().contains("salmon") || $0.lowercased().contains("fish") }) {
            score += 0.15
            reasons.append("You haven't had fish this week — try \(recipe.name)")
        }

        // Variety — score down if similar to recent meals
        if preferences.weeklyHistory.contains(where: { hasSimilarIngredients($0, recipe) }) {
            score -= 0.1
        }

        let reason = reasons.first ?? "Recommended for you"
        return (min(max(score, 0.0), 1.0), reason)
    }

    private func generateSuggestionTags(for recipe: Meal, preferences: MealPreferences) -> [String] {
        var tags: [String] = []

        if recipe.nutrition.protein > 35 {
            tags.append("high-protein")
        }
        if recipe.cookTime <= 20 {
            tags.append("quick")
        }
        if recipe.tags.contains("Healthy") || recipe.tags.contains("Omega-3") {
            tags.append("nutritious")
        }
        if !Set(recipe.ingredients.map { $0.name.lowercased() }).isDisjoint(with: Set(["salmon", "fish", "tuna"))) {
            tags.append("seafood")
        }

        return tags
    }

    private func matchesMealTypeTag(_ tags: [String], mealType: MealType) -> Bool {
        switch mealType {
        case .breakfast: return tags.contains("Breakfast") || tags.contains("Quick")
        case .lunch: return tags.contains("Lunch") || tags.contains("Healthy")
        case .dinner: return tags.contains("Dinner")
        case .snacks: return tags.contains("Snacks") || tags.contains("Quick")
        }
    }

    private func hasSimilarIngredients(_ mealName: String, _ recipe: Meal) -> Bool {
        guard let previous = Meal.sampleRecipes.first(where: { $0.name == mealName }) else { return false }
        let shared = Set(previous.ingredients.map { $0.name.lowercased() })
            .intersection(Set(recipe.ingredients.map { $0.name.lowercased() }))
        return shared.count >= 2
    }
}
