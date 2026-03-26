import SwiftUI

// MARK: - Family Comparison View (Embedded in FamilyManagementView)

struct FamilyComparisonView: View {
    @EnvironmentObject var familyService: FamilyService
    @State private var members: [FamilyMember] = []
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
                    .tint(.accentGreen)
                    .padding(.vertical, 24)
            } else if members.isEmpty {
                emptyState
            } else {
                leaderBoardSection
                consistencyBars
            }
        }
        .onAppear {
            loadData()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3")
                .font(.system(size: 28))
                .foregroundColor(.inactiveEmpty)

            Text("No family members yet")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)

            Text("Add family members to start competing!")
                .font(.system(size: 12))
                .foregroundColor(.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var leaderBoardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leaderboard")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)

            ForEach(Array(sortedMembers.enumerated()), id: \.element.id) { index, member in
                CompactMemberRow(rank: index + 1, member: member)
            }
        }
    }

    private var consistencyBars: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Consistency")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)

            ForEach(members) { member in
                HStack(spacing: 10) {
                    Text(member.emoji)
                        .font(.system(size: 14))
                        .frame(width: 24)

                    Text(member.name)
                        .font(.system(size: 12, weight: member.isCurrentUser ? .semibold : .regular))
                        .foregroundColor(.textPrimary)
                        .frame(width: 70, alignment: .leading)
                        .lineLimit(1)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.inactiveEmpty.opacity(0.2))
                                .frame(height: 6)

                            Capsule()
                                .fill(member.consistencyScore > 0.7 ? Color.accentGreen : Color.yellow)
                                .frame(width: geo.size.width * max(member.consistencyScore, 0.01), height: 6)
                        }
                    }
                    .frame(height: 6)

                    Text("\(Int(member.consistencyScore * 100))%")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .frame(width: 34, alignment: .trailing)
                }
            }
        }
    }

    private var sortedMembers: [FamilyMember] {
        members.sorted { $0.consistencyScore > $1.consistencyScore }
    }

    private var leader: FamilyMember? {
        sortedMembers.first
    }

    private func loadData() {
        isLoading = true
        do {
            _ = try familyService.ensureCurrentUser()
            members = try familyService.fetchAllMembers()
        } catch {
            print("Load family members error: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Compact Member Row

struct CompactMemberRow: View {
    let rank: Int
    let member: FamilyMember

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.15))
                    .frame(width: 28, height: 28)

                if rank <= 3 {
                    Image(systemName: rankIcon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(rankColor)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(rankColor)
                }
            }
            .frame(width: 28)

            Text(member.emoji)
                .font(.system(size: 16))

            Text(member.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textPrimary)

            if member.isCurrentUser {
                Text("You")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.accentGreen)
                    .clipShape(Capsule())
            }

            Spacer()

            Text("\(member.streak)d")
                .font(.system(size: 11))
                .foregroundColor(.textSecondary)

            Text("\(Int(member.consistencyScore * 100))%")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.accentGreen)
        }
        .padding(.vertical, 6)
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

#Preview {
    FamilyComparisonView()
        .environmentObject(FamilyService.shared)
}
