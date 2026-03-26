import Foundation

// MARK: - Health Insights Errors

enum HealthInsightsError: Error {
    case dateComputationFailed
    case insufficientData
}

// MARK: - Health Insight Models

struct MonthlyReport: Identifiable, Codable {
    let id: UUID
    let month: Int
    let year: Int
    let overallConsistency: Double
    let totalDaysTracked: Int
    let totalVitaminsTaken: Int
    let bestStreak: Int
    let currentStreak: Int
    let comparisonToPreviousMonth: Double  // percentage point change
    let vitaminBreakdown: [VitaminReport]
    let generatedAt: Date

    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard let date = Calendar.current.date(from: components) else { return "" }
        return formatter.string(from: date)
    }
}

struct VitaminReport: Identifiable, Codable {
    let id: UUID
    let vitaminName: String
    let vitaminEmoji: String
    let consistency: Double
    let daysTaken: Int
    let daysExpected: Int
    let currentStreak: Int
    let bestStreak: Int
    let weekdayConsistency: Double   // Mon-Fri average
    let weekendConsistency: Double   // Sat-Sun average
    let weekdayMissRate: Double      // How often missed on weekdays
    let weekendMissRate: Double      // How often missed on weekends
    let mostMissedWeekday: Int?       // 1=Sun, 7=Sat
}

struct CorrelationInsight: Identifiable, Codable {
    let id: UUID
    let type: InsightType
    let title: String
    let body: String
    let vitaminName: String?
    let confidence: Double  // 0-1
    let priority: Int      // lower = more important

    enum InsightType: String, Codable {
        case weekdayPattern
        case supplementInteraction
        case timingPattern
        case streakRisk
    }
}

struct SupplementConflict: Identifiable {
    let id: String
    let vitamin1: String
    let vitamin2: String
    let explanation: String
    let severity: ConflictSeverity

    enum ConflictSeverity {
        case warning   // take separately
        case critical  // don't take together
    }

    static let knownConflicts: [SupplementConflict] = [
        SupplementConflict(
            id: "calcium_iron",
            vitamin1: "Calcium",
            vitamin2: "Iron",
            explanation: "Calcium blocks iron absorption. Take at least 2 hours apart.",
            severity: .warning
        ),
        SupplementConflict(
            id: "iron_zinc",
            vitamin1: "Zinc",
            vitamin2: "Iron",
            explanation: "Zinc and iron compete for absorption. Space them 2+ hours apart.",
            severity: .warning
        ),
        SupplementConflict(
            id: "calcium_zinc",
            vitamin1: "Calcium",
            vitamin2: "Zinc",
            explanation: "Calcium can reduce zinc absorption. Take separately for best results.",
            severity: .warning
        ),
        SupplementConflict(
            id: "magnesium_calcium",
            vitamin1: "Calcium",
            vitamin2: "Magnesium",
            explanation: "High-dose calcium and magnesium compete. Consider alternating times of day.",
            severity: .warning
        ),
    ]
}

// MARK: - Health Insights Service

final class HealthInsightsService: ObservableObject {
    static let shared = HealthInsightsService()

    private let databaseService = DatabaseService.shared

    private init() {}

    // MARK: - Monthly Report Generation

    func generateMonthlyReport(for date: Date = Date()) throws -> MonthlyReport {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)

        let vitamins = try databaseService.fetchAllVitamins()
        guard !vitamins.isEmpty else {
            return MonthlyReport(
                id: UUID(),
                month: month,
                year: year,
                overallConsistency: 0,
                totalDaysTracked: 0,
                totalVitaminsTaken: 0,
                bestStreak: 0,
                currentStreak: 0,
                comparisonToPreviousMonth: 0,
                vitaminBreakdown: [],
                generatedAt: Date()
            )
        }

        let (startOfMonth, daysInMonth) = Self.monthBounds(for: date, calendar: calendar)
        let today = calendar.startOfDay(for: Date())

        // Previous month for comparison
        guard let prevMonthDate = calendar.date(byAdding: .month, value: -1, to: date) else {
            throw HealthInsightsError.dateComputationFailed
        }
        let prevConsistency = try databaseService.getConsistencyScore(forMonth: prevMonthDate)
        // currentConsistency is computed below as overallConsistency

        let logs = try databaseService.fetchLogs(forMonth: date)

        var totalExpected = 0
        var totalTaken = 0
        var bestStreak = 0
        var currentStreak = 0
        var vitaminReports: [VitaminReport] = []

        for vitamin in vitamins {
            guard let vid = vitamin.id else { continue }
            let history = try databaseService.getVitaminHistory(vitaminId: vid)

            var vitaminTaken = 0
            var vitaminExpected = 0
            var weekdayTaken = 0
            var weekdayExpected = 0
            var weekendTaken = 0
            var weekendExpected = 0
            var weekdayMisses = 0
            var weekendMisses = 0
            var weekdayCounts = [Int: Int]()  // weekday -> miss count
            // Note: weekendCounts was unused and removed — tracking is via weekdayCounts only

            for dayOffset in 0..<daysInMonth {
                guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: startOfMonth) else { break }
                if dayDate > today { break }

                let weekday = calendar.component(.weekday, from: dayDate)
                let isWeekend = weekday == 1 || weekday == 7  // Sun or Sat

                vitaminExpected += 1
                if isWeekend {
                    weekendExpected += 1
                } else {
                    weekdayExpected += 1
                }

                let key = Self.dateKey(dayDate)
                let dayLogs = logs[key] ?? []
                let taken = dayLogs.contains { $0.vitaminId == vid && $0.taken }

                if taken {
                    vitaminTaken += 1
                    totalTaken += 1
                    if isWeekend {
                        weekendTaken += 1
                    } else {
                        weekdayTaken += 1
                    }
                } else {
                    if isWeekend {
                        weekendMisses += 1
                        weekdayCounts[weekday, default: 0] += 1
                    } else {
                        weekdayMisses += 1
                        weekdayCounts[weekday, default: 0] += 1
                    }
                }
            }

            totalExpected += vitaminExpected

            let vitaminConsistency = vitaminExpected > 0 ? Double(vitaminTaken) / Double(vitaminExpected) : 0
            let weekdayConsistency = weekdayExpected > 0 ? Double(weekdayTaken) / Double(weekdayExpected) : 0
            let weekendConsistency = weekendExpected > 0 ? Double(weekendTaken) / Double(weekendExpected) : 0
            let weekdayMissRate = weekdayExpected > 0 ? Double(weekdayMisses) / Double(weekdayExpected) : 0
            let weekendMissRate = weekendExpected > 0 ? Double(weekendMisses) / Double(weekendExpected) : 0

            // Find most missed weekday
            var mostMissedWeekday: Int? = nil
            var maxMisses = 0
            for (day, misses) in weekdayCounts {
                if misses > maxMisses {
                    maxMisses = misses
                    mostMissedWeekday = day
                }
            }

            bestStreak = max(bestStreak, history.currentStreak)
            currentStreak = max(currentStreak, history.currentStreak)

            vitaminReports.append(VitaminReport(
                id: UUID(),
                vitaminName: vitamin.name,
                vitaminEmoji: vitamin.pillEmoji,
                consistency: vitaminConsistency,
                daysTaken: vitaminTaken,
                daysExpected: vitaminExpected,
                currentStreak: history.currentStreak,
                bestStreak: history.currentStreak,
                weekdayConsistency: weekdayConsistency,
                weekendConsistency: weekendConsistency,
                weekdayMissRate: weekdayMissRate,
                weekendMissRate: weekendMissRate,
                mostMissedWeekday: mostMissedWeekday
            ))
        }

        let overallConsistency = totalExpected > 0 ? Double(totalTaken) / Double(totalExpected) : 0
        let comparison = overallConsistency - prevConsistency

        return MonthlyReport(
            id: UUID(),
            month: month,
            year: year,
            overallConsistency: overallConsistency,
            totalDaysTracked: min(daysInMonth, calendar.component(.day, from: today)),
            totalVitaminsTaken: totalTaken,
            bestStreak: bestStreak,
            currentStreak: currentStreak,
            comparisonToPreviousMonth: comparison,
            vitaminBreakdown: vitaminReports,
            generatedAt: Date()
        )
    }

    // MARK: - Correlation Insights

    func generateCorrelationInsights(for vitamins: [Vitamin], months: Int = 2) throws -> [CorrelationInsight] {
        var insights: [CorrelationInsight] = []

        for vitamin in vitamins {
            guard let vid = vitamin.id else { continue }
            let _ = try databaseService.getVitaminHistory(vitaminId: vid) // Validates vitamin exists

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            var weekdayMissRate: Double = 0
            var weekendMissRate: Double = 0
            var weekdayDays: Double = 0
            var weekendDays: Double = 0

            for monthOffset in 0..<months {
                guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: today) else { continue }
                let (startOfMonth, daysInMonth) = Self.monthBounds(for: monthDate, calendar: calendar)
                let logs = try databaseService.fetchLogs(forMonth: monthDate)

                for dayOffset in 0..<daysInMonth {
                    guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: startOfMonth) else { break }
                    if dayDate > today { break }

                    let weekday = calendar.component(.weekday, from: dayDate)
                    let isWeekend = weekday == 1 || weekday == 7

                    let key = Self.dateKey(dayDate)
                    let dayLogs = logs[key] ?? []
                    let taken = dayLogs.contains { $0.vitaminId == vid && $0.taken }

                    if isWeekend {
                        weekendDays += 1
                        if !taken { weekendMissRate += 1 }
                    } else {
                        weekdayDays += 1
                        if !taken { weekdayMissRate += 1 }
                    }
                }
            }

            weekdayMissRate = weekdayDays > 0 ? weekdayMissRate / weekdayDays : 0
            weekendMissRate = weekendDays > 0 ? weekendMissRate / weekendDays : 0

            // Weekend pattern insight
            if weekendDays > 7 && weekdayDays > 7 {
                let difference = weekendMissRate - weekdayMissRate
                if difference > 0.15 {
                    insights.append(CorrelationInsight(
                        id: UUID(),
                        type: .weekdayPattern,
                        title: "Weekend pattern detected",
                        body: "You're \(Int(abs(difference) * 100))% more likely to forget \(vitamin.name) on weekends.",
                        vitaminName: vitamin.name,
                        confidence: min(abs(difference) * 2, 1.0),
                        priority: difference > 0.3 ? 1 : 2
                    ))
                } else if difference < -0.15 {
                    insights.append(CorrelationInsight(
                        id: UUID(),
                        type: .weekdayPattern,
                        title: "Weekday pattern detected",
                        body: "You tend to forget \(vitamin.name) more during the week.",
                        vitaminName: vitamin.name,
                        confidence: min(abs(difference) * 2, 1.0),
                        priority: 3
                    ))
                }
            }
        }

        // Supplement interaction insights
        let interactionInsights = generateInteractionInsights(for: vitamins)
        insights.append(contentsOf: interactionInsights)

        return insights.sorted { $0.priority < $1.priority }
    }

    // MARK: - Supplement Interaction Detection

    func generateInteractionInsights(for vitamins: [Vitamin]) -> [CorrelationInsight] {
        var insights: [CorrelationInsight] = []
        let vitaminNamesLower = vitamins.map { $0.name.lowercased() }

        for conflict in SupplementConflict.knownConflicts {
            let v1Lower = conflict.vitamin1.lowercased()
            let v2Lower = conflict.vitamin2.lowercased()

            let hasV1 = vitaminNamesLower.contains { $0.contains(v1Lower) || v1Lower.contains($0) }
            let hasV2 = vitaminNamesLower.contains { $0.contains(v2Lower) || v2Lower.contains($0) }

            if hasV1 && hasV2 {
                insights.append(CorrelationInsight(
                    id: UUID(),
                    type: .supplementInteraction,
                    title: "\(conflict.vitamin1) + \(conflict.vitamin2)",
                    body: conflict.explanation,
                    vitaminName: nil,
                    confidence: 0.9,
                    priority: 1
                ))
            }
        }

        // Check for synergistic combinations
        let synergies: [(String, String, String)] = [
            ("Vitamin D", "Magnesium", "Magnesium improves Vitamin D absorption. Great pairing!"),
            ("Vitamin D", "Vitamin K", "Vitamin K2 pairs well with Vitamin D for bone health."),
            ("Vitamin C", "Iron", "Vitamin C enhances iron absorption. Perfect combo!"),
            ("Omega-3", "Vitamin D", "Fat-soluble vitamins absorb better together."),
        ]

        for (v1, v2, msg) in synergies {
            let hasV1 = vitaminNamesLower.contains { $0.contains(v1.lowercased()) || v1.lowercased().contains($0) }
            let hasV2 = vitaminNamesLower.contains { $0.contains(v2.lowercased()) || v2.lowercased().contains($0) }

            if hasV1 && hasV2 {
                insights.append(CorrelationInsight(
                    id: UUID(),
                    type: .supplementInteraction,
                    title: "Synergy: \(v1) + \(v2)",
                    body: msg,
                    vitaminName: nil,
                    confidence: 0.8,
                    priority: 3
                ))
            }
        }

        return insights
    }

    // MARK: - Helpers

    private static func monthBounds(for date: Date, calendar: Calendar) -> (Date, Int) {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let startOfMonth = calendar.date(from: components),
              let daysRange = calendar.range(of: .day, in: .month, for: date) else {
            // Fallback: return today as start with 30 days
            let today = calendar.startOfDay(for: date)
            return (today, 30)
        }
        return (startOfMonth, daysRange.count)
    }

    private static func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
