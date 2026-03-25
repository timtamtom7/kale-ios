import Foundation

/// R7: AI-powered vitamin intelligence for personalized recommendations,
/// deficiency risk detection, and optimal timing.
struct VitaminIntelligence {
    var recommendations: [VitaminRecommendation]
    var deficiencyRisks: [DeficiencyRisk]
    var adherenceScore: Int
    var timingTips: [String]
    var weeklyPattern: [String: Bool]
    var motivationalMessage: String
}

struct VitaminRecommendation: Identifiable {
    let id = UUID()
    let vitamin: String
    let reason: String
    let priority: String // "high", "medium", "low"
}

struct DeficiencyRisk: Identifiable {
    let id = UUID()
    let vitamin: String
    let riskLevel: String // "low", "medium", "high"
    let reason: String
}

final class VitaminIntelligenceService {
    static let shared = VitaminIntelligenceService()

    private init() {}

    // MARK: - R7: Generate Intelligence

    func generateIntelligence(dailyLogs: [DailyLog], vitamins: [Vitamin]) -> VitaminIntelligence {
        let recommendations = generateRecommendations(logs: dailyLogs, vitamins: vitamins)
        let deficiencyRisks = detectDeficiencyRisks(logs: dailyLogs, vitamins: vitamins)
        let adherenceScore = calculateAdherenceScore(logs: dailyLogs)
        let timingTips = generateTimingTips(vitamins: vitamins, logs: dailyLogs)
        let weeklyPattern = computeWeeklyPattern(logs: dailyLogs)
        let motivationalMessage = generateMotivationalMessage(adherence: adherenceScore, risks: deficiencyRisks)

        return VitaminIntelligence(
            recommendations: recommendations,
            deficiencyRisks: deficiencyRisks,
            adherenceScore: adherenceScore,
            timingTips: timingTips,
            weeklyPattern: weeklyPattern,
            motivationalMessage: motivationalMessage
        )
    }

    // MARK: - Recommendations

    private func generateRecommendations(logs: [DailyLog], vitamins: [Vitamin]) -> [VitaminRecommendation] {
        var recs: [VitaminRecommendation] = []
        let recentLogs = logs.prefix(7)

        for vitamin in vitamins {
            let vitaminLogs = recentLogs.filter { $0.vitaminId == vitamin.id }
            let missedDays = 7 - vitaminLogs.filter { $0.taken }.count

            if missedDays >= 3 {
                recs.append(VitaminRecommendation(
                    vitamin: vitamin.name,
                    reason: "You missed \(missedDays) of the last 7 days. Consider setting a reminder.",
                    priority: missedDays >= 5 ? "high" : "medium"
                ))
            }

            // Iron for women of childbearing age
            if vitamin.name.lowercased().contains("iron") {
                recs.append(VitaminRecommendation(
                    vitamin: vitamin.name,
                    reason: "Take Iron with Vitamin C for better absorption. Avoid with calcium.",
                    priority: "low"
                ))
            }

            // Vitamin D with fatty meal
            if vitamin.name.lowercased().contains("vitamin d") {
                recs.append(VitaminRecommendation(
                    vitamin: vitamin.name,
                    reason: "Take Vitamin D with a meal containing fat for 50% better absorption.",
                    priority: "low"
                ))
            }

            // Magnesium for sleep
            if vitamin.name.lowercased().contains("magnesium") {
                recs.append(VitaminRecommendation(
                    vitamin: vitamin.name,
                    reason: "Take magnesium in the evening for better sleep support.",
                    priority: "low"
                ))
            }
        }

        return recs
    }

    // MARK: - Deficiency Risk Detection

    private func detectDeficiencyRisks(logs: [DailyLog], vitamins: [Vitamin]) -> [DeficiencyRisk] {
        var risks: [DeficiencyRisk] = []
        let recent = logs.prefix(14) // last 2 weeks

        for vitamin in vitamins {
            let vitaminLogs = recent.filter { $0.vitaminId == vitamin.id }
            let takenDays = vitaminLogs.filter { $0.taken }.count
            let complianceRate = Double(takenDays) / Double(max(recent.count, 1))

            if complianceRate < 0.3 {
                risks.append(DeficiencyRisk(
                    vitamin: vitamin.name,
                    riskLevel: "high",
                    reason: "You've only taken this \(Int(complianceRate * 100))% of the time in the past 2 weeks."
                ))
            } else if complianceRate < 0.5 {
                risks.append(DeficiencyRisk(
                    vitamin: vitamin.name,
                    riskLevel: "medium",
                    reason: "Missed frequently over the past 2 weeks. Your levels may be dropping."
                ))
            }
        }

        return risks
    }

    // MARK: - Adherence Score

    private func calculateAdherenceScore(logs: [DailyLog]) -> Int {
        guard !logs.isEmpty else { return 0 }
        let recent = logs.prefix(30)
        let totalLogs = recent.count
        let takenLogs = recent.filter { $0.taken }.count
        guard totalLogs > 0 else { return 100 }
        return min(100, Int(Double(takenLogs) / Double(totalLogs) * 100))
    }

    // MARK: - Timing Tips

    private func generateTimingTips(vitamins: [Vitamin], logs: [DailyLog]) -> [String] {
        var tips: [String] = []

        for vitamin in vitamins {
            let name = vitamin.name.lowercased()

            if name.contains("vitamin d") || name.contains("vitamin k") {
                tips.append("💊 \(vitamin.name): Morning with breakfast (fat helps absorption)")
            } else if name.contains("iron") {
                tips.append("💊 \(vitamin.name): Morning on empty stomach, or with orange juice")
            } else if name.contains("magnesium") || name.contains("calcium") {
                tips.append("💊 \(vitamin.name): Evening (better for sleep and relaxation)")
            } else if name.contains("vitamin c") || name.contains("zinc") {
                tips.append("💊 \(vitamin.name): Morning or afternoon (boosts energy)")
            } else if name.contains("vitamin b") || name.contains("b12") {
                tips.append("💊 \(vitamin.name): Morning (B vitamins can interfere with sleep)")
            }
        }

        return tips
    }

    // MARK: - Weekly Pattern

    private func computeWeeklyPattern(logs: [DailyLog]) -> [String: Bool] {
        var pattern: [String: Bool] = [:]
        let calendar = Calendar.current
        let recent = logs.prefix(7)

        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        for (index, dayName) in dayNames.enumerated() {
            let dayIndex = index + 1 // Calendar weekday: 1=Sun
            let dayLogs = recent.filter {
                calendar.component(.weekday, from: $0.date) == dayIndex
            }
            pattern[dayName] = !dayLogs.isEmpty && dayLogs.allSatisfy { $0.taken }
        }

        return pattern
    }

    // MARK: - Motivational Message

    private func generateMotivationalMessage(adherence: Int, risks: [DeficiencyRisk]) -> String {
        if adherence >= 90 {
            return "Outstanding! You're in the top tier of supplement takers. Your body thanks you! 🌟"
        } else if adherence >= 70 {
            return "Great consistency! You're building strong habits. Just a little more to reach excellence!"
        } else if adherence >= 50 {
            return "You're on the right track. A few more days of consistency will make this automatic!"
        } else if !risks.isEmpty {
            return "Focus on \(risks.first?.vitamin ?? "your supplements") today — your health is worth it!"
        } else {
            return "Every vitamin counts! Start with one reminder and build from there."
        }
    }

    // MARK: - Known Interactions

    static let knownInteractions: [(v1: String, v2: String, advice: String, severity: String)] = [
        ("Calcium", "Iron", "Take 2+ hours apart", "warning"),
        ("Calcium", "Zinc", "Take 2+ hours apart", "warning"),
        ("Calcium", "Magnesium", "Take at different times for best absorption", "low"),
        ("Iron", "Vitamin C", "Vitamin C enhances iron absorption — great together!", "positive"),
        ("Vitamin D", "Vitamin K2", "Better together — K2 directs calcium to bones", "positive"),
        ("Vitamin E", "Vitamin K", "High-dose E can interfere with K — consult your doctor", "warning"),
        ("Zinc", "Copper", "Long-term zinc supplementation may deplete copper", "medium"),
        ("Fish Oil", "Vitamin E", "Fish oil may increase need for Vitamin E", "low")
    ]
}
