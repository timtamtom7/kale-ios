import SwiftUI

struct WeeklyPlanView: View {
    @Binding var weekPlan: WeekPlan
    let recipes: [Meal]
    @Binding var selectedMeal: Meal?
    @Binding var showingRecipePicker: Bool
    @Binding var currentEditingDay: DayPlan?
    @Binding var currentEditingMealType: MealType?

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Week navigation header
            HStack {
                Button {
                    moveWeek(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }
                .buttonStyle(.plain)

                Spacer()

                VStack(spacing: 2) {
                    Text(weekTitle)
                        .font(.title2.bold())
                    Text(dateRangeText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    moveWeek(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Theme.cream)

            // 7-day grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(weekPlan.days) { day in
                        DayColumnView(
                            day: day,
                            isToday: Calendar.current.isDateInToday(day.date),
                            onMealTap: { mealType in
                                currentEditingDay = day
                                currentEditingMealType = mealType
                                showingRecipePicker = true
                            },
                            onMealClear: { mealType in
                                clearMeal(day: day, mealType: mealType)
                            }
                        )
                    }
                }
                .padding()
            }
            .background(Theme.surface)
        }
    }

    private var weekTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: weekPlan.startDate)
    }

    private var dateRangeText: String {
        let start = dateFormatter.string(from: weekPlan.startDate)
        let end = dateFormatter.string(from: weekPlan.days.last?.date ?? weekPlan.startDate)
        return "\(start) - \(end)"
    }

    private func moveWeek(by weeks: Int) {
        let calendar = Calendar.current
        if let newStart = calendar.date(byAdding: .weekOfYear, value: weeks, to: weekPlan.startDate) {
            weekPlan = WeekPlan(startDate: newStart)
        }
    }

    private func clearMeal(day: DayPlan, mealType: MealType) {
        if let dayIndex = weekPlan.days.firstIndex(where: { $0.id == day.id }) {
            weekPlan.days[dayIndex].meals[mealType] = Meal(name: mealType.rawValue, cookTime: 0, servings: 1, tags: [], ingredients: [], nutrition: NutritionInfo(), instructions: [])
        }
    }
}

struct DayColumnView: View {
    let day: DayPlan
    let isToday: Bool
    let onMealTap: (MealType) -> Void
    let onMealClear: (MealType) -> Void

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()

    var body: some View {
        VStack(spacing: 8) {
            // Day header
            VStack(spacing: 4) {
                Text(dayFormatter.string(from: day.date))
                    .font(.caption.bold())
                    .foregroundStyle(isToday ? Theme.kaleGreen : .secondary)
                Text(dateFormatter.string(from: day.date))
                    .font(.title2.bold())
                    .foregroundStyle(isToday ? Theme.kaleGreen : .primary)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isToday ? Theme.kaleGreen.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Meal slots
            ForEach(MealType.allCases, id: \.self) { mealType in
                if let meal = day.meals[mealType] {
                    MealSlotView(
                        mealType: mealType,
                        meal: meal,
                        onTap: { onMealTap(mealType) },
                        onClear: { onMealClear(mealType) }
                    )
                }
            }
        }
        .frame(width: 140)
    }
}

struct MealSlotView: View {
    let mealType: MealType
    let meal: Meal
    let onTap: () -> Void
    let onClear: () -> Void

    @State private var isHovering = false

    private var isAssigned: Bool {
        meal.name != mealType.rawValue || meal.cookTime > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: mealType.icon)
                    .font(.caption2)
                    .foregroundStyle(Theme.kaleGreen)
                Text(mealType.rawValue)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                if isAssigned {
                    Button {
                        onClear()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .opacity(isHovering ? 1 : 0)
                }
            }

            if isAssigned {
                Text(meal.name)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 8))
                    Text("\(meal.cookTime)m")
                        .font(.system(size: 9))
                    Spacer()
                    Text("\(meal.nutrition.calories) cal")
                        .font(.system(size: 9))
                }
                .foregroundStyle(.secondary)
            } else {
                Button {
                    onTap()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.dashed")
                            .font(.caption)
                        Text("Add")
                            .font(.caption)
                    }
                    .foregroundStyle(Theme.kaleGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Theme.kaleGreen.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
