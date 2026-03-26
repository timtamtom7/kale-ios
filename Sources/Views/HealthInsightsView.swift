import SwiftUI

struct HealthInsightsView: View {
    @EnvironmentObject var healthService: HealthInsightsService
    @EnvironmentObject var databaseService: DatabaseService
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var currentReport: MonthlyReport?
    @State private var previousReport: MonthlyReport?
    @State private var correlationInsights: [CorrelationInsight] = []
    @State private var isLoading = true
    @State private var selectedMonth = Date()
    @State private var vitamins: [Vitamin] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundLight.ignoresSafeArea()

                if !subscriptionManager.canAccess(.healthInsights) {
                    lockedView
                } else if isLoading {
                    ProgressView()
                        .tint(.accentGreen)
                } else {
                    insightsScrollView
                }
            }
            .navigationTitle("Health Insights")
            .onAppear {
                loadData()
            }
        }
    }

    private var lockedView: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.accentGreen.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 32))
                    .foregroundColor(.accentGreen.opacity(0.6))
            }

            VStack(spacing: 10) {
                Text("Complete Plan Required")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.textPrimary)

                Text("Health insights, monthly reports,\nand correlation analysis require\nthe Complete plan.")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button {
                // Would open pricing
            } label: {
                Text("Upgrade to Complete")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.accentGreen)
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding()
    }

    private var insightsScrollView: some View {
        ScrollView {
            VStack(spacing: 24) {
                monthSelector

                if let report = currentReport {
                    monthlyReportCard(report)

                    if let prev = previousReport {
                        comparisonCard(current: report, previous: prev)
                    }

                    vitaminBreakdownSection(report)
                }

                correlationSection
            }
            .padding()
        }
    }

    private var monthSelector: some View {
        HStack {
            Button {
                selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                loadData()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.accentGreen)
            }

            Spacer()

            Text(monthYearString)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.textPrimary)

            Spacer()

            Button {
                selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                if selectedMonth <= Date() {
                    loadData()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(selectedMonth >= Date() ? .inactiveEmpty : .accentGreen)
            }
            .disabled(selectedMonth >= Date())
        }
        .padding(.horizontal, 8)
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    private func monthlyReportCard(_ report: MonthlyReport) -> some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Monthly Consistency")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(report.overallConsistency * 100))")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(.accentGreen)
                        Text("%")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.accentGreen)
                    }
                }

                Spacer()

                ConsistencyRing(score: report.overallConsistency, size: 70)
            }

            Divider()

            HStack(spacing: 0) {
                miniStat(value: "\(report.totalDaysTracked)", label: "days tracked", icon: "calendar")
                Spacer()
                miniStat(value: "\(report.currentStreak)", label: "current streak", icon: "flame.fill")
                Spacer()
                miniStat(value: "\(report.bestStreak)", label: "best streak", icon: "trophy.fill")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.surfaceLight)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }

    private func miniStat(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.accentGreen)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.textSecondary)
        }
    }

    private func comparisonCard(current: MonthlyReport, previous: MonthlyReport) -> some View {
        let change = current.overallConsistency - previous.overallConsistency
        let isPositive = change >= 0
        let changeText = isPositive ? "+\(Int(change * 100))%" : "\(Int(change * 100))%"

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill((isPositive ? Color.accentGreen : Color.yellow).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isPositive ? .accentGreen : .yellow)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(isPositive ? "Improvement from last month" : "Slight dip from last month")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textPrimary)

                HStack(spacing: 4) {
                    Text(changeText)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isPositive ? .accentGreen : .yellow)
                    Text("vs \(previous.monthName)")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfaceLight)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
    }

    private func vitaminBreakdownSection(_ report: MonthlyReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vitamin Breakdown")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)

            if report.vitaminBreakdown.isEmpty {
                Text("No vitamins tracked yet")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                ForEach(report.vitaminBreakdown) { vr in
                    VitaminInsightRow(report: vr)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.surfaceLight)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
    }

    private var correlationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)

            if correlationInsights.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 24))
                        .foregroundColor(.inactiveEmpty)
                    Text("Keep tracking to unlock insights")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(correlationInsights) { insight in
                    CorrelationInsightCard(insight: insight)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.surfaceLight)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
    }

    private func loadData() {
        isLoading = true
        do {
            vitamins = try databaseService.fetchAllVitamins()
            currentReport = try healthService.generateMonthlyReport(for: selectedMonth)

            let prevMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
            previousReport = try healthService.generateMonthlyReport(for: prevMonth)

            correlationInsights = try healthService.generateCorrelationInsights(for: vitamins)
        } catch {
            print("Health insights load error: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Vitamin Insight Row

struct VitaminInsightRow: View {
    let report: VitaminReport
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Text(report.vitaminEmoji)
                        .font(.system(size: 20))
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(report.vitaminName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textPrimary)
                        Text("\(report.daysTaken)/\(report.daysExpected) days taken")
                            .font(.system(size: 11))
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    Text("\(Int(report.consistency * 100))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.accentGreen)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(spacing: 8) {
                    Divider()

                    HStack(spacing: 0) {
                        insightMini(value: "\(report.currentStreak)", label: "streak", icon: "flame.fill")
                        Spacer()
                        insightMini(value: "\(report.bestStreak)", label: "best", icon: "trophy.fill")
                        Spacer()
                        let weekdayPct = Int(report.weekdayConsistency * 100)
                        insightMini(value: "\(weekdayPct)%", label: "weekdays", icon: "briefcase")
                        Spacer()
                        let weekendPct = Int(report.weekendConsistency * 100)
                        insightMini(value: "\(weekendPct)%", label: "weekends", icon: "sun.max")
                    }

                    if let weekday = report.mostMissedWeekday {
                        weekdayMissInsight(weekday: weekday)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.backgroundLight)
        )
    }

    private func weekdayMissInsight(weekday: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundColor(.yellow)

            Text("Most missed on \(Self.weekdayName(weekday))")
                .font(.system(size: 12))
                .foregroundColor(.textSecondary)

            Spacer()
        }
    }

    private func insightMini(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.accentGreen.opacity(0.7))
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.textSecondary)
        }
    }

    private static func weekdayName(_ weekday: Int) -> String {
        let names = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        guard weekday >= 1 && weekday <= 7 else { return "" }
        return names[weekday]
    }
}

// MARK: - Correlation Insight Card

struct CorrelationInsightCard: View {
    let insight: CorrelationInsight

    private var iconName: String {
        switch insight.type {
        case .weekdayPattern: return "calendar.badge.exclamationmark"
        case .supplementInteraction: return "capsule.portrait"
        case .timingPattern: return "clock"
        case .streakRisk: return "flame.fill"
        }
    }

    private var iconColor: Color {
        switch insight.type {
        case .weekdayPattern: return .orange
        case .supplementInteraction: return .yellow
        case .timingPattern: return .blue
        case .streakRisk: return .red
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: iconName)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Text(insight.body)
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
                    .lineSpacing(2)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.backgroundLight)
        )
    }
}

#Preview {
    HealthInsightsView()
        .environmentObject(HealthInsightsService.shared)
        .environmentObject(DatabaseService.shared)
        .environmentObject(SubscriptionManager.shared)
}
