import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Entry

struct KaleWidgetEntry: TimelineEntry {
    let date: Date
    let vitamins: [WidgetVitamin]
    let takenCount: Int
    let allTaken: Bool
}

struct WidgetVitamin: Identifiable {
    let id: Int64
    let name: String
    let emoji: String
    let dosage: String
    let taken: Bool
}

// MARK: - Widget Provider

struct KaleWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> KaleWidgetEntry {
        KaleWidgetEntry(
            date: Date(),
            vitamins: [
                WidgetVitamin(id: 1, name: "Vitamin D3", emoji: "💊", dosage: "2000 IU", taken: false),
                WidgetVitamin(id: 2, name: "Magnesium", emoji: "🫙", dosage: "400mg", taken: false)
            ],
            takenCount: 0,
            allTaken: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (KaleWidgetEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KaleWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> KaleWidgetEntry {
        let sharedDefaults = UserDefaults(suiteName: "group.com.kale.app")

        if let data = sharedDefaults?.data(forKey: "widget_vitamins"),
           let vitamins = try? JSONDecoder().decode([WidgetVitaminData].self, from: data) {
            let widgetVitamins = vitamins.map { v in
                WidgetVitamin(id: v.id, name: v.name, emoji: v.emoji, dosage: v.dosage, taken: v.taken)
            }
            let takenCount = widgetVitamins.filter { $0.taken }.count
            return KaleWidgetEntry(
                date: Date(),
                vitamins: widgetVitamins,
                takenCount: takenCount,
                allTaken: !widgetVitamins.isEmpty && takenCount == widgetVitamins.count
            )
        }

        return KaleWidgetEntry(
            date: Date(),
            vitamins: [
                WidgetVitamin(id: 1, name: "Vitamin D3", emoji: "💊", dosage: "2000 IU", taken: false),
                WidgetVitamin(id: 2, name: "Magnesium", emoji: "🫙", dosage: "400mg", taken: false)
            ],
            takenCount: 0,
            allTaken: false
        )
    }
}

struct WidgetVitaminData: Codable {
    let id: Int64
    let name: String
    let emoji: String
    let dosage: String
    let taken: Bool
}

// MARK: - Widget Views

struct KaleWidgetEntryView: View {
    var entry: KaleWidgetProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: KaleWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("💊")
                    .font(.system(size: 16))
                Text("Kale")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "1a1f1a"))
                Spacer()
            }

            if entry.vitamins.isEmpty {
                Spacer()
                Text("No vitamins yet")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "6b7280"))
                Text("Open app to add")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "6b7280").opacity(0.7))
                Spacer()
            } else {
                Spacer()
                Text("\(entry.takenCount)/\(entry.vitamins.count)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(entry.allTaken ? Color(hex: "4ade80") : Color(hex: "1a1f1a"))

                Text(entry.allTaken ? "All done! 🎉" : "taken today")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "6b7280"))
                Spacer()
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(hex: "f8faf7")
        }
        .widgetURL(URL(string: "kale://today"))
    }
}

struct MediumWidgetView: View {
    let entry: KaleWidgetEntry

    var body: some View {
        HStack(spacing: 0) {
            // Left: Summary
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("💊")
                        .font(.system(size: 14))
                    Text("Kale")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "1a1f1a"))
                }

                Spacer()

                if entry.vitamins.isEmpty {
                    Text("No vitamins yet")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "6b7280"))
                    Text("Open app to add")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "6b7280").opacity(0.7))
                } else {
                    Text("\(entry.takenCount)/\(entry.vitamins.count)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(entry.allTaken ? Color(hex: "4ade80") : Color(hex: "1a1f1a"))

                    Text(entry.allTaken ? "All done today!" : "taken today")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "6b7280"))

                    if entry.allTaken {
                        Text("🌿")
                            .font(.system(size: 20))
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 14)
            .padding(.vertical, 12)

            // Divider
            Rectangle()
                .fill(Color(hex: "d1d9d1").opacity(0.5))
                .frame(width: 1)

            // Right: Vitamin list
            VStack(alignment: .leading, spacing: 6) {
                if entry.vitamins.isEmpty {
                    Spacer()
                    Text("Add vitamins in app")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "6b7280"))
                    Spacer()
                } else {
                    ForEach(entry.vitamins.prefix(3)) { vitamin in
                        HStack(spacing: 6) {
                            Text(vitamin.emoji)
                                .font(.system(size: 14))
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(vitamin.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "1a1f1a"))
                                    .lineLimit(1)
                                Text(vitamin.dosage)
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(hex: "6b7280"))
                            }

                            Spacer()

                            Image(systemName: vitamin.taken ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 14))
                                .foregroundColor(vitamin.taken ? Color(hex: "4ade80") : Color(hex: "d1d9d1"))
                        }
                    }

                    if entry.vitamins.count > 3 {
                        Text("+\(entry.vitamins.count - 3) more")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "6b7280"))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .containerBackground(for: .widget) {
            Color(hex: "f8faf7")
        }
        .widgetURL(URL(string: "kale://today"))
    }
}

// MARK: - Color Extension for Widget

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
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Widget Configuration

struct KaleWidget: Widget {
    let kind: String = "KaleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KaleWidgetProvider()) { entry in
            KaleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today's Vitamins")
        .description("Track your daily vitamin intake at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
#Preview(as: .systemSmall) {
    KaleWidget()
} timeline: {
    KaleWidgetEntry(
        date: Date(),
        vitamins: [
            WidgetVitamin(id: 1, name: "Vitamin D3", emoji: "💊", dosage: "2000 IU", taken: true),
            WidgetVitamin(id: 2, name: "Magnesium", emoji: "🫙", dosage: "400mg", taken: false)
        ],
        takenCount: 1,
        allTaken: false
    )
}

#Preview(as: .systemMedium) {
    KaleWidget()
} timeline: {
    KaleWidgetEntry(
        date: Date(),
        vitamins: [
            WidgetVitamin(id: 1, name: "Vitamin D3", emoji: "💊", dosage: "2000 IU", taken: true),
            WidgetVitamin(id: 2, name: "Magnesium", emoji: "🫙", dosage: "400mg", taken: true),
            WidgetVitamin(id: 3, name: "Omega-3", emoji: "🐟", dosage: "1000mg", taken: false)
        ],
        takenCount: 2,
        allTaken: false
    )
}
