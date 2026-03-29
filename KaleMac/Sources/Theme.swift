import SwiftUI

enum Theme {
    static let kaleGreen = Color(hex: "4CAF50")
    static let avocado = Color(hex: "9ABC66")
    static let cream = Color(hex: "F5F5DC")
    static let tomato = Color(hex: "E64A19")
    static let fatOrange = Color(hex: "FF9800")
    static let surface = Color(hex: "FAFAFA")
    static let cardBg = Color(hex: "FFFFFF")

    static let primaryGradient = LinearGradient(
        colors: [kaleGreen, avocado],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [tomato, Color(hex: "FF7043")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
