import SwiftUI

struct CommunityView: View {
    @EnvironmentObject var communityService: CommunityService
    @EnvironmentObject var databaseService: DatabaseService
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedTab = 0
    @State private var popularRoutines: [SharedRoutine] = []
    @State private var recentRoutines: [SharedRoutine] = []
    @State private var searchText = ""
    @State private var searchResults: [SharedRoutine] = []
    @State private var isLoading = true
    @State private var showingShareSheet = false
    @State private var selectedRoutine: SharedRoutine?
    @State private var showingImportConfirm = false
    @State private var routineToImport: SharedRoutine?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundLight.ignoresSafeArea()

                if !subscriptionManager.canAccess(.communityRoutines) {
                    lockedView
                } else if isLoading {
                    ProgressView()
                        .tint(.accentGreen)
                } else {
                    contentView
                }
            }
            .navigationTitle("Community")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                            .foregroundColor(.accentGreen)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search routines...")
            .onChange(of: searchText) { _, newValue in
                if !newValue.isEmpty {
                    Task {
                        searchResults = (try? await communityService.searchRoutines(query: newValue)) ?? []
                    }
                }
            }
            .onAppear {
                loadData()
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareRoutineView()
            }
            .sheet(item: $routineToImport) { routine in
                ImportRoutineConfirmView(routine: routine) { imported in
                    routineToImport = nil
                    selectedRoutine = nil
                }
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
                Image(systemName: "person.3.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.accentGreen.opacity(0.6))
            }

            VStack(spacing: 10) {
                Text("Complete Plan Required")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.textPrimary)

                Text("Share your routines and discover\npopular stacks from the community.")
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

    private var contentView: some View {
        VStack(spacing: 0) {
            if !searchText.isEmpty {
                searchResultsView
            } else {
                tabSelector
                tabContent
            }
        }
    }

    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton("Popular", index: 0)
            tabButton("Recent", index: 1)
        }
        .padding(4)
        .background(Color.surfaceLight)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func tabButton(_ label: String, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = index
            }
        } label: {
            Text(label)
                .font(.system(size: 14, weight: selectedTab == index ? .semibold : .regular))
                .foregroundColor(selectedTab == index ? .white : .textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if selectedTab == index {
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .fill(Color.accentGreen)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                let routines = selectedTab == 0 ? popularRoutines : recentRoutines
                ForEach(routines) { routine in
                    RoutineCard(routine: routine, onImport: {
                        routineToImport = routine
                    }, onLike: {
                        communityService.likeRoutine(id: routine.id)
                    })
                }
            }
            .padding()
        }
    }

    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 28))
                            .foregroundColor(.inactiveEmpty)
                        Text("No routines found for \"\(searchText)\"")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(searchResults) { routine in
                        RoutineCard(routine: routine, onImport: {
                            routineToImport = routine
                        }, onLike: {
                            communityService.likeRoutine(id: routine.id)
                        })
                    }
                }
            }
            .padding()
        }
    }

    private func loadData() {
        isLoading = true
        Task {
            do {
                popularRoutines = try await communityService.fetchPopularRoutines()
                recentRoutines = try await communityService.fetchRecentRoutines()
            } catch {
                print("Load routines error: \(error)")
            }
            isLoading = false
        }
    }
}

// MARK: - Routine Card

struct RoutineCard: View {
    let routine: SharedRoutine
    let onImport: () -> Void
    let onLike: () -> Void
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.accentGreen.opacity(0.1))
                            .frame(width: 44, height: 44)
                        Text(routine.authorEmoji)
                            .font(.system(size: 20))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(routine.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        HStack(spacing: 6) {
                            Text(routine.authorName)
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)

                            Text("•")
                                .foregroundColor(.textSecondary.opacity(0.5))

                            Text("\(routine.uses) uses")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
            }
            .buttonStyle(.plain)
            .padding(16)

            // Expanded content
            if expanded {
                Divider()
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 12) {
                    // Vitamins list
                    ForEach(routine.vitamins, id: \.name) { vitamin in
                        HStack(spacing: 10) {
                            Text(vitamin.emoji)
                                .font(.system(size: 16))
                                .frame(width: 24)

                            Text(vitamin.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.textPrimary)

                            Spacer()

                            Text(vitamin.dosage)
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                        }
                    }

                    // Tags
                    if !routine.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(routine.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.system(size: 11))
                                        .foregroundColor(.accentGreen)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.accentGreen.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    Divider()

                    // Actions
                    HStack(spacing: 0) {
                        Button(action: onLike) {
                            HStack(spacing: 6) {
                                Image(systemName: "heart")
                                    .font(.system(size: 14))
                                Text("\(routine.likes)")
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(.textSecondary)
                        }

                        Spacer()

                        Button(action: onImport) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 14))
                                Text("Import")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.accentGreen)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(Color.surfaceLight)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        )
    }
}

// MARK: - Share Routine View

struct ShareRoutineView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var databaseService: DatabaseService
    @EnvironmentObject var communityService: CommunityService
    @State private var title = ""
    @State private var selectedTags: Set<String> = []
    @State private var vitamins: [Vitamin] = []
    @State private var isSharing = false

    private let availableTags = ["fitness", "wellness", "energy", "sleep", "immune", "general", "stress", "recovery", "muscle", "daily"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundLight.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Routine Name")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.textSecondary)
                            TextField("e.g. Morning Energy Stack", text: $title)
                                .font(.system(size: 15))
                                .padding(12)
                                .background(Color.surfaceLight)
                                .cornerRadius(Theme.CornerRadius.md)
                        }

                        // Your vitamins
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Vitamins to Share")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.textSecondary)

                            if vitamins.isEmpty {
                                Text("No vitamins added yet")
                                    .font(.system(size: 13))
                                    .foregroundColor(.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 16)
                            } else {
                                ForEach(vitamins) { vitamin in
                                    HStack(spacing: 12) {
                                        Text(vitamin.pillEmoji)
                                            .font(.system(size: 18))
                                        Text(vitamin.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.textPrimary)
                                        Spacer()
                                        Text(vitamin.dosage)
                                            .font(.system(size: 12))
                                            .foregroundColor(.textSecondary)
                                    }
                                    .padding(12)
                                    .background(Color.surfaceLight)
                                    .cornerRadius(Theme.CornerRadius.sm)
                                }
                            }
                        }

                        // Tags
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.textSecondary)

                            FlowLayout(spacing: 8) {
                                ForEach(availableTags, id: \.self) { tag in
                                    Button {
                                        if selectedTags.contains(tag) {
                                            selectedTags.remove(tag)
                                        } else {
                                            selectedTags.insert(tag)
                                        }
                                    } label: {
                                        Text("#\(tag)")
                                            .font(.system(size: 12, weight: selectedTags.contains(tag) ? .semibold : .regular))
                                            .foregroundColor(selectedTags.contains(tag) ? .white : .accentGreen)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(selectedTags.contains(tag) ? Color.accentGreen : Color.accentGreen.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Share Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.accentGreen)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Share") {
                        shareRoutine()
                    }
                    .foregroundColor(.accentGreen)
                    .disabled(title.isEmpty || vitamins.isEmpty || isSharing)
                }
            }
            .onAppear {
                loadVitamins()
            }
        }
    }

    private func loadVitamins() {
        do {
            vitamins = try databaseService.fetchAllVitamins()
        } catch {
            print("Load vitamins error: \(error)")
        }
    }

    private func shareRoutine() {
        isSharing = true
        do {
            _ = try communityService.shareRoutine(
                title: title,
                vitamins: vitamins,
                tags: Array(selectedTags)
            )
            dismiss()
        } catch {
            print("Share routine error: \(error)")
        }
        isSharing = false
    }
}

// MARK: - Import Routine Confirm View

struct ImportRoutineConfirmView: View {
    let routine: SharedRoutine
    let onComplete: ([Vitamin]) -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var communityService: CommunityService
    @EnvironmentObject var databaseService: DatabaseService
    @State private var importedVitamins: [Vitamin] = []
    @State private var isImporting = false
    @State private var done = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundLight.ignoresSafeArea()

                if done {
                    doneView
                } else if isImporting {
                    ProgressView()
                        .tint(.accentGreen)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Routine preview
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(routine.authorEmoji)
                                        .font(.system(size: 20))
                                    Text("by \(routine.authorName)")
                                        .font(.system(size: 13))
                                        .foregroundColor(.textSecondary)
                                }

                                Text(routine.title)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.textPrimary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // Vitamins to import
                            VStack(alignment: .leading, spacing: 8) {
                                Text("This will add \(routine.vitamins.count) vitamins to your list:")
                                    .font(.system(size: 13))
                                    .foregroundColor(.textSecondary)

                                ForEach(routine.vitamins, id: \.name) { vitamin in
                                    HStack(spacing: 12) {
                                        Text(vitamin.emoji)
                                            .font(.system(size: 20))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(vitamin.name)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.textPrimary)
                                            Text(vitamin.dosage)
                                                .font(.system(size: 12))
                                                .foregroundColor(.textSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.accentGreen)
                                    }
                                    .padding(12)
                                    .background(Color.surfaceLight)
                                    .cornerRadius(Theme.CornerRadius.sm)
                                }
                            }

                            Spacer()
                        }
                        .padding()
                    }

                    VStack {
                        Spacer()
                        Button {
                            importRoutine()
                        } label: {
                            Text("Import \(routine.vitamins.count) Vitamins")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.accentGreen)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                        }
                        .padding()
                        .background(Color.backgroundLight)
                    }
                }
            }
            .navigationTitle("Import Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.accentGreen)
                }
            }
        }
    }

    private var doneView: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.accentGreen.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.accentGreen)
            }

            VStack(spacing: 8) {
                Text("Routine Imported!")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.textPrimary)

                Text("\(importedVitamins.count) vitamins added to your list")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentGreen)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    private func importRoutine() {
        isImporting = true
        Task {
            do {
                importedVitamins = try communityService.importRoutine(routine, to: databaseService)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        done = true
                    }
                }
            } catch {
                print("Import routine error: \(error)")
            }
            isImporting = false
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, containerWidth: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layout(sizes: sizes, containerWidth: bounds.width).offsets

        for (subview, offset) in zip(subviews, offsets) {
            subview.place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }

    private struct LayoutResult {
        let offsets: [CGPoint]
        let size: CGSize
    }

    private func layout(sizes: [CGSize], containerWidth: CGFloat) -> LayoutResult {
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for size in sizes {
            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            offsets.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxWidth = max(maxWidth, currentX - spacing)
        }

        return LayoutResult(offsets: offsets, size: CGSize(width: maxWidth, height: currentY + lineHeight))
    }
}

#Preview {
    CommunityView()
        .environmentObject(CommunityService.shared)
        .environmentObject(DatabaseService.shared)
        .environmentObject(SubscriptionManager.shared)
}
