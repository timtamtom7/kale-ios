import Foundation

struct Vitamin: Identifiable, Codable, Equatable {
    var id: Int64?
    var name: String
    var dosage: String
    var barcode: String?
    var pillEmoji: String
    var reminderTime: Date
    var createdAt: Date
    var stockCount: Int?      // remaining capsules/pills (nil = not tracking)
    var dailyDose: Int        // capsules per day (default 1)

    init(id: Int64? = nil, name: String, dosage: String, barcode: String? = nil, pillEmoji: String = "💊", reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date(), createdAt: Date = Date(), stockCount: Int? = nil, dailyDose: Int = 1) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.barcode = barcode
        self.pillEmoji = pillEmoji
        self.reminderTime = reminderTime
        self.createdAt = createdAt
        self.stockCount = stockCount
        self.dailyDose = dailyDose
    }
}
