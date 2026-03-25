import Foundation
import CoreLocation
import UserNotifications

// R11: Smart Reminders for Kale
// Contextual reminders, location-based, adaptive frequency
@MainActor
final class SmartReminderService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = SmartReminderService()

    @Published var isLocationEnabled = false
    @Published var reminderSchedules: [ReminderSchedule] = []

    struct ReminderSchedule: Identifiable, Codable {
        let id: UUID
        let supplementName: String
        let reminderTime: Date
        let reminderType: ReminderType
        var isEnabled: Bool
        var lastTriggered: Date?

        enum ReminderType: String, Codable {
            case timeBased
            case mealBased // breakfast, lunch, dinner
            case locationBased
            case adaptive
        }
    }

    private var locationManager: CLLocationManager?
    private var registeredLocations: [CLRegion] = []

    override private init() {
        super.init()
        loadSchedules()
    }

    // MARK: - Meal-Based Reminders

    func scheduleMealBasedReminder(supplementName: String, mealTime: MealTime) {
        let schedule = ReminderSchedule(
            id: UUID(),
            supplementName: supplementName,
            reminderTime: mealTime.time,
            reminderType: .mealBased,
            isEnabled: true,
            lastTriggered: nil
        )
        reminderSchedules.append(schedule)
        scheduleNotification(for: schedule, title: "Take \(supplementName)", body: "It's \(mealTime.rawValue) time!")
        saveSchedules()
    }

    enum MealTime: String, CaseIterable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"

        var time: Date {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            switch self {
            case .breakfast: components.hour = 8; components.minute = 0
            case .lunch: components.hour = 12; components.minute = 0
            case .dinner: components.hour = 18; components.minute = 0
            }
            return calendar.date(from: components) ?? Date()
        }
    }

    // MARK: - Adaptive Reminders

    func scheduleAdaptiveReminder(supplementName: String, baselineFrequency: Int) {
        // More frequent reminders for supplements user often forgets
        let schedule = ReminderSchedule(
            id: UUID(),
            supplementName: supplementName,
            reminderTime: Date(),
            reminderType: .adaptive,
            isEnabled: true,
            lastTriggered: nil
        )
        reminderSchedules.append(schedule)
        saveSchedules()
    }

    func adjustAdaptiveFrequency(for supplementName: String, basedOnMissedDoses: Int) {
        // Increase frequency if often missed
        // Decrease frequency if always taken
        guard let index = reminderSchedules.firstIndex(where: { $0.supplementName == supplementName && $0.reminderType == .adaptive }) else { return }

        var schedule = reminderSchedules[index]

        if basedOnMissedDoses > 3 {
            // Add extra reminder
            schedule = ReminderSchedule(
                id: schedule.id,
                supplementName: schedule.supplementName,
                reminderTime: schedule.reminderTime.addingTimeInterval(3600 * 2), // 2 hours later
                reminderType: .adaptive,
                isEnabled: true,
                lastTriggered: nil
            )
        }

        reminderSchedules[index] = schedule
        saveSchedules()
    }

    // MARK: - Location-Based Reminders

    func requestLocationPermission() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
    }

    func scheduleLocationReminder(supplementName: String, location: CLLocationCoordinate2D, radius: Double = 100) {
        let schedule = ReminderSchedule(
            id: UUID(),
            supplementName: supplementName,
            reminderTime: Date(),
            reminderType: .locationBased,
            isEnabled: true,
            lastTriggered: nil
        )
        reminderSchedules.append(schedule)

        // Register geofence
        let region = CLCircularRegion(
            center: location,
            radius: radius,
            identifier: supplementName
        )
        region.notifyOnEntry = true
        region.notifyOnExit = false

        locationManager?.startMonitoring(for: region)
        registeredLocations.append(region)

        saveSchedules()
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        // Trigger reminder when entering location
        sendNotification(
            title: "Take \(region.identifier)",
            body: "You're at a good location to take your supplement",
            identifier: "loc-\(region.identifier)"
        )
    }

    // MARK: - Skip Notification

    func sendSkipNotification(supplementName: String) {
        // "You skipped yesterday" notification
        sendNotification(
            title: "You skipped \(supplementName) yesterday",
            body: "Tap to log it now",
            identifier: "skip-\(supplementName)"
        )
    }

    // MARK: - Private Helpers

    private func scheduleNotification(for schedule: ReminderSchedule, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.hour, .minute], from: schedule.reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)

        let request = UNNotificationRequest(
            identifier: schedule.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func sendNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Persistence

    private func loadSchedules() {
        guard let data = UserDefaults.standard.data(forKey: "reminderSchedules"),
              let schedules = try? JSONDecoder().decode([ReminderSchedule].self, from: data) else {
            return
        }
        reminderSchedules = schedules
    }

    private func saveSchedules() {
        if let data = try? JSONEncoder().encode(reminderSchedules) {
            UserDefaults.standard.set(data, forKey: "reminderSchedules")
        }
    }
}
