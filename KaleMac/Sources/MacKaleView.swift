import SwiftUI

struct MacKaleView: View {
    @State private var vitamins: [Vitamin] = []
    @State private var todayLogs: [DailyLog] = []
    @State private var selectedTab = 0
    @State private var showAddVitamin = false

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayMacView(vitamins: vitamins, todayLogs: todayLogs, onTake: takeVitamin)
                .tabItem {
                    Label("Today", systemImage: "checkmark.circle.fill")
                }
                .tag(0)

            HistoryMacView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
                .tag(1)

            SettingsMacView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .tint(Color(hex: "4ade80"))
        .frame(minWidth: 900, minHeight: 700)
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            loadVitamins()
        }
    }

    private func loadVitamins() {
        vitamins = [
            Vitamin(name: "Vitamin D3", dosage: "2000 IU", pillEmoji: "💊", reminderTime: Date()),
            Vitamin(name: "Omega-3", dosage: "1000mg", pillEmoji: "🐟", reminderTime: Date()),
            Vitamin(name: "Magnesium", dosage: "400mg", pillEmoji: "🫙", reminderTime: Date()),
        ]
    }

    private func takeVitamin(_ vitamin: Vitamin) {
        // Mark as taken for today
        let log = DailyLog(vitaminId: vitamin.id ?? 0, date: Date(), takenAt: Date())
        todayLogs.append(log)
    }
}

struct TodayMacView: View {
    let vitamins: [Vitamin]
    let todayLogs: [DailyLog]
    let onTake: (Vitamin) -> Void

    var takenCount: Int { todayLogs.count }
    var totalCount: Int { vitamins.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Today's Vitamins")
                        .font(.largeTitle.bold())

                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Text("\(takenCount)/\(totalCount)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "4ade80"))

                        Text("taken")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 32)

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .controlBackgroundColor))

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "4ade80").gradient)
                            .frame(width: geometry.size.width * CGFloat(takenCount) / CGFloat(max(totalCount, 1)))
                    }
                }
                .frame(height: 12)
                .padding(.horizontal, 40)

                // Vitamin cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(vitamins) { vitamin in
                        VitaminMacCard(
                            vitamin: vitamin,
                            isTaken: todayLogs.contains { $0.vitaminId == vitamin.id },
                            onTake: { onTake(vitamin) }
                        )
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
}

struct VitaminMacCard: View {
    let vitamin: Vitamin
    let isTaken: Bool
    let onTake: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Text(vitamin.pillEmoji)
                .font(.system(size: 40))

            VStack(alignment: .leading, spacing: 4) {
                Text(vitamin.name)
                    .font(.headline)

                Text(vitamin.dosage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                if !isTaken {
                    onTake()
                }
            } label: {
                Image(systemName: isTaken ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28))
                    .foregroundStyle(isTaken ? Color(hex: "4ade80") : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(isTaken)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isTaken ? Color(hex: "4ade80").opacity(0.1) : Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isTaken ? Color(hex: "4ade80").opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

struct HistoryMacView: View {
    var body: some View {
        VStack {
            ContentUnavailableView(
                "No History Yet",
                systemImage: "calendar",
                description: Text("Your vitamin tracking history will appear here.")
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SettingsMacView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Settings")
                .font(.largeTitle.bold())

            VStack(alignment: .leading, spacing: 16) {
                SettingsRow(icon: "bell.fill", title: "Notifications", subtitle: "Daily reminders")
                SettingsRow(icon: "person.2.fill", title: "Family Sharing", subtitle: "Track for family members")
                SettingsRow(icon: "chart.bar.fill", title: "Health Insights", subtitle: "AI-powered recommendations")
                SettingsRow(icon: "square.and.arrow.up", title: "Export Data", subtitle: "Download your tracking history")
            }

            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color(hex: "4ade80"))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
