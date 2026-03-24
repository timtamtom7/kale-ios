import Foundation
import EventKit
import UIKit
import UserNotifications

// MARK: - Calendar Service

final class CalendarService: ObservableObject {
    static let shared = CalendarService()

    @Published var isAuthorized = false
    @Published var selectedCalendarTitle: String = "Kale Reminders"
    @Published var syncEnabled = false
    @Published var travelDetectionEnabled = false
    @Published var detectedTravelDates: [DateInterval] = []

    private let eventStore = EKEventStore()
    private let calendarIdentifierKey = "kale_calendar_identifier"
    private let reminderEventTitleKey = "kale_reminder_event_title"

    private init() {
        loadSettings()
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run {
                self.isAuthorized = granted
                if granted {
                    self.syncEnabled = true
                    self.saveSettings()
                }
            }
            return granted
        } catch {
            print("Calendar access error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        isAuthorized = status == .fullAccess
    }

    // MARK: - Calendar Management

    private func getOrCreateKaleCalendar() -> EKCalendar? {
        if let identifier = UserDefaults.standard.string(forKey: calendarIdentifierKey),
           let calendar = eventStore.calendar(withIdentifier: identifier) {
            return calendar
        }

        // Find or create "Kale Reminders" calendar
        let calendars = eventStore.calendars(for: .event)
        if let existing = calendars.first(where: { $0.title == selectedCalendarTitle }) {
            UserDefaults.standard.set(existing.calendarIdentifier, forKey: calendarIdentifierKey)
            return existing
        }

        let sources = eventStore.sources
        let defaultSource = sources.first { $0.sourceType == .local } ?? sources.first

        guard let source = defaultSource else { return nil }

        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = selectedCalendarTitle
        newCalendar.cgColor = UIColor.systemGreen.cgColor
        newCalendar.source = source

        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            UserDefaults.standard.set(newCalendar.calendarIdentifier, forKey: calendarIdentifierKey)
            return newCalendar
        } catch {
            print("Calendar creation error: \(error)")
            return nil
        }
    }

    // MARK: - Event Management

    func addVitaminReminderEvent(for vitamin: Vitamin) {
        guard isAuthorized, syncEnabled else { return }
        guard let calendar = getOrCreateKaleCalendar() else { return }

        // Remove existing event for this vitamin
        removeVitaminReminderEvent(for: vitamin)

        let event = EKEvent(eventStore: eventStore)
        event.title = "💊 Take: \(vitamin.name)"
        event.notes = "Dosage: \(vitamin.dosage)\nKale Vitamin Reminder"
        event.isAllDay = false

        // Set reminder time
        let calendar_obj = Calendar.current
        var components = calendar_obj.dateComponents([.year, .month, .day], from: Date())
        components.hour = calendar_obj.component(.hour, from: vitamin.reminderTime)
        components.minute = calendar_obj.component(.minute, from: vitamin.reminderTime)

        if let reminderDate = calendar_obj.date(from: components) {
            event.startDate = reminderDate
            event.endDate = calendar_obj.date(byAdding: .minute, value: 30, to: reminderDate)
        }

        // Make it recurring daily
        let rule = EKRecurrenceRule(
            recurrenceWith: .daily,
            interval: 1,
            end: nil
        )
        event.addRecurrenceRule(rule)

        event.calendar = calendar

        // Alert 0 minutes before (system notification will handle it)
        event.calendar = calendar

        do {
            try eventStore.save(event, span: .futureEvents)
        } catch {
            print("Event save error: \(error)")
        }
    }

    func removeVitaminReminderEvent(for vitamin: Vitamin) {
        guard isAuthorized else { return }

        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(
            withStart: Date(),
            end: Date().addingTimeInterval(365 * 24 * 3600),
            calendars: calendars
        )

        let events = eventStore.events(matching: predicate)
        let matchingEvents = events.filter { $0.title == "💊 Take: \(vitamin.name)" }

        for event in matchingEvents {
            do {
                try eventStore.remove(event, span: .futureEvents)
            } catch {
                print("Event removal error: \(error)")
            }
        }
    }

    func syncAllVitaminReminders() {
        guard isAuthorized, syncEnabled else { return }

        do {
            let vitamins = try DatabaseService.shared.fetchAllVitamins()
            for vitamin in vitamins {
                addVitaminReminderEvent(for: vitamin)
            }
        } catch {
            print("Sync vitamins error: \(error)")
        }
    }

    func disableCalendarSync() {
        syncEnabled = false
        saveSettings()

        // Remove all kale events
        guard isAuthorized else { return }
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(
            withStart: Date(),
            end: Date().addingTimeInterval(365 * 24 * 3600),
            calendars: calendars
        )
        let events = eventStore.events(matching: predicate)
        let kaleEvents = events.filter { $0.title?.hasPrefix("💊 Take:") == true }
        for event in kaleEvents {
            try? eventStore.remove(event, span: .futureEvents)
        }
    }

    // MARK: - Travel Detection

    func detectTravelPeriods(in nextDays: Int = 30) {
        guard isAuthorized, travelDetectionEnabled else { return }

        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: nextDays, to: startDate)!

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)

        var travelPeriods: [DateInterval] = []

        // Look for travel-related keywords in event titles
        let travelKeywords = ["flight", "trip", "travel", "hotel", "airbnb", "airport", "vacation", "conference", "away"]

        for event in events {
            guard let title = event.title?.lowercased() else { continue }
            let isTravel = travelKeywords.contains { title.contains($0) }
            if isTravel {
                guard let start = event.startDate as Date?, let end = event.endDate as Date? else { continue }
                let interval = DateInterval(start: start, end: end)
                travelPeriods.append(interval)
            }
        }

        // Merge overlapping intervals
        detectedTravelDates = mergeDateIntervals(travelPeriods)

        saveTravelPeriods()
    }

    private func mergeDateIntervals(_ intervals: [DateInterval]) -> [DateInterval] {
        guard !intervals.isEmpty else { return [] }

        let sorted = intervals.sorted { $0.start < $1.start }
        var merged: [DateInterval] = [sorted[0]]

        for interval in sorted.dropFirst() {
            if interval.start <= merged.last!.end {
                let newEnd = max(interval.end, merged.last!.end)
                merged[merged.count - 1] = DateInterval(start: merged.last!.start, end: newEnd)
            } else {
                merged.append(interval)
            }
        }

        return merged
    }

    func isDateInTravelPeriod(_ date: Date) -> Bool {
        detectedTravelDates.contains { $0.contains(date) }
    }

    func skipRemindersForTravel() {
        guard isAuthorized else { return }

        for period in detectedTravelDates {
            // Cancel scheduled notifications during travel
            NotificationService.shared.cancelRemindersBetween(start: period.start, end: period.end)
        }
    }

    // MARK: - Settings Persistence

    private func loadSettings() {
        syncEnabled = UserDefaults.standard.bool(forKey: "calendar_sync_enabled")
        travelDetectionEnabled = UserDefaults.standard.bool(forKey: "travel_detection_enabled")
        selectedCalendarTitle = UserDefaults.standard.string(forKey: "calendar_title") ?? "Kale Reminders"

        if let data = UserDefaults.standard.data(forKey: "travel_periods"),
           let periods = try? JSONDecoder().decode([CodableDateInterval].self, from: data) {
            detectedTravelDates = periods.map { DateInterval(start: $0.start, end: $0.end) }
        }
    }

    private func saveSettings() {
        UserDefaults.standard.set(syncEnabled, forKey: "calendar_sync_enabled")
        UserDefaults.standard.set(travelDetectionEnabled, forKey: "travel_detection_enabled")
        UserDefaults.standard.set(selectedCalendarTitle, forKey: "calendar_title")
        saveTravelPeriods()
    }

    private func saveTravelPeriods() {
        let codable = detectedTravelDates.map { CodableDateInterval(start: $0.start, end: $0.end) }
        if let data = try? JSONEncoder().encode(codable) {
            UserDefaults.standard.set(data, forKey: "travel_periods")
        }
    }
}

// MARK: - Codable DateInterval for persistence

private struct CodableDateInterval: Codable {
    let start: Date
    let end: Date
}

// MARK: - NotificationService extension for travel

extension NotificationService {
    func cancelRemindersBetween(start: Date, end: Date) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests.compactMap { request -> String? in
                guard let trigger = request.trigger as? UNCalendarNotificationTrigger,
                      let nextDate = trigger.nextTriggerDate() else { return nil }
                if nextDate >= start && nextDate <= end {
                    return request.identifier
                }
                return nil
            }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
    }
}
