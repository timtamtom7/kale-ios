import SwiftUI
import WidgetKit

struct TodayView: View {
    @EnvironmentObject var databaseService: DatabaseService
    @EnvironmentObject var notificationService: NotificationService
    @State private var vitamins: [Vitamin] = []
    @State private var todayLogs: [Int64: Bool] = [:]
    @State private var showingAddVitamin = false
    @State private var showingPricing = false
    @State private var selectedDate = Date()
    @State private var weekDates: [Date] = []
    @State private var selectedVitamin: Vitamin?
    @State private var showingHistory = false
    @State private var lowStockVitamins: [Vitamin] = []
    @State private var showingLowStock = false
    @State private var lowStockDetectionFailed = false
    @State private var activeHint: SupplementInteraction?
    @State private var shownHintIds: Set<String> = []
    @State private var showingFamilyView = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundLight.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        greetingSection

                        if !lowStockVitamins.isEmpty {
                            lowStockSection
                        }

                        vitaminCardsSection
                        weekDotsSection
                    }
                    .padding()

                    // Floating hint toast
                    if let hint = activeHint {
                        VStack {
                            Spacer()
                            HStack {
                                InteractionHintToast(hint: hint.hint) {
                                    activeHint = nil
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                        }
                    }
                }
            }
            .navigationTitle("Kale")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        if !lowStockVitamins.isEmpty {
                            Button {
                                showingLowStock = true
                            } label: {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "bell.badge.fill")
                                        .font(.title2)
                                        .foregroundColor(.orange)
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 2, y: -2)
                                }
                            }
                        }

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

                        Button {
                            showingFamilyView = true
                        } label: {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.accentGreen)
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
            .sheet(isPresented: $showingLowStock) {
                LowStockSheet(vitamins: lowStockVitamins)
            }
            .sheet(isPresented: $showingHistory) {
                if let vitamin = selectedVitamin {
                    VitaminHistoryView(vitamin: vitamin)
                }
            }
            .sheet(isPresented: $showingFamilyView) {
                FamilyManagementView()
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

    @ViewBuilder
    private var lowStockSection: some View {
        if lowStockDetectionFailed {
            LowStockDetectionFailedView {
                lowStockDetectionFailed = false
                loadLowStock()
            }
        } else {
            VStack(spacing: 8) {
                ForEach(lowStockVitamins.prefix(2)) { vitamin in
                    LowStockAlertCard(vitamin: vitamin) {
                        selectedVitamin = vitamin
                        showingLowStock = true
                    }
                }
            }
        }
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
                        onToggle: { toggleVitamin(vitamin) },
                        onTap: {
                            selectedVitamin = vitamin
                            showingHistory = true
                        }
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
        loadLowStock()
    }

    private func loadLowStock() {
        do {
            lowStockVitamins = try databaseService.getLowStockVitamins()
            lowStockDetectionFailed = false
        } catch {
            lowStockDetectionFailed = true
            lowStockVitamins = []
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

            // Update widget
            updateWidgetData()

            // Decrement stock when taken
            if newState && vitamin.stockCount != nil {
                try databaseService.decrementStock(for: vitamin)
                loadData()
            }

            // Show interaction hint when taken
            if newState, let hint = InteractionHintService.getHint(for: vitamin.name), !shownHintIds.contains(hint.id) {
                activeHint = hint
                shownHintIds.insert(hint.id)
            }
        } catch {
            print("Toggle error: \(error)")
        }
    }

    private func updateWidgetData() {
        let todayDate = Calendar.current.startOfDay(for: Date())
        let logs = todayLogs.map { (vid, taken) -> DailyLog in
            DailyLog(id: nil, vitaminId: vid, date: todayDate, taken: taken, takenAt: taken ? Date() : nil)
        }
        WidgetUpdater.shared.refreshWidget(vitamins: vitamins, todayLogs: logs)
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
