import Foundation
import UserNotifications

final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false
    @Published var reminderTime: Date {
        didSet {
            UserDefaults.standard.set(reminderTime.timeIntervalSince1970, forKey: "reminderTime")
            scheduleMorningNotification()
        }
    }

    private init() {
        let saved = UserDefaults.standard.double(forKey: "reminderTime")
        self.reminderTime = saved > 0 ? Date(timeIntervalSince1970: saved) : Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
        checkAuthorizationStatus()
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    self.scheduleMorningNotification()
                }
            }
        }
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func scheduleMorningNotification() {
        guard isAuthorized else { return }

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["morning_reminder"])

        let vitamins: [Vitamin]
        do {
            vitamins = try DatabaseService.shared.fetchAllVitamins()
        } catch {
            return
        }

        let vitaminNames = vitamins.prefix(3).map { $0.name }.joined(separator: " + ")
        let body = vitamins.isEmpty ? "Time to take your vitamins!" : "Today: \(vitaminNames)"

        let content = UNMutableNotificationContent()
        content.title = "Good morning. 🌿"
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "VITAMIN_REMINDER"

        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        dateComponents.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "morning_reminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)

        // Add notification actions
        let takeAction = UNNotificationAction(identifier: "TAKE_ACTION", title: "Take", options: [.foreground])
        let laterAction = UNNotificationAction(identifier: "LATER_ACTION", title: "Remind me later", options: [])
        let category = UNNotificationCategory(identifier: "VITAMIN_REMINDER", actions: [takeAction, laterAction], intentIdentifiers: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    func markTodayAsTaken() {
        do {
            let vitamins = try DatabaseService.shared.fetchAllVitamins()
            let today = Date()
            for vitamin in vitamins {
                if let vid = vitamin.id {
                    try DatabaseService.shared.logTaken(vitaminId: vid, date: today, taken: true)
                }
            }
        } catch {
            print("Error marking as taken: \(error)")
        }
    }

    func scheduleRemindLater() {
        let content = UNMutableNotificationContent()
        content.title = "Reminder 💊"
        content.body = "Don't forget to take your vitamins!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        let request = UNNotificationRequest(identifier: "remind_later", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleLowStockNotification(for vitamin: Vitamin) {
        guard isAuthorized, let stock = vitamin.stockCount else { return }

        let content = UNMutableNotificationContent()
        content.title = "Low Stock Alert ⚠️"
        content.body = "\(vitamin.name) is running low — only \(stock) capsules left."
        content.sound = .default
        content.categoryIdentifier = "LOW_STOCK"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = "low_stock_\(vitamin.id ?? 0)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
