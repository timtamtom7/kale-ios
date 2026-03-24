import Foundation
import AVFoundation
import Vision

struct BarcodeEntry: Codable {
    let barcode: String
    let name: String
    let dosage: String
}

final class BarcodeService: ObservableObject {
    static let shared = BarcodeService()

    @Published var barcodeDatabase: [String: BarcodeEntry] = [:]

    private init() {
        loadDatabase()
    }

    private func loadDatabase() {
        guard let url = Bundle.main.url(forResource: "BarcodeDatabase", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return
        }

        let decoder = JSONDecoder()
        if let entries = try? decoder.decode([BarcodeEntry].self, from: data) {
            for entry in entries {
                barcodeDatabase[entry.barcode] = entry
            }
        }
    }

    func lookup(barcode: String) -> BarcodeEntry? {
        return barcodeDatabase[barcode]
    }
}
