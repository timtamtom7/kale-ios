import XCTest
@testable import Kale

final class KaleTests: XCTestCase {
    func testVitaminModel() {
        let vitamin = Vitamin(name: "Vitamin D", dosage: "2000 IU")
        XCTAssertEqual(vitamin.name, "Vitamin D")
        XCTAssertEqual(vitamin.dosage, "2000 IU")
        XCTAssertEqual(vitamin.pillEmoji, "💊")
    }

    func testDailyLogDateKey() {
        let log = DailyLog(vitaminId: 1, date: Date(), taken: true)
        XCTAssertFalse(log.dateKey.isEmpty)
    }
}
