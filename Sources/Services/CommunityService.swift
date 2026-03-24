import Foundation

// MARK: - Community Models

struct SharedRoutine: Identifiable, Codable {
    let id: UUID
    let authorName: String
    let authorEmoji: String
    let title: String
    let vitamins: [RoutineVitamin]
    let likes: Int
    let uses: Int
    let createdAt: Date
    let tags: [String]

    struct RoutineVitamin: Codable {
        let name: String
        let dosage: String
        let emoji: String
    }
}

// MARK: - Community Service

final class CommunityService: ObservableObject {
    static let shared = CommunityService()

    // Local mock database — in production this would be a backend API
    @Published var popularRoutines: [SharedRoutine] = []
    @Published var recentRoutines: [SharedRoutine] = []
    @Published var isLoading = false

    private init() {
        loadMockRoutines()
    }

    // MARK: - Fetch Routines

    func fetchPopularRoutines() async throws -> [SharedRoutine] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        return popularRoutines
    }

    func fetchRecentRoutines() async throws -> [SharedRoutine] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return recentRoutines
    }

    func searchRoutines(query: String) async throws -> [SharedRoutine] {
        try await Task.sleep(nanoseconds: 300_000_000)
        let lowercased = query.lowercased()
        return popularRoutines.filter { routine in
            routine.title.lowercased().contains(lowercased) ||
            routine.vitamins.contains { $0.name.lowercased().contains(lowercased) } ||
            routine.tags.contains { $0.lowercased().contains(lowercased) }
        }
    }

    // MARK: - Share Routine

    func shareRoutine(
        title: String,
        vitamins: [Vitamin],
        tags: [String],
        authorName: String = "Anonymous",
        authorEmoji: String = "🧑"
    ) throws -> SharedRoutine {
        let routine = SharedRoutine(
            id: UUID(),
            authorName: authorName,
            authorEmoji: authorEmoji,
            title: title,
            vitamins: vitamins.map { SharedRoutine.RoutineVitamin(name: $0.name, dosage: $0.dosage, emoji: $0.pillEmoji) },
            likes: 0,
            uses: 0,
            createdAt: Date(),
            tags: tags
        )

        // Add to local "server"
        popularRoutines.insert(routine, at: 0)
        recentRoutines.insert(routine, at: 0)

        return routine
    }

    func likeRoutine(id: UUID) {
        if let index = popularRoutines.firstIndex(where: { $0.id == id }) {
            var updated = popularRoutines[index]
            updated = SharedRoutine(
                id: updated.id,
                authorName: updated.authorName,
                authorEmoji: updated.authorEmoji,
                title: updated.title,
                vitamins: updated.vitamins,
                likes: updated.likes + 1,
                uses: updated.uses,
                createdAt: updated.createdAt,
                tags: updated.tags
            )
            popularRoutines[index] = updated
        }
        if let index = recentRoutines.firstIndex(where: { $0.id == id }) {
            let original = recentRoutines[index]
            let updated = SharedRoutine(
                id: original.id,
                authorName: original.authorName,
                authorEmoji: original.authorEmoji,
                title: original.title,
                vitamins: original.vitamins,
                likes: original.likes + 1,
                uses: original.uses,
                createdAt: original.createdAt,
                tags: original.tags
            )
            recentRoutines[index] = updated
        }
    }

    func recordUse(id: UUID) {
        if let index = popularRoutines.firstIndex(where: { $0.id == id }) {
            let original = popularRoutines[index]
            let updated = SharedRoutine(
                id: original.id,
                authorName: original.authorName,
                authorEmoji: original.authorEmoji,
                title: original.title,
                vitamins: original.vitamins,
                likes: original.likes,
                uses: original.uses + 1,
                createdAt: original.createdAt,
                tags: original.tags
            )
            popularRoutines[index] = updated
        }
    }

    // MARK: - Import Routine

    func importRoutine(_ routine: SharedRoutine, to database: DatabaseService) throws -> [Vitamin] {
        var imported: [Vitamin] = []
        let now = Date()

        for rv in routine.vitamins {
            let vitamin = Vitamin(
                name: rv.name,
                dosage: rv.dosage,
                barcode: nil,
                pillEmoji: rv.emoji,
                reminderTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? now,
                createdAt: now,
                stockCount: nil,
                dailyDose: 1
            )
            let id = try database.insertVitamin(vitamin)
            var v = vitamin
            v.id = id
            imported.append(v)
        }

        recordUse(id: routine.id)
        return imported
    }

    // MARK: - Mock Data

    private func loadMockRoutines() {
        popularRoutines = [
            SharedRoutine(
                id: UUID(),
                authorName: "Alex",
                authorEmoji: "🏃",
                title: "Runner's Essentials",
                vitamins: [
                    SharedRoutine.RoutineVitamin(name: "Vitamin D3", dosage: "2000 IU", emoji: "💊"),
                    SharedRoutine.RoutineVitamin(name: "Magnesium", dosage: "400mg", emoji: "🫙"),
                    SharedRoutine.RoutineVitamin(name: "Omega-3", dosage: "1000mg", emoji: "🐟"),
                    SharedRoutine.RoutineVitamin(name: "Collagen", dosage: "10g", emoji: "💊"),
                ],
                likes: 142,
                uses: 389,
                createdAt: Date().addingTimeInterval(-86400 * 30),
                tags: ["fitness", "running", "recovery"]
            ),
            SharedRoutine(
                id: UUID(),
                authorName: "Sarah",
                authorEmoji: "🧘",
                title: "Mind & Body Balance",
                vitamins: [
                    SharedRoutine.RoutineVitamin(name: "Ashwagandha", dosage: "600mg", emoji: "🌿"),
                    SharedRoutine.RoutineVitamin(name: "Vitamin B12", dosage: "1000mcg", emoji: "💊"),
                    SharedRoutine.RoutineVitamin(name: "Magnesium", dosage: "400mg", emoji: "🫙"),
                    SharedRoutine.RoutineVitamin(name: "Omega-3", dosage: "1000mg", emoji: "🐟"),
                ],
                likes: 98,
                uses: 267,
                createdAt: Date().addingTimeInterval(-86400 * 15),
                tags: ["stress", "wellness", "energy"]
            ),
            SharedRoutine(
                id: UUID(),
                authorName: "Dr. Mike",
                authorEmoji: "👨‍⚕️",
                title: "General Wellness Stack",
                vitamins: [
                    SharedRoutine.RoutineVitamin(name: "Multivitamin", dosage: "1 tablet", emoji: "🫙"),
                    SharedRoutine.RoutineVitamin(name: "Vitamin D3", dosage: "2000 IU", emoji: "💊"),
                    SharedRoutine.RoutineVitamin(name: "Vitamin C", dosage: "1000mg", emoji: "🍊"),
                    SharedRoutine.RoutineVitamin(name: "Zinc", dosage: "30mg", emoji: "💊"),
                ],
                likes: 211,
                uses: 534,
                createdAt: Date().addingTimeInterval(-86400 * 60),
                tags: ["general", "immune", "daily"]
            ),
            SharedRoutine(
                id: UUID(),
                authorName: "Emma",
                authorEmoji: "💪",
                title: "Gym Regular",
                vitamins: [
                    SharedRoutine.RoutineVitamin(name: "Creatine", dosage: "5g", emoji: "💊"),
                    SharedRoutine.RoutineVitamin(name: "Vitamin D3", dosage: "5000 IU", emoji: "💊"),
                    SharedRoutine.RoutineVitamin(name: "Zinc", dosage: "30mg", emoji: "💊"),
                    SharedRoutine.RoutineVitamin(name: "Vitamin B12", dosage: "1000mcg", emoji: "💊"),
                ],
                likes: 87,
                uses: 198,
                createdAt: Date().addingTimeInterval(-86400 * 10),
                tags: ["gym", "muscle", "strength"]
            ),
            SharedRoutine(
                id: UUID(),
                authorName: "Jamie",
                authorEmoji: "😴",
                title: "Better Sleep Protocol",
                vitamins: [
                    SharedRoutine.RoutineVitamin(name: "Magnesium", dosage: "400mg", emoji: "🫙"),
                    SharedRoutine.RoutineVitamin(name: "Melatonin", dosage: "3mg", emoji: "😴"),
                    SharedRoutine.RoutineVitamin(name: "Vitamin D3", dosage: "2000 IU", emoji: "💊"),
                    SharedRoutine.RoutineVitamin(name: "L-Theanine", dosage: "200mg", emoji: "💊"),
                ],
                likes: 176,
                uses: 412,
                createdAt: Date().addingTimeInterval(-86400 * 20),
                tags: ["sleep", "relaxation", "evening"]
            ),
        ]

        recentRoutines = popularRoutines.sorted { $0.createdAt > $1.createdAt }
    }
}
