import SwiftUI

// MARK: - Botanical Capsule Icon (for use in UI)

struct BotanicalCapsuleIcon: View {
    let emoji: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.accentGreen.opacity(0.15), Color.accentWarm.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Text(emoji)
                .font(.system(size: size * 0.45))
        }
    }
}

// MARK: - Premium Badge

struct PremiumBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.system(size: 10))
            Text("Premium")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(.yellow)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.yellow.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Free Badge

struct FreeBadge: View {
    var body: some View {
        Text("Free")
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.accentGreen)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentGreen.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - Consistency Ring

struct ConsistencyRing: View {
    let score: Double
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.inactiveEmpty.opacity(0.3), lineWidth: size * 0.08)

            Circle()
                .trim(from: 0, to: score)
                .stroke(
                    LinearGradient(
                        colors: [.accentGreen, Color(hex: "22c55e")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("\(Int(score * 100))%")
                .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                .foregroundColor(.accentGreen)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Calendar Heatmap Preview

struct CalendarHeatmapPreview: View {
    let weeks: Int
    let intensity: Double

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<weeks, id: \.self) { week in
                VStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { day in
                        let intensity = Double.random(in: 0...1)
                        Circle()
                            .fill(intensityColor(intensity))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
    }

    private func intensityColor(_ value: Double) -> Color {
        if value < 0.2 { return Color.inactiveEmpty.opacity(0.3) }
        if value < 0.6 { return Color.yellow.opacity(0.5) }
        return Color.accentGreen
    }
}

// MARK: - Pill Shape View

struct PillShapeView: View {
    let color: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            Capsule()
                .fill(color)
                .frame(width: size * 1.8, height: size)

            Capsule()
                .fill(color.opacity(0.7))
                .frame(width: size * 0.9, height: size)
                .offset(x: size * 0.45)
        }
    }
}

#Preview("Capsule Icon") {
    HStack(spacing: 16) {
        BotanicalCapsuleIcon(emoji: "💊", size: 60)
        BotanicalCapsuleIcon(emoji: "🫙", size: 60)
        BotanicalCapsuleIcon(emoji: "🐟", size: 60)
    }
    .padding()
    .background(Color.backgroundLight)
}

#Preview("Badges") {
    HStack(spacing: 16) {
        PremiumBadge()
        FreeBadge()
    }
    .padding()
    .background(Color.backgroundLight)
}

#Preview("Consistency Ring") {
    ConsistencyRing(score: 0.87, size: 120)
}

#Preview("Heatmap") {
    CalendarHeatmapPreview(weeks: 5, intensity: 0.7)
        .padding()
        .background(Color.backgroundLight)
}

#Preview("Pill Shape") {
    HStack(spacing: 20) {
        PillShapeView(color: .accentGreen, size: 30)
        PillShapeView(color: .yellow.opacity(0.6), size: 30)
        PillShapeView(color: .accentWarm, size: 30)
    }
    .padding()
    .background(Color.backgroundLight)
}
