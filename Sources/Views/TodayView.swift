import SwiftUI

struct TodayView: View {
    @EnvironmentObject var databaseService: DatabaseService
    @EnvironmentObject var notificationService: NotificationService
    @State private var vitamins: [Vitamin] = []
    @State private var todayLogs: [Int64: Bool] = [:]
    @State private var showingAddVitamin = false
    @State private var showingPricing = false
    @State private var selectedDate = Date()
    @State private var weekDates: [Date] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundLight.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        greetingSection
                        vitaminCardsSection
                        weekDotsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Kale")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showingAddVitamin = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.accentGreen)
                        }

                        Button {
                            showingPricing = true
                        } label: {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddVitamin) {
                AddVitaminView { newVitamin in
                    loadData()
                }
            }
            .sheet(isPresented: $showingPricing) {
                PricingView()
            }
            .onAppear {
                loadData()
                buildWeekDates()
            }
        }
    }

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingText)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.textSecondary)

            if vitamins.isEmpty {
                Text("Add vitamins to get started")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.textSecondary.opacity(0.7))
            } else {
                Text("\(allTakenCount)/\(vitamins.count) taken today")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.textSecondary.opacity(0.7))
            }
        }
        .padding(.top, 8)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning." }
        else if hour < 17 { return "Good afternoon." }
        else { return "Good evening." }
    }

    private var vitaminCardsSection: some View {
        VStack(spacing: 12) {
            if vitamins.isEmpty {
                EmptyVitaminsView {
                    showingAddVitamin = true
                }
                .frame(maxWidth: .infinity)
            } else {
                ForEach(vitamins) { vitamin in
                    VitaminCard(
                        vitamin: vitamin,
                        isTaken: todayLogs[vitamin.id ?? 0] ?? false,
                        onToggle: { toggleVitamin(vitamin) }
                    )
                }
            }
        }
    }

    private var weekDotsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This week")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textSecondary)

            HStack(spacing: 6) {
                ForEach(weekDates, id: \.self) { date in
                    WeekDot(date: date)
                }
            }
        }
        .padding(.top, 4)
    }

    private var allTakenCount: Int {
        todayLogs.filter { $0.value }.count
    }

    private func loadData() {
        do {
            vitamins = try databaseService.fetchAllVitamins()
            let logs = try databaseService.fetchLogs(for: Date())
            todayLogs = Dictionary(uniqueKeysWithValues: logs.map { ($0.vitaminId, $0.taken) })
        } catch {
            print("Load error: \(error)")
        }
    }

    private func buildWeekDates() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        weekDates = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset - daysFromMonday, to: today)
        }
    }

    private func toggleVitamin(_ vitamin: Vitamin) {
        guard let vid = vitamin.id else { return }
        let currentState = todayLogs[vid] ?? false
        let newState = !currentState

        do {
            try databaseService.logTaken(vitaminId: vid, date: Date(), taken: newState)
            todayLogs[vid] = newState
        } catch {
            print("Toggle error: \(error)")
        }
    }
}

struct WeekDot: View {
    let date: Date
    @EnvironmentObject var databaseService: DatabaseService
    @State private var status: DayStatus = .empty

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(dayLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isToday ? .accentGreen : .textSecondary)

            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
        }
        .onAppear {
            loadStatus()
        }
    }

    private var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }

    private var statusColor: Color {
        switch status {
        case .empty, .none: return Color.inactiveEmpty
        case .partial: return Color.yellow
        case .complete: return Color.accentGreen
        }
    }

    private func loadStatus() {
        do {
            status = try databaseService.getDayStatus(on: date)
        } catch {
            status = .empty
        }
    }
}

#Preview {
    TodayView()
        .environmentObject(DatabaseService.shared)
        .environmentObject(NotificationService.shared)
}
