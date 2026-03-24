import Foundation
import SQLite

// MARK: - Family Service

final class FamilyService: ObservableObject {
    static let shared = FamilyService()

    private var db: Connection?

    // Tables
    private let familyMembers = Table("family_members")
    private let familyConsistency = Table("family_consistency")

    // FamilyMember columns
    private let memberId = SQLite.Expression<String>("id")
    private let memberName = SQLite.Expression<String>("name")
    private let memberEmoji = SQLite.Expression<String>("emoji")
    private let memberIsCurrentUser = SQLite.Expression<Bool>("is_current_user")
    private let memberJoinedAt = SQLite.Expression<Date>("joined_at")
    private let memberStreak = SQLite.Expression<Int>("streak")
    private let memberConsistencyScore = SQLite.Expression<Double>("consistency_score")

    // Consistency columns
    private let consistencyId = SQLite.Expression<Int64>("id")
    private let consistencyMemberId = SQLite.Expression<String>("member_id")
    private let consistencyMonth = SQLite.Expression<Int>("month")
    private let consistencyYear = SQLite.Expression<Int>("year")
    private let consistencyTakenDays = SQLite.Expression<Int>("taken_days")
    private let consistencyExpectedDays = SQLite.Expression<Int>("expected_days")

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let dbPath = documentsPath.appendingPathComponent("kale.sqlite3").path
            db = try Connection(dbPath)
            try createTables()
        } catch {
            print("FamilyService DB error: \(error)")
        }
    }

    private func createTables() throws {
        try db?.run(familyMembers.create(ifNotExists: true) { t in
            t.column(memberId, primaryKey: true)
            t.column(memberName)
            t.column(memberEmoji)
            t.column(memberIsCurrentUser)
            t.column(memberJoinedAt)
            t.column(memberStreak, defaultValue: 0)
            t.column(memberConsistencyScore, defaultValue: 0)
        })

        try db?.run(familyConsistency.create(ifNotExists: true) { t in
            t.column(consistencyId, primaryKey: .autoincrement)
            t.column(consistencyMemberId)
            t.column(consistencyMonth)
            t.column(consistencyYear)
            t.column(consistencyTakenDays, defaultValue: 0)
            t.column(consistencyExpectedDays, defaultValue: 0)
        })

        try db?.run(familyConsistency.createIndex(consistencyMemberId, consistencyMonth, consistencyYear, ifNotExists: true))
    }

    // MARK: - Member CRUD

    func addMember(_ member: FamilyMember) throws {
        guard let db = db else { throw FamilyError.connectionFailed }
        let insert = familyMembers.insert(
            memberId <- member.id.uuidString,
            memberName <- member.name,
            memberEmoji <- member.emoji,
            memberIsCurrentUser <- member.isCurrentUser,
            memberJoinedAt <- member.joinedAt,
            memberStreak <- member.streak,
            memberConsistencyScore <- member.consistencyScore
        )
        try db.run(insert)
    }

    func updateMember(_ member: FamilyMember) throws {
        guard let db = db else { throw FamilyError.connectionFailed }
        let row = familyMembers.filter(memberId == member.id.uuidString)
        try db.run(row.update(
            memberName <- member.name,
            memberEmoji <- member.emoji,
            memberStreak <- member.streak,
            memberConsistencyScore <- member.consistencyScore
        ))
    }

    func removeMember(id: UUID) throws {
        guard let db = db else { throw FamilyError.connectionFailed }
        let row = familyMembers.filter(memberId == id.uuidString)
        try db.run(row.delete())
    }

    func fetchAllMembers() throws -> [FamilyMember] {
        guard let db = db else { throw FamilyError.connectionFailed }

        var members: [FamilyMember] = []
        for row in try db.prepare(familyMembers.order(memberJoinedAt.asc)) {
            let member = FamilyMember(
                id: UUID(uuidString: row[memberId]) ?? UUID(),
                name: row[memberName],
                emoji: row[memberEmoji],
                consistencyScore: row[memberConsistencyScore],
                streak: row[memberStreak],
                isCurrentUser: row[memberIsCurrentUser],
                joinedAt: row[memberJoinedAt]
            )
            members.append(member)
        }
        return members
    }

    func fetchCurrentUser() throws -> FamilyMember? {
        guard let db = db else { throw FamilyError.connectionFailed }
        let query = familyMembers.filter(memberIsCurrentUser == true)
        guard let row = try db.pluck(query) else { return nil }
        return FamilyMember(
            id: UUID(uuidString: row[memberId]) ?? UUID(),
            name: row[memberName],
            emoji: row[memberEmoji],
            consistencyScore: row[memberConsistencyScore],
            streak: row[memberStreak],
            isCurrentUser: true,
            joinedAt: row[memberJoinedAt]
        )
    }

    func ensureCurrentUser(name: String = "Me", emoji: String = "🧑") throws -> FamilyMember {
        if let existing = try fetchCurrentUser() {
            return existing
        }
        let member = FamilyMember(name: name, emoji: emoji, isCurrentUser: true)
        try addMember(member)
        return member
    }

    // MARK: - Consistency Tracking

    func updateConsistencyScore(for memberId: UUID, month: Int, year: Int, taken: Int, expected: Int) throws {
        guard let db = db else { throw FamilyError.connectionFailed }

        let query = familyConsistency.filter(
            consistencyMemberId == memberId.uuidString &&
            consistencyMonth == month &&
            consistencyYear == year
        )

        if try db.pluck(query) != nil {
            try db.run(query.update(
                consistencyTakenDays <- taken,
                consistencyExpectedDays <- expected
            ))
        } else {
            try db.run(familyConsistency.insert(
                consistencyMemberId <- memberId.uuidString,
                consistencyMonth <- month,
                consistencyYear <- year,
                consistencyTakenDays <- taken,
                consistencyExpectedDays <- expected
            ))
        }
    }

    func getConsistencyData(for memberId: UUID, month: Int, year: Int) throws -> FamilyConsistencyData? {
        guard let db = db else { throw FamilyError.connectionFailed }

        let query = familyConsistency.filter(
            consistencyMemberId == memberId.uuidString &&
            consistencyMonth == month &&
            consistencyYear == year
        )

        guard let row = try db.pluck(query) else { return nil }
        return FamilyConsistencyData(
            memberId: memberId,
            month: row[consistencyMonth],
            year: row[consistencyYear],
            takenDays: row[consistencyTakenDays],
            expectedDays: row[consistencyExpectedDays]
        )
    }

    func calculateFamilyRankings() throws -> [FamilyMember] {
        let members = try fetchAllMembers()
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)

        return members.sorted { m1, m2 in
            let score1 = (try? getConsistencyData(for: m1.id, month: month, year: year)?.score) ?? m1.consistencyScore
            let score2 = (try? getConsistencyData(for: m2.id, month: month, year: year)?.score) ?? m2.consistencyScore
            return score1 > score2
        }
    }

    // MARK: - Member Count

    func memberCount() throws -> Int {
        guard let db = db else { throw FamilyError.connectionFailed }
        return try db.scalar(familyMembers.count)
    }
}

enum FamilyError: Error {
    case connectionFailed
    case memberNotFound
    case maxMembersReached
}
