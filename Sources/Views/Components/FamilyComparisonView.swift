import SwiftUI

// MARK: - Family Member

struct FamilyMember: Identifiable {
    let id: UUID
    let name: String
    let emoji: String
    let consistencyScore: Double
    let streak: Int
    let isCurrentUser: Bool
}

// MARK: - Family Comparison View

struct FamilyComparisonView: View {
    let members: [FamilyMember]
    @Environment(\.dismiss) var dismiss

    private var sortedMembers: [FamilyMember] {
        members.sorted { $0.consistencyScore > $1.consistencyScore }
    }

    private var leader: FamilyMember? {
        sortedMembers.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundLight.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerCard
                        leaderBoard
                        consistencyChart
                    }
                    .padding()
                }
            }
            .navigationTitle("Family")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.accentGreen)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var headerCard: some View {
        VStack(spacing: 12) {
            if let leader = leader {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.accentGreen.opacity(0.15))
                            .frame(width: 60, height: 60)
                        Text(leader.emoji)
                            .font(.system(size: 28))
                        // Crown for leader
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.yellow)
                            .offset(x: 20, y: -22)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(leader.name) is leading! 🏆")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.textPrimary)
                        Text("\(Int(leader.consistencyScore * 100))% consistency this month")
                            .font(.system(size: 13))
                            .foregroundColor(.accentGreen)
                    }

                    Spacer()
                }
            } else {
                Text("Add family members to start competing!")
                    .font(.system(size: 15))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.surfaceLight)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }

    private var leaderBoard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leaderboard")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)

            ForEach(Array(sortedMembers.enumerated()), id: \.element.id) { index, member in
                FamilyMemberRow(rank: index + 1, member: member)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.surfaceLight)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }

    private var consistencyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Consistency This Month")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)

            ForEach(members) { member in
                HStack(spacing: 12) {
                    Text(member.emoji)
                        .font(.system(size: 16))

                    Text(member.name)
                        .font(.system(size: 13, weight: member.isCurrentUser ? .semibold : .regular))
                        .foregroundColor(.textPrimary)
                        .frame(width: 90, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.inactiveEmpty.opacity(0.2))
                                .frame(height: 8)

                            Capsule()
                                .fill(member.consistencyScore > 0.7 ? Color.accentGreen : Color.yellow)
                                .frame(width: geo.size.width * member.consistencyScore, height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(Int(member.consistencyScore * 100))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.surfaceLight)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}

// MARK: - Family Member Row

struct FamilyMemberRow: View {
    let rank: Int
    let member: FamilyMember

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.15))
                    .frame(width: 32, height: 32)

                if rank <= 3 {
                    Image(systemName: rankIcon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(rankColor)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(rankColor)
                }
            }
            .frame(width: 32)

            Text(member.emoji)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(member.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textPrimary)

                    if member.isCurrentUser {
                        Text("You")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentGreen)
                            .clipShape(Capsule())
                    }
                }

                Text("\(member.streak) day streak")
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(member.consistencyScore * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.accentGreen)
                Text("consistency")
                    .font(.system(size: 10))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.vertical, 8)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(hex: "C0C0C0")
        case 3: return Color(hex: "CD7F32")
        default: return .textSecondary
        }
    }

    private var rankIcon: String {
        switch rank {
        case 1: return "trophy.fill"
        case 2: return "trophy"
        case 3: return "trophy"
        default: return ""
        }
    }
}

// MARK: - Preview

#Preview {
    FamilyComparisonView(members: [
        FamilyMember(id: UUID(), name: "Tommaso", emoji: "🧑", consistencyScore: 0.92, streak: 14, isCurrentUser: true),
        FamilyMember(id: UUID(), name: "Sofia", emoji: "👩", consistencyScore: 0.85, streak: 8, isCurrentUser: false),
        FamilyMember(id: UUID(), name: "Marco", emoji: "👦", consistencyScore: 0.78, streak: 5, isCurrentUser: false),
    ])
}
