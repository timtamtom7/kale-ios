import SwiftUI

struct NutritionView: View {
    let weekPlan: WeekPlan

    private var dailyNutrition: [(Date, NutritionInfo)] {
        weekPlan.days.map { day in
            var total = NutritionInfo()
            for (mealType, meal) in day.meals {
                // Skip sentinel/unassigned meals
                if meal.name == mealType.rawValue && meal.cookTime == 0 { continue }
                total.calories += meal.nutrition.calories
                total.protein += meal.nutrition.protein
                total.carbs += meal.nutrition.carbs
                total.fat += meal.nutrition.fat
            }
            return (day.date, total)
        }
    }

    private var weeklyTotals: NutritionInfo {
        var total = NutritionInfo()
        for (_, nutrition) in dailyNutrition {
            total.calories += nutrition.calories
            total.protein += nutrition.protein
            total.carbs += nutrition.carbs
            total.fat += nutrition.fat
        }
        return total
    }

    private var averageDaily: NutritionInfo {
        let count = max(dailyNutrition.filter { $0.1.calories > 0 }.count, 1)
        return NutritionInfo(
            calories: weeklyTotals.calories / count,
            protein: weeklyTotals.protein / count,
            carbs: weeklyTotals.carbs / count,
            fat: weeklyTotals.fat / count
        )
    }

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Nutrition Summary")
                    .font(.largeTitle.bold())
                Spacer()
            }
            .padding()
            .background(Theme.cream)

            ScrollView {
                VStack(spacing: 24) {
                    // Weekly averages
                    VStack(spacing: 16) {
                        Text("Daily Average")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 24) {
                            NutritionRing(title: "Calories", value: averageDaily.calories, goal: 2000, unit: "", color: Theme.tomato)
                            NutritionRing(title: "Protein", value: averageDaily.protein, goal: 50, unit: "g", color: Theme.kaleGreen)
                            NutritionRing(title: "Carbs", value: averageDaily.carbs, goal: 250, unit: "g", color: Theme.avocado)
                            NutritionRing(title: "Fat", value: averageDaily.fat, goal: 65, unit: "g", color: Theme.fatOrange)
                        }
                    }
                    .padding()
                    .background(Theme.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

                    // Daily breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily Breakdown")
                            .font(.headline)

                        ForEach(dailyNutrition, id: \.0) { date, nutrition in
                            DailyNutritionRow(
                                day: dayFormatter.string(from: date),
                                isToday: Calendar.current.isDateInToday(date),
                                nutrition: nutrition
                            )
                        }
                    }
                    .padding()
                    .background(Theme.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

                    // Weekly totals
                    VStack(spacing: 12) {
                        Text("Weekly Totals")
                            .font(.headline)

                        HStack(spacing: 16) {
                            WeeklyTotalCard(title: "Calories", value: weeklyTotals.calories, unit: "kcal", icon: "flame.fill", color: Theme.tomato)
                            WeeklyTotalCard(title: "Protein", value: weeklyTotals.protein, unit: "g", icon: "figure.strengthtraining.traditional", color: Theme.kaleGreen)
                            WeeklyTotalCard(title: "Carbs", value: weeklyTotals.carbs, unit: "g", icon: "leaf.fill", color: Theme.avocado)
                            WeeklyTotalCard(title: "Fat", value: weeklyTotals.fat, unit: "g", icon: "drop.fill", color: Theme.fatOrange)
                        }
                    }
                    .padding()
                    .background(Theme.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                }
                .padding()
            }
            .background(Theme.surface)
        }
    }
}

struct NutritionRing: View {
    let title: String
    let value: Int
    let goal: Int
    let unit: String
    let color: Color

    var progress: Double {
        min(Double(value) / Double(goal), 1.0)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: progress)

                VStack(spacing: 0) {
                    Text("\(value)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 80, height: 80)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct DailyNutritionRow: View {
    let day: String
    let isToday: Bool
    let nutrition: NutritionInfo

    var hasData: Bool {
        nutrition.calories > 0
    }

    var body: some View {
        HStack {
            Text(day)
                .font(.subheadline.bold())
                .foregroundStyle(isToday ? Theme.kaleGreen : .primary)
                .frame(width: 50, alignment: .leading)

            // Calorie bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(nsColor: .controlBackgroundColor))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.primaryGradient)
                        .frame(width: geo.size.width * min(CGFloat(nutrition.calories) / 2500, 1))
                }
            }
            .frame(height: 20)

            Spacer()

            if hasData {
                HStack(spacing: 16) {
                    NutrientBadge(value: nutrition.calories, unit: "", color: Theme.tomato)
                    NutrientBadge(value: nutrition.protein, unit: "g P", color: Theme.kaleGreen)
                    NutrientBadge(value: nutrition.carbs, unit: "g C", color: Theme.avocado)
                    NutrientBadge(value: nutrition.fat, unit: "g F", color: Theme.fatOrange)
                }
            } else {
                Text("No data")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct NutrientBadge: View {
    let value: Int
    let unit: String
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 11, weight: .medium))
            Text(unit)
                .font(.system(size: 9))
        }
        .foregroundStyle(color)
    }
}

struct WeeklyTotalCard: View {
    let title: String
    let value: Int
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text("\(value)")
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
