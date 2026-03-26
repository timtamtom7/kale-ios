import SwiftUI

struct VitaminHistoryView: View {
    let vitamin: Vitamin
    @EnvironmentObject var databaseService: DatabaseService
    @Environment(\.dismiss) var dismiss
    @State private var history: VitaminHistory?
    @State private var last30DaysLogs: [DailyLog] = []
    @State private var isLoading = true
    @State private var showingStockEditor = false
    @State private var stockText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundLight.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(.accentGreen)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            headerCard
                            statsGrid
                            stockCard
                            historyChart
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(vitamin.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.accentGreen)
                }
            }
            .sheet(isPresented: $showingStockEditor) {
                stockEditorSheet
            }
            .onAppear {
                loadHistory()
            }
        }
    }

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentGreen.opacity(0.1))
                    .frame(width: 60, height: 60)
                Text(vitamin.pillEmoji)
                    .font(.system(size: 28))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(vitamin.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text(vitamin.dosage)
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                if let last = history?.lastTakenDate {
                    Text("Last taken: \(lastTakenString(last))")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                }
                if let hist = history {
                    let taken = Int(hist.consistency30Days * 30)
                    Text("\(taken)/30 days this month")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.accentGreen)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfaceLight)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }

    private var statsGrid: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "30-Day Rate",
                value: "\(Int((history?.consistency30Days ?? 0) * 100))%",
                icon: "chart.bar.fill",
                color: .accentGreen
            )
            StatCard(
                title: "Total Days",
                value: "\(history?.totalDaysTaken ?? 0)",
                icon: "calendar",
                color: .accentWarm
            )
            StatCard(
                title: "Current Streak",
                value: "\(history?.currentStreak ?? 0)",
                icon: "flame.fill",
                color: streakColor
            )
            StatCard(
                title: "Stock Left",
                value: stockValue,
                icon: "pills.fill",
                color: stockColor
            )
        }
    }

    private var streakColor: Color {
        let streak = history?.currentStreak ?? 0
        if streak >= 7 { return .accentGreen }
        if streak >= 3 { return .orange }
        return .textSecondary
    }

    private var stockValue: String {
        if let stock = vitamin.stockCount {
            return "\(stock)"
        }
        return "—"
    }

    private var stockColor: Color {
        guard let stock = vitamin.stockCount else { return .textSecondary }
        let days = stock / max(vitamin.dailyDose, 1)
        if days <= 3 { return .red }
        if days <= 7 { return .orange }
        return .accentGreen
    }

    private var stockCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stock Level")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                    if let stock = vitamin.stockCount {
                        let days = stock / max(vitamin.dailyDose, 1)
                        Text("\(days) days remaining (\(stock) capsules)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(stockColor)
                    } else {
                        Text("Not tracking stock")
                            .font(.system(size: 15))
                            .foregroundColor(.textSecondary)
                    }
                }
                Spacer()
                Button {
                    stockText = vitamin.stockCount.map { "\($0)" } ?? ""
                    showingStockEditor = true
                } label: {
                    Text("Update")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.accentGreen)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentGreen.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            if let stock = vitamin.stockCount {
                GeometryReader { geo in
                    let maxStock = max(stock * 2, 30)
                    let fillRatio = min(CGFloat(stock) / CGFloat(maxStock), 1.0)
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.inactiveEmpty.opacity(0.3))
                            .frame(height: 8)
                        Capsule()
                            .fill(stockColor)
                            .frame(width: geo.size.width * fillRatio, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfaceLight)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }

    private var historyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 30 Days")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textSecondary)

            if last30DaysLogs.isEmpty {
                Text("No history data yet")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // Simple dot-grid chart: 6 columns (weeks), 5 rows (days)
                let dayDots = buildDayDots()
                VStack(alignment: .leading, spacing: 6) {
                    ForEach((0..<5).reversed(), id: \.self) { row in
                        HStack(spacing: 4) {
                            ForEach((0..<6), id: \.self) { col in
                                let index = row * 6 + col
                                if index < dayDots.count {
                                    Circle()
                                        .fill(dayDots[index].color)
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Text(dayDots[index].label)
                                                .font(.system(size: 9, weight: .medium))
                                                .foregroundColor(dayDots[index].textColor)
                                        )
                                }
                            }
                        }
                    }
                }

                HStack(spacing: 16) {
                    LegendDot(color: .accentGreen, label: "Taken")
                    LegendDot(color: .inactiveEmpty.opacity(0.4), label: "Missed")
                    LegendDot(color: .clear, label: "Future")
                }
                .font(.system(size: 11))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfaceLight)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }

    private struct DayDot {
        let color: Color
        let label: String
        let textColor: Color
    }

    private func buildDayDots() -> [DayDot] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var dots: [DayDot] = []

        for offset in (0..<30).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
                continue
            }
            let log = last30DaysLogs.first { calendar.isDate($0.date, inSameDayAs: date) }
            let isTaken = log?.taken ?? false

            let formatter = DateFormatter()
            formatter.dateFormat = "d"
            let label = formatter.string(from: date)

            dots.append(DayDot(
                color: isTaken ? .accentGreen : Color.inactiveEmpty.opacity(0.35),
                label: label,
                textColor: isTaken ? .white : .textSecondary
            ))
        }
        return dots
    }

    private var stockEditorSheet: some View {
        NavigationStack {
            ZStack {
                Color.backgroundLight.ignoresSafeArea()
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Capsules remaining")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textSecondary)
                        TextField("e.g. 60", text: $stockText)
                            .font(.system(size: 17))
                            .keyboardType(.numberPad)
                            .padding(12)
                            .background(Color.surfaceLight)
                            .cornerRadius(12)
                        Text("Enter how many capsules you currently have")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }

                    Button {
                        if let count = Int(stockText) {
                            try? databaseService.updateStock(for: vitamin, count: count)
                            showingStockEditor = false
                            loadHistory()
                        }
                    } label: {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(Int(stockText) == nil)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Update Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showingStockEditor = false }
                        .foregroundColor(.accentGreen)
                }
            }
        }
        .presentationDetents([.height(280)])
    }

    private func loadHistory() {
        isLoading = true
        do {
            guard let vid = vitamin.id else { return }
            history = try databaseService.getVitaminHistory(vitaminId: vid)

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) ?? calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()

            let logs = try databaseService.fetchLogs(forMonth: today)
            var allLogs: [DailyLog] = []
            for (_, dayLogs) in logs {
                allLogs.append(contentsOf: dayLogs.filter { $0.vitaminId == vid && $0.date >= thirtyDaysAgo })
            }
            last30DaysLogs = allLogs
        } catch {
            print("History load error: \(error)")
        }
        isLoading = false
    }

    private func lastTakenString(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.surfaceLight)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
    }
}

struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(Color.inactiveEmpty.opacity(0.3), lineWidth: color == .clear ? 1 : 0)
                )
            Text(label)
                .foregroundColor(.textSecondary)
        }
    }
}
