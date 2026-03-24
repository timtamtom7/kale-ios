import Foundation
import WidgetKit

// MARK: - Widget Data Service (Main App Side)

// Shared vitamin data structure for widget communication
struct SharedWidgetVitaminData: Codable {
    let id: Int64
    let name: String
    let emoji: String
    let dosage: String
    let taken: Bool
}

// MARK: - Widget Data Updater

final class WidgetUpdater {
    static let shared = WidgetUpdater()
    static let appGroupID = "group.com.kale.app"

    private init() {}

    func refreshWidget(vitamins: [Vitamin], todayLogs: [DailyLog]) {
        guard let defaults = UserDefaults(suiteName: WidgetUpdater.appGroupID) else { return }

        let widgetData: [SharedWidgetVitaminData] = vitamins.compactMap { v in
            guard let id = v.id else { return nil }
            let log = todayLogs.first { $0.vitaminId == id }
            return SharedWidgetVitaminData(
                id: id,
                name: v.name,
                emoji: v.pillEmoji,
                dosage: v.dosage,
                taken: log?.taken ?? false
            )
        }

        if let data = try? JSONEncoder().encode(widgetData) {
            defaults.set(data, forKey: "widget_vitamins")
        }

        WidgetCenter.shared.reloadAllTimelines()
    }
}
