import SwiftUI

struct NutritionAnalysisView: View {
    let weekPlan: WeekPlan
    @State private var selectedTab: AnalysisTab = .macros
    @State private var showingGoalEditor = false

    enum AnalysisTab: String, CaseIterable {
        case macros = "Macros"
        case trends = "Trends"
        case insights = "Insights"
    }

    // MARK: - Computed Data

    private var dailyNutrition: [(Date, NutritionInfo)] {
        weekPlan.days.map { day in
            var total = NutritionInfo()
            for (_, meal) in day.meals {
                if meal.name.isEmpty || meal.cookTime == 0 { continue }
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

    private var insights: [NutritionInsight] {
        generateInsights()
    }

    // Goals
    private let calorieGoal = 2000
    private let proteinGoal = 50
    private let carbsGoal = 250
    private let fatGoal = 65

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Nutrition Analysis")
                    .font(.largeTitle.bold())
                Spacer()
                Button {
                    showingGoalEditor = true
                } label: {
                    Label("Goals", systemImage: "target")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Theme.cream)

            // Tab selector
            Picker("", selection: $selectedTab) {
                ForEach(AnalysisTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            ScrollView {
                VStack(spacing: 24) {
                    switch selectedTab {
                    case .macros:
                        macrosTab
                    case .trends:
                        trendsTab
                    case .insights:
                        insightsTab
                    }
                }
                .padding()
            }
            .background(Theme.surface)
        }
        .sheet(isPresented: $showingGoalEditor) {
            GoalEditorView()
        }
    }

    // MARK: - Macros Tab

    private var macrosTab: some View {
        VStack(spacing: 24) {
            // Daily average rings
            VStack(spacing: 16) {
                Text("Daily Average")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 32) {
                    MacroRing(title: "Calories", value: averageDaily.calories, goal: calorieGoal, unit: "kcal", color: Theme.tomato, icon: "flame.fill")
                    MacroRing(title: "Protein", value: averageDaily.protein, goal: proteinGoal, unit: "g", color: Theme.kaleGreen, icon: "figure.strengthtraining.traditional")
                    MacroRing(title: "Carbs", value: averageDaily.carbs, goal: carbsGoal, unit: "g", color: Theme.avocado, icon: "leaf.fill")
                    MacroRing(title: "Fat", value: averageDaily.fat, goal: fatGoal, unit: "g", color: Color(hex: "FF9800"), icon: "drop.fill")
                }
            }
            .padding()
            .background(Theme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

            // Weekly macro breakdown
            VStack(spacing: 16) {
                Text("Macro Breakdown")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 0) {
                    MacroBarSlice(value: weeklyTotals.protein * 4, total: weeklyTotals.calories, color: Theme.kaleGreen, label: "Protein")
                    MacroBarSlice(value: weeklyTotals.carbs * 4, total: weeklyTotals.calories, color: Theme.avocado, label: "Carbs")
                    MacroBarSlice(value: weeklyTotals.fat * 9, total: weeklyTotals.calories, color: Color(hex: "FF9800"), label: "Fat")
                }
                .frame(height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 24) {
                    MacroLegend(color: Theme.kaleGreen, label: "Protein", value: "\(weeklyTotals.protein)g", cals: "\(weeklyTotals.protein * 4) cal")
                    MacroLegend(color: Theme.avocado, label: "Carbs", value: "\(weeklyTotals.carbs)g", cals: "\(weeklyTotals.carbs * 4) cal")
                    MacroLegend(color: Color(hex: "FF9800"), label: "Fat", value: "\(weeklyTotals.fat)g", cals: "\(weeklyTotals.fat * 9) cal")
                }
                .font(.caption)
            }
            .padding()
            .background(Theme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

            // Daily breakdown table
            VStack(spacing: 16) {
                Text("Daily Breakdown")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(dailyNutrition, id: \.0) { date, nutrition in
                    AnalysisDailyRow(
                        day: dayFormatter.string(from: date),
                        isToday: Calendar.current.isDateInToday(date),
                        nutrition: nutrition,
                        calorieGoal: calorieGoal
                    )
                }
            }
            .padding()
            .background(Theme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }

    // MARK: - Trends Tab

    private var trendsTab: some View {
        VStack(spacing: 24) {
            // Calorie trend chart
            VStack(spacing: 16) {
                Text("Calorie Trend")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                CalorieTrendChart(dailyData: dailyNutrition, goal: calorieGoal)
                    .frame(height: 150)
            }
            .padding()
            .background(Theme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

            // Protein trend
            VStack(spacing: 16) {
                Text("Protein Trend")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                MacroTrendChart(dailyData: dailyNutrition.map { ($0.0, $0.1.protein) }, goal: proteinGoal, color: Theme.kaleGreen)
                    .frame(height: 100)
            }
            .padding()
            .background(Theme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

            // Week comparison
            VStack(spacing: 16) {
                Text("Weekly Summary")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 16) {
                    WeeklyStatCard(title: "Avg Daily Cal", value: "\(averageDaily.calories)", goal: "\(calorieGoal)", icon: "flame.fill", color: Theme.tomato)
                    WeeklyStatCard(title: "Total Protein", value: "\(weeklyTotals.protein)g", goal: "\(proteinGoal * 7)g", icon: "figure.strengthtraining.traditional", color: Theme.kaleGreen)
                    WeeklyStatCard(title: "Days On Target", value: "\(daysOnTarget)/7", goal: "5+", icon: "checkmark.circle.fill", color: Theme.avocado)
                }
            }
            .padding()
            .background(Theme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }

    // MARK: - Insights Tab

    private var insightsTab: some View {
        VStack(spacing: 16) {
            Text("AI Insights")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(insights) { insight in
                InsightCard(insight: insight)
            }

            if insights.isEmpty {
                ContentUnavailableView(
                    "No Insights Yet",
                    systemImage: "lightbulb",
                    description: Text("Add meals to your plan to get personalized nutrition insights")
                )
                .padding(.vertical, 40)
            }
        }
    }

    // MARK: - Helper Properties

    private var daysOnTarget: Int {
        dailyNutrition.filter { nutrition in
            let cal = nutrition.1.calories
            return cal >= calorieGoal - 300 && cal <= calorieGoal + 400
        }.count
    }

    // MARK: - Insight Generation

    private func generateInsights() -> [NutritionInsight] {
        var result: [NutritionInsight] = []

        // Check protein
        let avgProtein = averageDaily.protein
        if avgProtein < proteinGoal {
            result.append(NutritionInsight(
                message: "You're low on protein this week",
                severity: .warning,
                affectedNutrient: "Protein",
                suggestion: "Try adding Greek Yogurt Parfait or Grilled Chicken Salad for extra protein"
            ))
        }

        // Check calorie balance
        let avgCals = averageDaily.calories
        if avgCals < calorieGoal - 300 {
            result.append(NutritionInsight(
                message: "You're running a calorie deficit",
                severity: .info,
                affectedNutrient: "Calories",
                suggestion: "Consider adding snacks or larger portions to meet your energy needs"
            ))
        } else if avgCals > calorieGoal + 400 {
            result.append(NutritionInsight(
                message: "Calorie intake is above target",
                severity: .warning,
                affectedNutrient: "Calories",
                suggestion: "Try swapping one meal for a lighter option"
            ))
        }

        // Check variety
        let uniqueMeals = Set(dailyNutrition.flatMap { date, _ in
            weekPlan.days.first { Calendar.current.isDate($0.date, inSameDayAs: date) }?.meals.values.map { $0.name } ?? []
        }).count
        if uniqueMeals < 5 {
            result.append(NutritionInsight(
                message: "Limited meal variety this week",
                severity: .info,
                affectedNutrient: nil,
                suggestion: "Try the AI optimizer for more diverse meal suggestions"
            ))
        }

        // Check fat balance
        let avgFat = averageDaily.fat
        if avgFat > fatGoal {
            result.append(NutritionInsight(
                message: "Fat intake is above target",
                severity: .warning,
                affectedNutrient: "Fat",
                suggestion: "Choose grilled proteins over fried options"
            ))
        }

        // Positive insight
        if avgProtein >= proteinGoal && avgCals >= calorieGoal - 200 && avgCals <= calorieGoal + 200 {
            result.append(NutritionInsight(
                message: "Great job! Your nutrition is well balanced this week",
                severity: .info,
                affectedNutrient: nil,
                suggestion: nil
            ))
        }

        return result
    }
}

// MARK: - Supporting Views

struct MacroRing: View {
    let title: String
    let value: Int
    let goal: Int
    let unit: String
    let color: Color
    let icon: String

    var progress: Double {
        min(Double(value) / Double(goal), 1.0)
    }

    var statusColor: Color {
        let ratio = Double(value) / Double(goal)
        if ratio < 0.8 { return .orange }
        if ratio > 1.1 { return .red }
        return Theme.kaleGreen
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 10)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(statusColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: progress)

                VStack(spacing: 0) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(statusColor)
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
            }
            .frame(width: 90, height: 90)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(value)/\(goal)\(unit)")
                .font(.caption2)
                .foregroundStyle(statusColor)
        }
    }
}

struct MacroBarSlice: View {
    let value: Int
    let total: Int
    let color: Color
    let label: String

    var ratio: Double {
        guard total > 0 else { return 0 }
        return min(Double(value) / Double(total), 1.0)
    }

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(color)
                .frame(width: geo.size.width * ratio)
        }
    }
}

struct MacroLegend: View {
    let color: Color
    let label: String
    let value: String
    let cals: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2.bold())
                Text(value)
                    .font(.caption2)
                Text(cals)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct AnalysisDailyRow: View {
    let day: String
    let isToday: Bool
    let nutrition: NutritionInfo
    let calorieGoal: Int

    var calorieStatus: Color {
        let cal = nutrition.calories
        if cal == 0 { return .secondary }
        if cal < calorieGoal - 300 { return .orange }
        if cal > calorieGoal + 400 { return .red }
        return Theme.kaleGreen
    }

    var body: some View {
        HStack {
            Text(day)
                .font(.subheadline.bold())
                .foregroundStyle(isToday ? Theme.kaleGreen : .primary)
                .frame(width: 50, alignment: .leading)

            // Status indicator
            Circle()
                .fill(calorieStatus)
                .frame(width: 8, height: 8)

            Spacer()

            HStack(spacing: 16) {
                TrendNutrientBadge(value: nutrition.calories, unit: "", color: Theme.tomato)
                TrendNutrientBadge(value: nutrition.protein, unit: "g", color: Theme.kaleGreen)
                TrendNutrientBadge(value: nutrition.carbs, unit: "g", color: Theme.avocado)
                TrendNutrientBadge(value: nutrition.fat, unit: "g", color: Color(hex: "FF9800"))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isToday ? Theme.kaleGreen.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct TrendNutrientBadge: View {
    let value: Int
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)\(unit)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(value > 0 ? .primary : .tertiary)
            Text(unit.isEmpty ? "cal" : unit)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 40)
    }
}

struct CalorieTrendChart: View {
    let dailyData: [(Date, NutritionInfo)]
    let goal: Int

    var maxCalories: Int {
        max(dailyData.map { $0.1.calories }.max() ?? goal, goal)
    }

    var body: some View {
        GeometryReader { geo in
            let barWidth = (geo.size.width - CGFloat(dailyData.count - 1) * 4) / CGFloat(max(dailyData.count, 1))

            ZStack(alignment: .bottom) {
                // Goal line
                HStack {
                    Rectangle()
                        .fill(Theme.tomato.opacity(0.3))
                        .frame(height: 1)
                }

                // Goal indicator
                HStack {
                    Spacer()
                    Text("\(goal) goal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .offset(y: geo.size.height * (1 - CGFloat(goal) / CGFloat(maxCalories)) - 10)

                // Bars
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(Array(dailyData.enumerated()), id: \.offset) { index, data in
                        let ratio = CGFloat(data.1.calories) / CGFloat(maxCalories)
                        let isOverGoal = data.1.calories > goal

                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isOverGoal ? Theme.tomato : Theme.tomato.opacity(0.7))
                                .frame(width: barWidth, height: max(geo.size.height * ratio, 4))

                            Text("\(data.1.calories)")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

struct MacroTrendChart: View {
    let dailyData: [(Date, Int)]
    let goal: Int
    let color: Color

    var maxValue: Int {
        max(dailyData.map { $0.1 }.max() ?? goal, goal)
    }

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(dailyData.enumerated()), id: \.offset) { index, data in
                    let ratio = CGFloat(data.1) / CGFloat(maxValue)
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(height: max(geo.size.height * ratio, 4))
                        Text("\(data.1)")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct WeeklyStatCard: View {
    let title: String
    let value: String
    let goal: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Goal: \(goal)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct InsightCard: View {
    let insight: NutritionInsight

    var severityColor: Color {
        switch insight.severity {
        case .info: return Theme.kaleGreen
        case .warning: return .orange
        case .alert: return Theme.tomato
        }
    }

    var severityIcon: String {
        switch insight.severity {
        case .info: return "lightbulb.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .alert: return "exclamationmark.octagon.fill"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: severityIcon)
                .font(.title3)
                .foregroundStyle(severityColor)

            VStack(alignment: .leading, spacing: 6) {
                Text(insight.message)
                    .font(.subheadline.bold())

                if let suggestion = insight.suggestion {
                    Text(suggestion)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(severityColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct GoalEditorView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Nutrition Goals")
                .font(.title2.bold())

            Text("Goal editing coming soon")
                .foregroundStyle(.secondary)

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}
