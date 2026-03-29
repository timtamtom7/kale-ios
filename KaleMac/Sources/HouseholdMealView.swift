import SwiftUI

// MARK: - Household Member

struct HouseholdMember: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var emoji: String
    var color: MemberColor
    var addedMeals: [MealAssignment]
    var isCurrentUser: Bool

    init(id: UUID = UUID(), name: String, emoji: String, color: MemberColor, addedMeals: [MealAssignment] = [], isCurrentUser: Bool = false) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.color = color
        self.addedMeals = addedMeals
        self.isCurrentUser = isCurrentUser
    }

    static let defaultColors: [MemberColor] = [.blue, .green, .purple, .orange, .pink, .teal]
}

enum MemberColor: String, Codable, CaseIterable {
    case blue, green, purple, orange, pink, teal, red, yellow

    var swatch: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        case .pink: return .pink
        case .teal: return .teal
        case .red: return .red
        case .yellow: return .yellow
        }
    }
}

// MARK: - Meal Assignment

struct MealAssignment: Identifiable, Codable, Hashable {
    let id: UUID
    let memberId: UUID
    let meal: Meal
    let dayIndex: Int // 0 = Monday, 6 = Sunday
    let mealType: MealType
    let assignedAt: Date

    init(id: UUID = UUID(), memberId: UUID, meal: Meal, dayIndex: Int, mealType: MealType, assignedAt: Date = Date()) {
        self.id = id
        self.memberId = memberId
        self.meal = meal
        self.dayIndex = dayIndex
        self.mealType = mealType
        self.assignedAt = assignedAt
    }
}

// MARK: - Household Meal View

struct HouseholdMealView: View {
    @State private var members: [HouseholdMember] = [
        HouseholdMember(name: "You", emoji: "🧑", color: .blue, isCurrentUser: true),
        HouseholdMember(name: "Sarah", emoji: "👩", color: .green),
        HouseholdMember(name: "Mike", emoji: "👨", color: .purple)
    ]
    @State private var mealAssignments: [MealAssignment] = []
    @State private var showingInviteSheet = false
    @State private var showingAddMemberSheet = false
    @State private var showingAddMealSheet = false
    @State private var selectedDayIndex: Int = 0
    @State private var selectedMemberId: UUID?
    @State private var inviteCode: String = ""

    private let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var currentUser: HouseholdMember? {
        members.first { $0.isCurrentUser }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Member bar
            memberBar

            Divider()

            // Calendar grid
            calendarGrid

            Divider()

            // Activity feed
            activityFeed
        }
        .sheet(isPresented: $showingInviteSheet) {
            inviteSheet
        }
        .sheet(isPresented: $showingAddMemberSheet) {
            addMemberSheet
        }
        .sheet(isPresented: $showingAddMealSheet) {
            addMealSheet
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Household Meal Plan")
                    .font(.title.bold())
                Text("\(members.count) members planning together")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                showingInviteSheet = true
            } label: {
                Label("Invite", systemImage: "person.badge.plus")
            }
            .buttonStyle(.borderedProminent)

            Button {
                showingAddMemberSheet = true
            } label: {
                Label("Add Member", systemImage: "plus")
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    // MARK: - Member Bar

    private var memberBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(members) { member in
                    memberChip(member)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func memberChip(_ member: HouseholdMember) -> some View {
        HStack(spacing: 6) {
            Text(member.emoji)
                .font(.title3)

            Text(member.name)
                .font(.subheadline.weight(.medium))

            if member.isCurrentUser {
                Text("You")
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(member.color.swatch.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(member.color.swatch.opacity(member.isCurrentUser ? 0.2 : 0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(member.color.swatch.opacity(0.5), lineWidth: 1)
        )
        .clipShape(Capsule())
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(spacing: 0) {
            // Day headers
            HStack(spacing: 0) {
                ForEach(Array(daysOfWeek.enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(index == selectedDayIndex ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(index == selectedDayIndex ? Color.accentColor.opacity(0.1) : Color.clear)
                        .onTapGesture {
                            selectedDayIndex = index
                        }
                }
            }

            Divider()

            // Meal slots
            VStack(spacing: 4) {
                ForEach(MealType.allCases, id: \.self) { mealType in
                    HStack(spacing: 0) {
                        // Meal type label
                        HStack(spacing: 4) {
                            Image(systemName: mealType.icon)
                                .font(.caption)
                            Text(mealType.rawValue)
                                .font(.caption)
                        }
                        .frame(width: 80, alignment: .leading)
                        .foregroundStyle(.secondary)

                        // Day cells
                        ForEach(0..<7, id: \.self) { dayIndex in
                            mealSlot(dayIndex: dayIndex, mealType: mealType)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(.vertical, 8)
        }
        .frame(minHeight: 200)
    }

    private func mealSlot(dayIndex: Int, mealType: MealType) -> some View {
        let assignment = findAssignment(dayIndex: dayIndex, mealType: mealType)
        var member: HouseholdMember? = nil
        if let a = assignment {
            member = members.first { $0.id == a.memberId }
        }

        return Group {
            if let assignment = assignment, let m = member {
                mealSlotFilled(assignment: assignment, member: m)
            } else {
                mealSlotEmpty(dayIndex: dayIndex, mealType: mealType)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .padding(2)
    }

    private func mealSlotFilled(assignment: MealAssignment, member: HouseholdMember) -> some View {
        VStack(spacing: 2) {
            Text(member.emoji)
                .font(.caption2)
            Text(assignment.meal.name)
                .font(.caption2)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .background(member.color.swatch.opacity(0.2))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(member.color.swatch, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func mealSlotEmpty(dayIndex: Int, mealType: MealType) -> some View {
        Button {
            selectedDayIndex = dayIndex
            selectedMemberId = currentUser?.id
            showingAddMealSheet = true
        } label: {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                .foregroundStyle(.tertiary)
                .overlay(
                    Image(systemName: "plus")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Activity Feed

    private var activityFeed: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 12)

            if mealAssignments.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "fork.knife")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text("No meals added yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Tap + on any day to add a meal")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(sortedRecentAssignments) { assignment in
                            activityRow(assignment)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 150)
            }
        }
    }

    private func activityRow(_ assignment: MealAssignment) -> some View {
        let member = members.first { $0.id == assignment.memberId } ?? members[0]
        let dayName = daysOfWeek[assignment.dayIndex]

        return HStack(spacing: 8) {
            Text(member.emoji)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(member.name) added: \(assignment.meal.name)")
                    .font(.subheadline.weight(.medium))
                Text("\(dayName) • \(assignment.mealType.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Circle()
                .fill(member.color.swatch)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(member.color.swatch.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var sortedRecentAssignments: [MealAssignment] {
        mealAssignments.sorted { $0.assignedAt > $1.assignedAt }.prefix(10).map { $0 }
    }

    // MARK: - Helper

    private func findAssignment(dayIndex: Int, mealType: MealType) -> MealAssignment? {
        mealAssignments.first { $0.dayIndex == dayIndex && $0.mealType == mealType }
    }

    // MARK: - Invite Sheet

    private var inviteSheet: some View {
        VStack(spacing: 20) {
            Text("Invite Household Member")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 8) {
                Text("Share this code with family members:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Text(inviteCode.isEmpty ? "KALE-\(UUID().uuidString.prefix(8))" : inviteCode)
                        .font(.title3.monospaced())
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Button {
                        inviteCode.isEmpty ? generateInviteCode() : copyInviteCode()
                    } label: {
                        Image(systemName: inviteCode.isEmpty ? "arrow.clockwise" : "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                }
            }

            HStack(spacing: 16) {
                ShareLink(item: "Join my KaleMac household with code: \(inviteCode)") {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)

                Button("Close") {
                    showingInviteSheet = false
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(width: 400)
    }

    private func generateInviteCode() {
        inviteCode = "KALE-\(UUID().uuidString.prefix(8).uppercased())"
    }

    private func copyInviteCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(inviteCode, forType: .string)
    }

    // MARK: - Add Member Sheet

    private var addMemberSheet: some View {
        AddMemberSheetView(members: $members) {
            showingAddMemberSheet = false
        }
    }

    // MARK: - Add Meal Sheet

    private var addMealSheet: some View {
        AddMealToPlanSheet(
            members: members,
            dayIndex: selectedDayIndex,
            onAdd: { assignment in
                mealAssignments.append(assignment)
                showingAddMealSheet = false
            },
            onCancel: {
                showingAddMealSheet = false
            }
        )
    }
}

// MARK: - Add Member Sheet

struct AddMemberSheetView: View {
    @Binding var members: [HouseholdMember]
    @State private var name = ""
    @State private var selectedEmoji = "👩"
    @State private var selectedColor: MemberColor = .green
    let onDismiss: () -> Void

    private let emojis = ["👩", "👨", "👦", "👧", "👴", "👵", "🧒", "👶", "🧑"]

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Household Member")
                .font(.title2.bold())

            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)

            VStack(alignment: .leading, spacing: 8) {
                Text("Avatar")
                    .font(.subheadline.weight(.medium))

                LazyVGrid(columns: Array(repeating: GridItem(.fixed(44)), count: 5), spacing: 8) {
                    ForEach(emojis, id: \.self) { emoji in
                        Text(emoji)
                            .font(.title2)
                            .padding(8)
                            .background(selectedEmoji == emoji ? Color.accentColor.opacity(0.2) : Color.clear)
                            .clipShape(Circle())
                            .onTapGesture {
                                selectedEmoji = emoji
                            }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.subheadline.weight(.medium))

                HStack(spacing: 12) {
                    ForEach(MemberColor.allCases, id: \.self) { color in
                        Circle()
                            .fill(color.swatch)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedColor = color
                            }
                    }
                }
            }

            HStack(spacing: 16) {
                Button("Cancel") {
                    onDismiss()
                }
                .buttonStyle(.bordered)

                Button("Add Member") {
                    let newMember = HouseholdMember(
                        name: name.isEmpty ? "Member" : name,
                        emoji: selectedEmoji,
                        color: selectedColor
                    )
                    members.append(newMember)
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 380)
    }
}

// MARK: - Add Meal To Plan Sheet

struct AddMealToPlanSheet: View {
    let members: [HouseholdMember]
    let dayIndex: Int
    let onAdd: (MealAssignment) -> Void
    let onCancel: () -> Void

    @State private var selectedMemberId: UUID?
    @State private var selectedMeal: Meal?
    @State private var selectedMealType: MealType = .dinner

    private let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Meal to \(daysOfWeek[dayIndex])")
                .font(.title2.bold())

            // Member picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Who's cooking?")
                    .font(.subheadline.weight(.medium))

                HStack(spacing: 12) {
                    ForEach(members) { member in
                        VStack(spacing: 4) {
                            Text(member.emoji)
                                .font(.title)
                            Text(member.name)
                                .font(.caption)
                        }
                        .padding(8)
                        .background(selectedMemberId == member.id ? member.color.swatch.opacity(0.2) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(member.color.swatch, lineWidth: selectedMemberId == member.id ? 2 : 0)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            selectedMemberId = member.id
                        }
                    }
                }
            }

            // Meal type
            VStack(alignment: .leading, spacing: 8) {
                Text("Meal type")
                    .font(.subheadline.weight(.medium))

                Picker("Meal Type", selection: $selectedMealType) {
                    ForEach(MealType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Recipe picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Select recipe")
                    .font(.subheadline.weight(.medium))

                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Meal.sampleRecipes) { recipe in
                            HStack {
                                Text(recipe.name)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(recipe.cookTime) min")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(selectedMeal?.id == recipe.id ? Color.accentColor.opacity(0.1) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .onTapGesture {
                                selectedMeal = recipe
                            }
                        }
                    }
                }
                .frame(maxHeight: 150)
            }

            HStack(spacing: 16) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)

                Button("Add to Plan") {
                    guard let memberId = selectedMemberId ?? members.first?.id,
                          let meal = selectedMeal ?? Meal.sampleRecipes.first else { return }
                    let assignment = MealAssignment(
                        memberId: memberId,
                        meal: meal,
                        dayIndex: dayIndex,
                        mealType: selectedMealType
                    )
                    onAdd(assignment)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedMemberId == nil || selectedMeal == nil)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}

// MARK: - Preview

#Preview {
    HouseholdMealView()
        .frame(width: 700, height: 600)
}
