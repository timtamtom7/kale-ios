import SwiftUI
import AVFoundation

struct SettingsView: View {
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var databaseService: DatabaseService
    @EnvironmentObject var calendarService: CalendarService
    @EnvironmentObject var familyService: FamilyService
    @State private var vitamins: [Vitamin] = []
    @State private var showingDeleteAlert = false
    @State private var vitaminToDelete: Vitamin?
    @State private var showingPricing = false
    @State private var notificationPermissionDenied = false
    @State private var showingFamilyView = false
    @State private var showingCalendarSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundLight.ignoresSafeArea()

                List {
                    // Notifications section
                    Section {
                        if notificationService.isAuthorized {
                            reminderTimeRow
                        } else {
                            notificationDeniedRow
                        }
                    } header: {
                        Text("Notifications")
                            .font(Theme.Typography.subheadline)
                    }

                    // Calendar Integration section
                    Section {
                        calendarSyncRow
                        travelDetectionRow
                    } header: {
                        Text("Calendar Integration")
                            .font(Theme.Typography.subheadline)
                    } footer: {
                        Text("Sync vitamin reminders with Apple Calendar. Travel detection pauses reminders when you're away.")
                            .font(Theme.Typography.xs)
                            .foregroundColor(.textSecondary)
                    }

                    // Family section
                    Section {
                        Button {
                            HapticManager.light()
                            showingFamilyView = true
                        } label: {
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(.accentGreen)
                                    .frame(width: 28)

                                Text("Family Sharing")
                                    .font(Theme.Typography.body)
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                if let count = try? familyService.memberCount() {
                                    Text("\(count) member\(count == 1 ? "" : "s")")
                                        .font(Theme.Typography.sm)
                                        .foregroundColor(.textSecondary)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textSecondary.opacity(0.5))
                            }
                        }
                        .accessibilityLabel("Family sharing")
                        .accessibilityHint("Opens family management")
                    } header: {
                        Text("Family")
                            .font(Theme.Typography.subheadline)
                    } footer: {
                        Text("Track vitamins together. Up to 6 family members. Complete plan required.")
                            .font(Theme.Typography.xs)
                            .foregroundColor(.textSecondary)
                    }

                    // Subscription section
                    Section {
                        Button {
                            HapticManager.light()
                            showingPricing = true
                        } label: {
                            HStack {
                                Image(systemName: "leaf.fill")
                                    .foregroundColor(.accentGreen)
                                    .frame(width: 28)

                                Text("Subscription")
                                    .font(Theme.Typography.body)
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                Text("Free")
                                    .font(Theme.Typography.sm)
                                    .foregroundColor(.textSecondary)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textSecondary.opacity(0.5))
                            }
                        }
                        .accessibilityLabel("Subscription")
                        .accessibilityHint("Opens subscription options")
                    } header: {
                        Text("Plan")
                            .font(Theme.Typography.subheadline)
                    }

                    // Vitamins section
                    Section {
                        ForEach(vitamins) { vitamin in
                            VitaminRow(vitamin: vitamin)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        vitaminToDelete = vitamin
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }

                        if vitamins.isEmpty {
                            Text("No vitamins added")
                                .font(Theme.Typography.body)
                                .foregroundColor(.textSecondary)
                        }
                    } header: {
                        Text("My Vitamins")
                            .font(Theme.Typography.subheadline)
                    }

                    // Data section
                    Section {
                        Button {
                            HapticManager.light()
                            exportData()
                        } label: {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                                .foregroundColor(.textPrimary)
                        }
                        .accessibilityLabel("Export data")

                        Button {
                            HapticManager.light()
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("App Settings", systemImage: "gear")
                                .foregroundColor(.textPrimary)
                        }
                        .accessibilityLabel("App settings")
                    } header: {
                        Text("Data")
                            .font(Theme.Typography.subheadline)
                    }

                    // About section
                    Section {
                        HStack {
                            Text("Version")
                                .font(Theme.Typography.body)
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Text("1.0.0")
                                .font(Theme.Typography.body)
                                .foregroundColor(.textSecondary)
                        }
                    } header: {
                        Text("About")
                            .font(Theme.Typography.subheadline)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .onAppear {
                loadVitamins()
                notificationService.checkAuthorizationStatus()
                calendarService.checkAuthorizationStatus()
            }
            .alert("Delete Vitamin?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let vitamin = vitaminToDelete, let id = vitamin.id {
                        deleteVitamin(id: id)
                    }
                }
            } message: {
                if let vitamin = vitaminToDelete {
                    Text("Are you sure you want to delete \(vitamin.name)?")
                }
            }
            .sheet(isPresented: $showingPricing) {
                PricingView()
            }
            .sheet(isPresented: $showingFamilyView) {
                FamilyManagementView()
            }
        }
    }

    private var reminderTimeRow: some View {
        HStack {
            Image(systemName: "bell.fill")
                .foregroundColor(.accentGreen)
                .frame(width: 28)

            Text("Daily Reminder")
                .font(Theme.Typography.body)
                .foregroundColor(.textPrimary)

            Spacer()

            DatePicker("", selection: $notificationService.reminderTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .colorScheme(.light)
        }
        .accessibilityLabel("Daily reminder time")
    }

    private var notificationDeniedRow: some View {
        Button {
            HapticManager.light()
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack {
                Image(systemName: "bell.slash.fill")
                    .foregroundColor(.accentGreen)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Notifications disabled")
                        .font(Theme.Typography.body)
                        .foregroundColor(.textPrimary)
                    Text("Tap to enable in Settings")
                        .font(Theme.Typography.sm)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary.opacity(0.5))
            }
        }
        .accessibilityLabel("Notifications disabled")
        .accessibilityHint("Opens Settings app to enable notifications")
    }

    private var calendarSyncRow: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(.accentGreen)
                .frame(width: 28)

            Text("Calendar Sync")
                .font(Theme.Typography.body)
                .foregroundColor(.textPrimary)

            Spacer()

            if calendarService.isAuthorized {
                Toggle("", isOn: Binding(
                    get: { calendarService.syncEnabled },
                    set: { newValue in
                        HapticManager.selection()
                        if newValue {
                            calendarService.syncAllVitaminReminders()
                        } else {
                            calendarService.disableCalendarSync()
                        }
                    }
                ))
                .labelsHidden()
                .tint(.accentGreen)
            } else {
                Button("Enable") {
                    HapticManager.medium()
                    Task {
                        _ = await calendarService.requestAccess()
                    }
                }
                .font(Theme.Typography.sm)
                .foregroundColor(.accentGreen)
            }
        }
        .accessibilityLabel("Calendar sync")
    }

    private var travelDetectionRow: some View {
        HStack {
            Image(systemName: "airplane")
                .foregroundColor(.accentGreen)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text("Travel Detection")
                    .font(Theme.Typography.body)
                    .foregroundColor(.textPrimary)
                if !calendarService.travelDetectionEnabled && calendarService.detectedTravelDates.isEmpty {
                    Text("Skip reminders when traveling")
                        .font(Theme.Typography.sm)
                        .foregroundColor(.textSecondary)
                } else if !calendarService.detectedTravelDates.isEmpty {
                    Text("\(calendarService.detectedTravelDates.count) travel period\(calendarService.detectedTravelDates.count == 1 ? "" : "s") detected")
                        .font(Theme.Typography.sm)
                        .foregroundColor(.accentGreen)
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { calendarService.travelDetectionEnabled },
                set: { newValue in
                    HapticManager.selection()
                    calendarService.travelDetectionEnabled = newValue
                    if newValue {
                        calendarService.detectTravelPeriods()
                    }
                    UserDefaults.standard.set(newValue, forKey: "travel_detection_enabled")
                }
            ))
            .labelsHidden()
            .tint(.accentGreen)
            .disabled(!calendarService.isAuthorized)
        }
        .accessibilityLabel("Travel detection")
    }

    private func loadVitamins() {
        do {
            vitamins = try databaseService.fetchAllVitamins()
        } catch {
            print("Load vitamins error: \(error)")
        }
    }

    private func deleteVitamin(id: Int64) {
        do {
            try databaseService.deleteVitamin(id: id)
            HapticManager.success()
            loadVitamins()
        } catch {
            HapticManager.error()
            print("Delete error: \(error)")
        }
    }

    private func exportData() {
        let vitaminList = vitamins.map { "\($0.pillEmoji) \($0.name) - \($0.dosage)" }.joined(separator: "\n")
        let activityVC = UIActivityViewController(activityItems: ["My Vitamins (Kale):\n\(vitaminList)"], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct VitaminRow: View {
    let vitamin: Vitamin

    var body: some View {
        HStack(spacing: 12) {
            Text(vitamin.pillEmoji)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 2) {
                Text(vitamin.name)
                    .font(Theme.Typography.bodyMedium)
                    .foregroundColor(.textPrimary)
                Text(vitamin.dosage)
                    .font(Theme.Typography.sm)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityLabel("\(vitamin.pillEmoji) \(vitamin.name), \(vitamin.dosage)")
    }
}

#Preview {
    SettingsView()
        .environmentObject(DatabaseService.shared)
        .environmentObject(NotificationService.shared)
        .environmentObject(CalendarService.shared)
        .environmentObject(FamilyService.shared)
}
