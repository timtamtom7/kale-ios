import Foundation
import SQLite

final class DatabaseService: ObservableObject {
    static let shared = DatabaseService()

    private var db: Connection?

    // Tables
    private let vitamins = Table("vitamins")
    private let dailyLogs = Table("daily_logs")

    // Vitamin columns
    private let id = SQLite.Expression<Int64>("id")
    private let name = SQLite.Expression<String>("name")
    private let dosage = SQLite.Expression<String>("dosage")
    private let barcode = SQLite.Expression<String?>("barcode")
    private let pillEmoji = SQLite.Expression<String>("pill_emoji")
    private let reminderTime = SQLite.Expression<Date>("reminder_time")
    private let createdAt = SQLite.Expression<Date>("created_at")
    private let stockCount = SQLite.Expression<Int?>("stock_count")
    private let dailyDose = SQLite.Expression<Int>("daily_dose")

    // DailyLog columns
    private let logId = SQLite.Expression<Int64>("id")
    private let vitaminId = SQLite.Expression<Int64>("vitamin_id")
    private let dateKey = SQLite.Expression<String>("date_key")
    private let taken = SQLite.Expression<Bool>("taken")
    private let takenAt = SQLite.Expression<Date?>("taken_at")

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
            print("Database setup error: \(error)")
        }
    }

    private func createTables() throws {
        try db?.run(vitamins.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(name)
            t.column(dosage)
            t.column(barcode)
            t.column(pillEmoji)
            t.column(reminderTime)
            t.column(createdAt)
            t.column(stockCount)
            t.column(dailyDose, defaultValue: 1)
        })

        try db?.run(dailyLogs.create(ifNotExists: true) { t in
            t.column(logId, primaryKey: .autoincrement)
            t.column(vitaminId)
            t.column(dateKey)
            t.column(taken)
            t.column(takenAt)
        })

        // Index for fast lookups
        try db?.run(dailyLogs.createIndex(vitaminId, dateKey, ifNotExists: true))
    }

    // MARK: - Vitamin CRUD

    func insertVitamin(_ vitamin: Vitamin) throws -> Int64 {
        guard let db = db else { throw DatabaseError.connectionFailed }

        let insert = vitamins.insert(
            name <- vitamin.name,
            dosage <- vitamin.dosage,
            barcode <- vitamin.barcode,
            pillEmoji <- vitamin.pillEmoji,
            reminderTime <- vitamin.reminderTime,
            createdAt <- vitamin.createdAt,
            stockCount <- vitamin.stockCount,
            dailyDose <- vitamin.dailyDose
        )
        return try db.run(insert)
    }

    func fetchAllVitamins() throws -> [Vitamin] {
        guard let db = db else { throw DatabaseError.connectionFailed }

        var result: [Vitamin] = []
        for row in try db.prepare(vitamins.order(createdAt.desc)) {
            let v = Vitamin(
                id: row[id],
                name: row[name],
                dosage: row[dosage],
                barcode: row[barcode],
                pillEmoji: row[pillEmoji],
                reminderTime: row[reminderTime],
                createdAt: row[createdAt],
                stockCount: row[stockCount],
                dailyDose: row[dailyDose]
            )
            result.append(v)
        }
        return result
    }

    func deleteVitamin(id vitaminId: Int64) throws {
        guard let db = db else { throw DatabaseError.connectionFailed }
        let vitamin = vitamins.filter(id == vitaminId)
        try db.run(vitamin.delete())
    }

    func updateVitamin(_ vitamin: Vitamin) throws {
        guard let db = db, let vid = vitamin.id else { throw DatabaseError.connectionFailed }
        let row = vitamins.filter(id == vid)
        try db.run(row.update(
            name <- vitamin.name,
            dosage <- vitamin.dosage,
            pillEmoji <- vitamin.pillEmoji,
            reminderTime <- vitamin.reminderTime,
            stockCount <- vitamin.stockCount,
            dailyDose <- vitamin.dailyDose
        ))
    }

    // MARK: - Daily Log CRUD

    func logTaken(vitaminId vid: Int64, date: Date, taken isTaken: Bool) throws {
        guard let db = db else { throw DatabaseError.connectionFailed }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: date)

        let existing = dailyLogs.filter(vitaminId == vid && dateKey == key)

        if try db.pluck(existing) != nil {
            try db.run(existing.update(
                taken <- isTaken,
                takenAt <- isTaken ? Date() : nil
            ))
        } else {
            try db.run(dailyLogs.insert(
                vitaminId <- vid,
                dateKey <- key,
                taken <- isTaken,
                takenAt <- isTaken ? Date() : nil
            ))
        }
    }

    func fetchLogs(for date: Date) throws -> [DailyLog] {
        guard let db = db else { throw DatabaseError.connectionFailed }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: date)

        var result: [DailyLog] = []
        let query = dailyLogs.filter(dateKey == key)
        for row in try db.prepare(query) {
            let log = DailyLog(
                id: row[logId],
                vitaminId: row[vitaminId],
                date: date,
                taken: row[taken],
                takenAt: row[takenAt]
            )
            result.append(log)
        }
        return result
    }

    func fetchLogs(forMonth date: Date) throws -> [String: [DailyLog]] {
        guard let db = db else { throw DatabaseError.connectionFailed }

        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let startKey = formatter.string(from: startOfMonth)
        let endKey = formatter.string(from: endOfMonth)

        var result: [String: [DailyLog]] = [:]
        let query = dailyLogs.filter(dateKey >= startKey && dateKey <= endKey)

        for row in try db.prepare(query) {
            guard let logDate = formatter.date(from: row[dateKey]) else { continue }
            let log = DailyLog(
                id: row[logId],
                vitaminId: row[vitaminId],
                date: logDate,
                taken: row[taken],
                takenAt: row[takenAt]
            )
            result[row[dateKey], default: []].append(log)
        }
        return result
    }

    func isVitaminTaken(vitaminId vid: Int64, on date: Date) throws -> Bool {
        guard let db = db else { throw DatabaseError.connectionFailed }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: date)

        let query = dailyLogs.filter(vitaminId == vid && dateKey == key)
        if let row = try db.pluck(query) {
            return row[taken]
        }
        return false
    }

    func getConsistencyScore(forMonth date: Date) throws -> Double {
        guard let db = db else { throw DatabaseError.connectionFailed }

        let allVitamins = try fetchAllVitamins()
        if allVitamins.isEmpty { return 0.0 }

        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let daysInMonth = calendar.range(of: .day, in: .month, for: date)!.count

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let startKey = formatter.string(from: startOfMonth)
        let endKey = formatter.string(from: calendar.date(byAdding: .day, value: daysInMonth - 1, to: startOfMonth)!)

        var totalExpected = 0
        var totalTaken = 0

        for dayOffset in 0..<daysInMonth {
            let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: startOfMonth)!
            let today = calendar.startOfDay(for: Date())
            if dayDate > today { break }

            let key = formatter.string(from: dayDate)
            let query = dailyLogs.filter(dateKey == key && taken == true)

            totalExpected += allVitamins.count
            totalTaken += try db.scalar(query.count)
        }

        guard totalExpected > 0 else { return 0.0 }
        return Double(totalTaken) / Double(totalExpected)
    }

    func getDayStatus(on date: Date) throws -> DayStatus {
        let allVitamins = try fetchAllVitamins()
        if allVitamins.isEmpty { return .empty }

        var takenCount = 0
        for vitamin in allVitamins {
            if let vid = vitamin.id, try isVitaminTaken(vitaminId: vid, on: date) {
                takenCount += 1
            }
        }

        if takenCount == 0 { return .none }
        if takenCount == allVitamins.count { return .complete }
        return .partial
    }

    // MARK: - Vitamin History

    func getVitaminHistory(vitaminId vid: Int64) throws -> VitaminHistory {
        guard let db = db else { throw DatabaseError.connectionFailed }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let today = Calendar.current.startOfDay(for: Date())
        var thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: today)!

        var lastTakenDate: Date?
        var daysTaken = 0
        var daysExpected = 0

        let allLogs = try db.prepare(dailyLogs.filter(vitaminId == vid).order(dateKey.desc))

        for row in allLogs {
            guard let logDate = formatter.date(from: row[dateKey]) else { continue }
            if lastTakenDate == nil && row[taken] {
                lastTakenDate = logDate
            }
            if logDate >= thirtyDaysAgo && logDate <= today {
                daysExpected += 1
                if row[taken] { daysTaken += 1 }
            }
        }

        // Total days taken ever
        var totalDaysTaken = 0
        for row in try db.prepare(dailyLogs.filter(vitaminId == vid && taken == true)) {
            totalDaysTaken += 1
        }

        let consistency: Double = daysExpected > 0 ? Double(daysTaken) / Double(daysExpected) : 0.0

        return VitaminHistory(
            vitaminId: vid,
            lastTakenDate: lastTakenDate,
            consistency30Days: consistency,
            totalDaysTaken: totalDaysTaken
        )
    }

    func getLowStockVitamins() throws -> [Vitamin] {
        let allVitamins = try fetchAllVitamins()
        return allVitamins.filter { vitamin in
            guard let stock = vitamin.stockCount, stock > 0 else { return false }
            let estimatedDays = stock / max(vitamin.dailyDose, 1)
            return estimatedDays <= 7
        }
    }

    func decrementStock(for vitamin: Vitamin) throws {
        guard let vid = vitamin.id, var stock = vitamin.stockCount else { return }
        stock = max(0, stock - vitamin.dailyDose)
        let updated = Vitamin(
            id: vitamin.id,
            name: vitamin.name,
            dosage: vitamin.dosage,
            barcode: vitamin.barcode,
            pillEmoji: vitamin.pillEmoji,
            reminderTime: vitamin.reminderTime,
            createdAt: vitamin.createdAt,
            stockCount: stock,
            dailyDose: vitamin.dailyDose
        )
        try updateVitamin(updated)
    }

    func updateStock(for vitamin: Vitamin, count: Int) throws {
        guard let vid = vitamin.id else { return }
        let updated = Vitamin(
            id: vitamin.id,
            name: vitamin.name,
            dosage: vitamin.dosage,
            barcode: vitamin.barcode,
            pillEmoji: vitamin.pillEmoji,
            reminderTime: vitamin.reminderTime,
            createdAt: vitamin.createdAt,
            stockCount: count,
            dailyDose: vitamin.dailyDose
        )
        try updateVitamin(updated)
    }
}

struct VitaminHistory {
    var vitaminId: Int64
    var lastTakenDate: Date?
    var consistency30Days: Double
    var totalDaysTaken: Int
}

enum DayStatus {
    case empty, none, partial, complete
}

enum DatabaseError: Error {
    case connectionFailed
}
