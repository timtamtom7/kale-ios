import Foundation

// R11: AI Supplement Insights for Kale
// Interaction detection, timing optimization, side effect correlation
actor AISupplementInsights {
    static let shared = AISupplementInsights()

    private init() {}

    // MARK: - Known Interactions

    struct SupplementInteraction: Identifiable {
        let id = UUID()
        let supplementA: String
        let supplementB: String
        let effect: String
        let recommendation: String
    }

    /// Common supplement interactions
    static let knownInteractions: [SupplementInteraction] = [
        SupplementInteraction(supplementA: "Vitamin D", supplementB: "Vitamin K", effect: "Increased absorption — Vitamin K helps transport calcium", recommendation: "Take together for bone health"),
        SupplementInteraction(supplementA: "Iron", supplementB: "Vitamin C", effect: "Vitamin C enhances non-heme iron absorption", recommendation: "Take iron with orange juice or Vitamin C"),
        SupplementInteraction(supplementA: "Calcium", supplementB: "Iron", effect: "Calcium inhibits iron absorption", recommendation: "Take at least 2 hours apart"),
        SupplementInteraction(supplementA: "Zinc", supplementB: "Copper", effect: "Zinc can deplete copper over time", recommendation: "Consider taking copper if on zinc long-term"),
        SupplementInteraction(supplementA: "Vitamin E", supplementB: "Vitamin K", effect: "High-dose Vitamin E may interfere with Vitamin K", recommendation: "Monitor if taking both"),
        SupplementInteraction(supplementA: "Magnesium", supplementB: "Calcium", effect: "Competition for absorption", recommendation: "Take at different times for optimal absorption"),
        SupplementInteraction(supplementA: "Fish Oil", supplementB: "Vitamin D", effect: "Synergistic for heart and bone health", recommendation: "Great combination!"),
        SupplementInteraction(supplementA: "B12", supplementB: "Folate", effect: "Work together in cell division", recommendation: "Good to pair for energy support")
    ]

    /// Check for interactions between user's supplements
    func detectInteractions(userSupplements: [String]) -> [SupplementInteraction] {
        var detected: [SupplementInteraction] = []

        let lowercased = Set(userSupplements.map { $0.lowercased() })

        for interaction in Self.knownInteractions {
            let aMatch = lowercased.contains(where: { $0.contains(interaction.supplementA.lowercased()) || interaction.supplementA.lowercased().contains($0) })
            let bMatch = lowercased.contains(where: { $0.contains(interaction.supplementB.lowercased()) || interaction.supplementB.lowercased().contains($0) })

            if aMatch && bMatch {
                detected.append(interaction)
            }
        }

        return detected
    }

    // MARK: - Timing Optimization

    struct TimingTip: Identifiable {
        let id = UUID()
        let supplement: String
        let tip: String
        let reason: String
    }

    /// Optimal timing suggestions
    func suggestTiming(for supplements: [String]) -> [TimingTip] {
        var tips: [TimingTip] = []

        let timingRules: [String: (tip: String, reason: String)] = [
            "iron": ("Morning on empty stomach", "Better absorbed without food competition"),
            "vitamin d": ("Morning with fatty meal", "Fat-soluble, needs dietary fat for absorption"),
            "magnesium": ("Evening or before bed", "May promote relaxation and sleep"),
            "calcium": ("With food, split doses", "Better tolerated with food; split if >500mg"),
            "zinc": ("Morning or afternoon", "May interfere with sleep if taken too late"),
            "b12": ("Morning", "Energy-supporting; taking at night may affect sleep"),
            "vitamin c": ("Any time with food", "Water-soluble; no specific timing needed"),
            "probiotic": ("Morning on empty stomach", "Stomach acid is lowest, helps bacteria survive"),
            "omega-3": ("With fatty meal", "Better absorption with dietary fat"),
            "vitamin k": ("With fatty meal if D is present", "Fat-soluble, pairs well with Vitamin D")
        ]

        for supplement in supplements {
            let lowercased = supplement.lowercased()
            for (key, value) in timingRules {
                if lowercased.contains(key) {
                    tips.append(TimingTip(
                        supplement: supplement,
                        tip: value.tip,
                        reason: value.reason
                    ))
                    break
                }
            }
        }

        return tips
    }

    // MARK: - Side Effect Correlation

    struct SideEffectLog: Identifiable, Codable {
        let id: UUID
        let supplementName: String
        let date: Date
        let sideEffect: String
        let severity: Int // 1-5
    }

    func logSideEffect(_ log: SideEffectLog) {
        // Store in UserDefaults for now
        var logs = loadSideEffectLogs()
        logs.append(log)
        saveSideEffectLogs(logs)
    }

    func analyzeSideEffects(for supplement: String, logs: [SideEffectLog]) -> [String] {
        let relevantLogs = logs.filter {
            $0.supplementName.lowercased() == supplement.lowercased()
        }

        guard !relevantLogs.isEmpty else { return [] }

        let avgSeverity = Double(relevantLogs.map { $0.severity }.reduce(0, +)) / Double(relevantLogs.count)

        var recommendations: [String] = []

        if avgSeverity > 3 {
            recommendations.append("Consider reducing dosage or consulting a healthcare provider")
        }

        let commonEffects = relevantLogs.map { $0.sideEffect }
        let mostCommon = mostFrequent(in: commonEffects)

        if mostCommon == "upset stomach" {
            recommendations.append("Try taking with food to reduce stomach upset")
        } else if mostCommon == "headache" {
            recommendations.append("Stay hydrated; consider if dosage is too high")
        } else if mostCommon == "insomnia" {
            recommendations.append("Try taking earlier in the day")
        }

        return recommendations
    }

    private func loadSideEffectLogs() -> [SideEffectLog] {
        guard let data = UserDefaults.standard.data(forKey: "sideEffectLogs"),
              let logs = try? JSONDecoder().decode([SideEffectLog].self, from: data) else {
            return []
        }
        return logs
    }

    private func saveSideEffectLogs(_ logs: [SideEffectLog]) {
        if let data = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(data, forKey: "sideEffectLogs")
        }
    }

    private func mostFrequent(in strings: [String]) -> String {
        let counts = strings.reduce(into: [:]) { counts, string in counts[string, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key ?? strings.first ?? ""
    }
}
