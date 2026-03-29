import Foundation

// MARK: - Meal & Recipe Models

struct Meal: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var cookTime: Int // minutes
    var servings: Int
    var tags: [String] // cuisine, meal type, diet
    var ingredients: [Ingredient]
    var nutrition: NutritionInfo
    var instructions: [String]

    init(id: UUID = UUID(), name: String, cookTime: Int = 30, servings: Int = 2, tags: [String] = [], ingredients: [Ingredient] = [], nutrition: NutritionInfo = NutritionInfo(), instructions: [String] = []) {
        self.id = id
        self.name = name
        self.cookTime = cookTime
        self.servings = servings
        self.tags = tags
        self.ingredients = ingredients
        self.nutrition = nutrition
        self.instructions = instructions
    }
}

struct Ingredient: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var quantity: Double
    var unit: String
    var category: GroceryCategory

    init(id: UUID = UUID(), name: String, quantity: Double, unit: String, category: GroceryCategory = .pantry) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
    }
}

struct NutritionInfo: Codable, Hashable {
    var calories: Int
    var protein: Int // grams
    var carbs: Int // grams
    var fat: Int // grams

    init(calories: Int = 0, protein: Int = 0, carbs: Int = 0, fat: Int = 0) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
}

enum GroceryCategory: String, Codable, CaseIterable {
    case produce = "Produce"
    case dairy = "Dairy"
    case meat = "Meat & Seafood"
    case pantry = "Pantry"
    case frozen = "Frozen"
    case bakery = "Bakery"
    case beverages = "Beverages"
    case other = "Other"

    var icon: String {
        switch self {
        case .produce: return "leaf.fill"
        case .dairy: return "cup.and.saucer.fill"
        case .meat: return "fish.fill"
        case .pantry: return "cabinet.fill"
        case .frozen: return "snowflake"
        case .bakery: return "birthday.cake.fill"
        case .beverages: return "wineglass.fill"
        case .other: return "bag.fill"
        }
    }
}

enum MealType: String, Codable, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snacks = "Snacks"

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snacks: return "carrot.fill"
        }
    }
}

// MARK: - Meal Plan

struct DayPlan: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var meals: [MealType: Meal]

    init(id: UUID = UUID(), date: Date, meals: [MealType: Meal] = [:]) {
        self.id = id
        self.date = date
        var defaultMeals: [MealType: Meal] = [:]
        for type in MealType.allCases {
            defaultMeals[type] = Meal(name: type.rawValue, cookTime: 0, servings: 1, tags: [], ingredients: [], nutrition: NutritionInfo(), instructions: [])
        }
        self.meals = meals.isEmpty ? defaultMeals : meals
    }
}

struct WeekPlan: Identifiable, Codable, Equatable {
    let id: UUID
    var startDate: Date
    var days: [DayPlan]

    init(id: UUID = UUID(), startDate: Date, days: [DayPlan] = []) {
        self.id = id
        self.startDate = startDate
        self.days = days
    }
}

// MARK: - Grocery Item

struct GroceryItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var quantity: Double
    var unit: String
    var category: GroceryCategory
    var isChecked: Bool
    var fromMeal: String?

    init(id: UUID = UUID(), name: String, quantity: Double, unit: String, category: GroceryCategory, isChecked: Bool = false, fromMeal: String? = nil) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.isChecked = isChecked
        self.fromMeal = fromMeal
    }
}

// MARK: - Sample Data

extension Meal {
    static let sampleRecipes: [Meal] = [
        Meal(
            name: "Avocado Toast with Eggs",
            cookTime: 15,
            servings: 2,
            tags: ["Breakfast", "Quick", "Vegetarian"],
            ingredients: [
                Ingredient(name: "Bread", quantity: 2, unit: "slices", category: .bakery),
                Ingredient(name: "Avocado", quantity: 1, unit: "whole", category: .produce),
                Ingredient(name: "Eggs", quantity: 2, unit: "whole", category: .dairy),
                Ingredient(name: "Olive Oil", quantity: 1, unit: "tbsp", category: .pantry)
            ],
            nutrition: NutritionInfo(calories: 350, protein: 15, carbs: 28, fat: 22),
            instructions: ["Toast bread", "Mash avocado", "Fry eggs", "Assemble and serve"]
        ),
        Meal(
            name: "Grilled Chicken Salad",
            cookTime: 25,
            servings: 2,
            tags: ["Lunch", "Healthy", "High-Protein"],
            ingredients: [
                Ingredient(name: "Chicken Breast", quantity: 200, unit: "g", category: .meat),
                Ingredient(name: "Mixed Greens", quantity: 100, unit: "g", category: .produce),
                Ingredient(name: "Cherry Tomatoes", quantity: 100, unit: "g", category: .produce),
                Ingredient(name: "Olive Oil", quantity: 2, unit: "tbsp", category: .pantry)
            ],
            nutrition: NutritionInfo(calories: 420, protein: 45, carbs: 12, fat: 24),
            instructions: ["Season chicken", "Grill until cooked", "Slice and toss with greens", "Add tomatoes and dressing"]
        ),
        Meal(
            name: "Salmon with Roasted Vegetables",
            cookTime: 40,
            servings: 2,
            tags: ["Dinner", "Healthy", "Omega-3"],
            ingredients: [
                Ingredient(name: "Salmon Fillet", quantity: 300, unit: "g", category: .meat),
                Ingredient(name: "Broccoli", quantity: 200, unit: "g", category: .produce),
                Ingredient(name: "Sweet Potato", quantity: 2, unit: "whole", category: .produce),
                Ingredient(name: "Lemon", quantity: 1, unit: "whole", category: .produce)
            ],
            nutrition: NutritionInfo(calories: 550, protein: 40, carbs: 35, fat: 28),
            instructions: ["Preheat oven to 400°F", "Season salmon", "Cut vegetables", "Roast for 25 minutes", "Serve together"]
        ),
        Meal(
            name: "Greek Yogurt Parfait",
            cookTime: 5,
            servings: 1,
            tags: ["Snacks", "Quick", "Healthy"],
            ingredients: [
                Ingredient(name: "Greek Yogurt", quantity: 200, unit: "g", category: .dairy),
                Ingredient(name: "Granola", quantity: 50, unit: "g", category: .pantry),
                Ingredient(name: "Blueberries", quantity: 50, unit: "g", category: .produce),
                Ingredient(name: "Honey", quantity: 1, unit: "tbsp", category: .pantry)
            ],
            nutrition: NutritionInfo(calories: 280, protein: 18, carbs: 38, fat: 8),
            instructions: ["Layer yogurt in glass", "Add granola", "Top with berries", "Drizzle honey"]
        )
    ]
}

// MARK: - Nutrition Insight

struct NutritionInsight: Identifiable {
    let id: UUID
    let message: String
    let severity: InsightSeverity
    let affectedNutrient: String?
    let suggestion: String?

    init(id: UUID = UUID(), message: String, severity: InsightSeverity, affectedNutrient: String? = nil, suggestion: String? = nil) {
        self.id = id
        self.message = message
        self.severity = severity
        self.affectedNutrient = affectedNutrient
        self.suggestion = suggestion
    }
}

enum InsightSeverity {
    case info
    case warning
    case alert
}
