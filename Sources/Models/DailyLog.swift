import Foundation

struct DailyLog: Identifiable {
    var id: Int64?
    var vitaminId: Int64
    var date: Date
    var taken: Bool
    var takenAt: Date?

    var dateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
