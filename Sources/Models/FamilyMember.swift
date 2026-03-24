import Foundation

// MARK: - Family Member Model

struct FamilyMember: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var emoji: String
    var consistencyScore: Double
    var streak: Int
    var isCurrentUser: Bool
    var currentStreakStart: Date?
    var joinedAt: Date

    init(id: UUID = UUID(), name: String, emoji: String, consistencyScore: Double = 0, streak: Int = 0, isCurrentUser: Bool = false, joinedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.consistencyScore = consistencyScore
        self.streak = streak
        self.isCurrentUser = isCurrentUser
        self.currentStreakStart = nil
        self.joinedAt = joinedAt
    }

    static let currentUserEmojis = ["🧑", "👤", "🧑‍💻", "🧑‍🎓"]
    static let memberEmojis = ["👩", "👨", "👦", "👧", "👴", "👵", "🧒", "👶"]

    static var defaultEmojis: [String] {
        currentUserEmojis + memberEmojis
    }
}

// MARK: - Family Consistency Data

struct FamilyConsistencyData: Codable {
    let memberId: UUID
    let month: Int
    let year: Int
    let takenDays: Int
    let expectedDays: Int

    var score: Double {
        guard expectedDays > 0 else { return 0 }
        return Double(takenDays) / Double(expectedDays)
    }
}

// MARK: - Family Invite Code

struct FamilyInviteCode: Codable {
    let code: String
    let createdBy: UUID
    let createdAt: Date
    let expiresAt: Date

    var isExpired: Bool {
        Date() > expiresAt
    }
}
