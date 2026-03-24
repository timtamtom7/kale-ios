import SwiftUI
import AVFoundation

struct SettingsView: View {
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var databaseService: DatabaseService
    @State private var vitamins: [Vitamin] = []
    @State private var showingDeleteAlert = false
    @State private var vitaminToDelete: Vitamin?
    @State private var showingPricing = false
    @State private var notificationPermissionDenied = false

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
                            .font(.system(size: 13, weight: .medium))
                    }

                    // Subscription section
                    Section {
                        Button {
                            showingPricing = true
                        } label: {
                            HStack {
                                Image(systemName: "leaf.fill")
                                    .foregroundColor(.accentGreen)
                                    .frame(width: 28)

                                Text("Subscription")
                                    .font(.system(size: 15))
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                Text("Free")
                                    .font(.system(size: 13))
                                    .foregroundColor(.textSecondary)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textSecondary.opacity(0.5))
                            }
                        }
                    } header: {
                        Text("Plan")
                            .font(.system(size: 13, weight: .medium))
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
                                .font(.system(size: 15))
                                .foregroundColor(.textSecondary)
                        }
                    } header: {
                        Text("My Vitamins")
                            .font(.system(size: 13, weight: .medium))
                    }

                    // Data section
                    Section {
                        Button {
                            exportData()
                        } label: {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                                .foregroundColor(.textPrimary)
                        }

                        Button {
                            // Open notification settings
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("App Settings", systemImage: "gear")
                                .foregroundColor(.textPrimary)
                        }
                    } header: {
                        Text("Data")
                            .font(.system(size: 13, weight: .medium))
                    }

                    // About section
                    Section {
                        HStack {
                            Text("Version")
                                .font(.system(size: 15))
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Text("1.0.0")
                                .font(.system(size: 15))
                                .foregroundColor(.textSecondary)
                        }
                    } header: {
                        Text("About")
                            .font(.system(size: 13, weight: .medium))
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .onAppear {
                loadVitamins()
                notificationService.checkAuthorizationStatus()
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
        }
    }

    private var reminderTimeRow: some View {
        HStack {
            Image(systemName: "bell.fill")
                .foregroundColor(.accentGreen)
                .frame(width: 28)

            Text("Daily Reminder")
                .font(.system(size: 15))
                .foregroundColor(.textPrimary)

            Spacer()

            DatePicker("", selection: $notificationService.reminderTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .colorScheme(.light)
        }
    }

    private var notificationDeniedRow: some View {
        Button {
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
                        .font(.system(size: 15))
                        .foregroundColor(.textPrimary)
                    Text("Tap to enable in Settings")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary.opacity(0.5))
            }
        }
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
            loadVitamins()
        } catch {
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
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.textPrimary)
                Text(vitamin.dosage)
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
        .environmentObject(DatabaseService.shared)
        .environmentObject(NotificationService.shared)
}
