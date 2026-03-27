import SwiftUI

// MARK: - Family Management View

struct FamilyManagementView: View {
    @EnvironmentObject var familyService: FamilyService
    @Environment(\.dismiss) var dismiss
    @State private var members: [FamilyMember] = []
    @State private var showingAddMember = false
    @State private var showingInviteCode = false
    @State private var inviteCode = ""
    @State private var isLoading = true
    @State private var memberToRemove: FamilyMember?
    @State private var showingRemoveAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundLight.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(.accentGreen)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            headerSection
                            membersSection
                            inviteSection
                            familyRankingSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Family")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accentGreen)
                }
            }
            .onAppear {
                loadMembers()
            }
            .sheet(isPresented: $showingAddMember) {
                AddFamilyMemberView(onAdd: { member in
                    addMember(member)
                })
            }
            .alert("Remove Family Member?", isPresented: $showingRemoveAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    if let member = memberToRemove {
                        removeMember(member)
                    }
                }
            } message: {
                if let member = memberToRemove {
                    Text("Remove \(member.name) from your family? Their tracking data will be preserved but they won't appear in family comparisons.")
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentGreen.opacity(0.1))
                    .frame(width: 72, height: 72)

                Image(systemName: "person.3.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.accentGreen)
            }

            Text("Family Tracking")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.textPrimary)

            Text("Track vitamins together as a family.\nUp to 6 members can share.")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(.top, 8)
    }

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Family Members")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textSecondary)

                Spacer()

                if members.count < 6 {
                    Button {
                        showingAddMember = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Add")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.accentGreen)
                    }
                }
            }

            if members.isEmpty {
                emptyMembersCard
            } else {
                ForEach(members) { member in
                    FamilyMemberCard(member: member) {
                        memberToRemove = member
                        showingRemoveAlert = true
                    }
                }
            }
        }
    }

    private var emptyMembersCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 28))
                .foregroundColor(.inactiveEmpty)

            Text("No family members yet")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)

            Text("Add family members to track together")
                .font(.system(size: 12))
                .foregroundColor(.textSecondary.opacity(0.7))

            Button {
                showingAddMember = true
            } label: {
                Text("Add First Member")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentGreen)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(Color.surfaceLight)
        )
    }

    private var inviteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Invite Family")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textSecondary)

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Share your invite code")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textPrimary)
                        Text("Family members can join with this code")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    Button {
                        generateInviteCode()
                    } label: {
                        Text("Generate")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.accentGreen)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.accentGreen.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                if !inviteCode.isEmpty {
                    HStack {
                        Text(inviteCode)
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(.accentGreen)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.accentGreen.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))

                        Spacer()

                        Button {
                            UIPasteboard.general.string = inviteCode
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 14))
                                .foregroundColor(.accentGreen)
                                .frame(width: 40, height: 40)
                                .background(Color.accentGreen.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(Color.surfaceLight)
            )
        }
    }

    private var familyRankingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Month's Consistency")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textSecondary)

            FamilyComparisonView()
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                        .fill(Color.surfaceLight)
                )
        }
    }

    private func loadMembers() {
        isLoading = true
        do {
            _ = try familyService.ensureCurrentUser()
            members = try familyService.fetchAllMembers()
        } catch {
            print("Load family members error: \(error)")
        }
        isLoading = false
    }

    private func addMember(_ member: FamilyMember) {
        do {
            try familyService.addMember(member)
            loadMembers()
        } catch {
            print("Add member error: \(error)")
        }
    }

    private func removeMember(_ member: FamilyMember) {
        do {
            try familyService.removeMember(id: member.id)
            loadMembers()
        } catch {
            print("Remove member error: \(error)")
        }
    }

    private func generateInviteCode() {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        inviteCode = String((0..<6).map { _ in chars.randomElement()! })
    }
}

// MARK: - Family Member Card

struct FamilyMemberCard: View {
    let member: FamilyMember
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentGreen.opacity(0.1))
                    .frame(width: 48, height: 48)
                Text(member.emoji)
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(member.name)
                        .font(.system(size: 15, weight: .medium))
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

                HStack(spacing: 8) {
                    Label("\(member.streak) day streak", systemImage: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(member.streak >= 7 ? .accentGreen : .textSecondary)

                    Text("•")
                        .foregroundColor(.textSecondary.opacity(0.5))

                    Text("\(Int(member.consistencyScore * 100))% this month")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            if !member.isCurrentUser {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.surfaceLight)
                        .clipShape(Circle())
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Color.surfaceLight)
        )
    }
}

// MARK: - Add Family Member View

struct AddFamilyMemberView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var selectedEmoji = "👩"

    let onAdd: (FamilyMember) -> Void

    private let emojis = FamilyMember.defaultEmojis

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundLight.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Emoji picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Avatar")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.textSecondary)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                                ForEach(emojis, id: \.self) { emoji in
                                    Text(emoji)
                                        .font(.system(size: 28))
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(selectedEmoji == emoji ? Color.accentGreen.opacity(0.2) : Color.surfaceLight)
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(selectedEmoji == emoji ? Color.accentGreen : Color.clear, lineWidth: 2)
                                        )
                                        .onTapGesture {
                                            selectedEmoji = emoji
                                        }
                                }
                            }
                        }

                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.textSecondary)

                            TextField("e.g. Sarah", text: $name)
                                .font(.system(size: 15))
                                .padding(12)
                                .background(Color.surfaceLight)
                                .cornerRadius(Theme.CornerRadius.md)
                        }

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Family Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.accentGreen)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let member = FamilyMember(name: name.isEmpty ? "Family Member" : name, emoji: selectedEmoji)
                        onAdd(member)
                        dismiss()
                    }
                    .foregroundColor(.accentGreen)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    FamilyManagementView()
        .environmentObject(FamilyService.shared)
}
