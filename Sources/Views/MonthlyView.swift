import SwiftUI

struct MonthlyView: View {
    @EnvironmentObject var databaseService: DatabaseService
    @State private var currentMonth = Date()
    @State private var dayStatuses: [String: DayStatus] = [:]
    @State private var selectedDayLogs: [DailyLog] = []
    @State private var selectedDayDate: Date?
    @State private var showingDayDetail = false
    @State private var consistencyScore: Double = 0

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundLight.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        scoreCard
                        monthCalendar
                        dayLabels
                    }
                    .padding()
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        changeMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.accentGreen)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        changeMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.accentGreen)
                    }
                }
            }
            .onAppear {
                loadMonthData()
            }
            .sheet(isPresented: $showingDayDetail) {
                if let date = selectedDayDate {
                    DayDetailView(date: date, logs: selectedDayLogs)
                        .presentationDetents([.height(300)])
                        .presentationDragIndicator(.visible)
                }
            }
        }
    }

    private var scoreCard: some View {
        VStack(spacing: 8) {
            Text("\(Int(consistencyScore * 100))%")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.accentGreen)
            Text("consistency this month")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.surfaceLight)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }

    private var monthCalendar: some View {
        VStack(spacing: 4) {
            Text(monthYearString)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.textPrimary)
                .padding(.bottom, 12)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            status: dayStatuses[dateKey(date)] ?? .empty,
                            isToday: calendar.isDateInToday(date),
                            isFuture: date > Date()
                        )
                        .onTapGesture {
                            if date <= Date() {
                                selectedDayDate = date
                                loadDayLogs(for: date)
                                showingDayDetail = true
                            }
                        }
                    } else {
                        Color.clear
                            .frame(width: 36, height: 36)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.surfaceLight)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }

    private var dayLabels: some View {
        HStack {
            ForEach(["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"], id: \.self) { label in
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var daysInMonth: [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysInMonthRange = calendar.range(of: .day, in: .month, for: currentMonth)!

        let offsetFromMonday = (firstWeekday + 5) % 7
        var days: [Date?] = Array(repeating: nil, count: offsetFromMonday)

        for day in 1...daysInMonthRange.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }

        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    private func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
            loadMonthData()
        }
    }

    private func loadMonthData() {
        do {
            let logs = try databaseService.fetchLogs(forMonth: currentMonth)
            let allVitamins = try databaseService.fetchAllVitamins()

            dayStatuses = [:]
            for (key, dayLogs) in logs {
                let takenCount = dayLogs.filter { $0.taken }.count
                if allVitamins.isEmpty {
                    dayStatuses[key] = .empty
                } else if takenCount == 0 {
                    dayStatuses[key] = .none
                } else if takenCount == allVitamins.count {
                    dayStatuses[key] = .complete
                } else {
                    dayStatuses[key] = .partial
                }
            }

            consistencyScore = try databaseService.getConsistencyScore(forMonth: currentMonth)
        } catch {
            print("Load month error: \(error)")
        }
    }

    private func loadDayLogs(for date: Date) {
        do {
            selectedDayLogs = try databaseService.fetchLogs(for: date)
        } catch {
            selectedDayLogs = []
        }
    }
}

struct DayCell: View {
    let date: Date
    let status: DayStatus
    let isToday: Bool
    let isFuture: Bool

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        ZStack {
            if isToday {
                Circle()
                    .stroke(Color.accentGreen, lineWidth: 2)
                    .frame(width: 32, height: 32)
            }

            Circle()
                .fill(backgroundColor)
                .frame(width: 32, height: 32)

            Text(dayNumber)
                .font(.system(size: 13, weight: isToday ? .semibold : .regular))
                .foregroundColor(textColor)
        }
        .frame(width: 36, height: 36)
    }

    private var backgroundColor: Color {
        if isFuture { return Color.clear }
        switch status {
        case .empty: return Color.clear
        case .none: return Color.inactiveEmpty.opacity(0.3)
        case .partial: return Color.yellow.opacity(0.5)
        case .complete: return Color.accentGreen
        }
    }

    private var textColor: Color {
        if isFuture { return Color.textSecondary.opacity(0.3) }
        if status == .complete { return .white }
        return Color.textPrimary
    }
}

struct DayDetailView: View {
    let date: Date
    let logs: [DailyLog]
    @EnvironmentObject var databaseService: DatabaseService
    @Environment(\.dismiss) var dismiss

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundLight.ignoresSafeArea()

                VStack(spacing: 16) {
                    Text(dateString)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.textSecondary)

                    if logs.isEmpty {
                        Text("No vitamins logged")
                            .font(.system(size: 15))
                            .foregroundColor(.textSecondary)
                            .padding(.top, 20)
                    } else {
                        ForEach(logs, id: \.id) { log in
                            if let vitamin = getVitamin(id: log.vitaminId) {
                                HStack {
                                    Text(vitamin.pillEmoji)
                                        .font(.system(size: 20))
                                    Text(vitamin.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                    Image(systemName: log.taken ? "checkmark.circle.fill" : "xmark.circle")
                                        .foregroundColor(log.taken ? .accentGreen : .textSecondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.surfaceLight)
                                )
                            }
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accentGreen)
                }
            }
        }
    }

    private func getVitamin(id: Int64) -> Vitamin? {
        try? databaseService.fetchAllVitamins().first { $0.id == id }
    }
}

#Preview {
    MonthlyView()
        .environmentObject(DatabaseService.shared)
        .environmentObject(NotificationService.shared)
}
