import Cocoa
import SwiftUI

@main
struct KaleMacApp: App {
    var body: some Scene {
        WindowGroup {
            MacKaleView()
                .frame(minWidth: 800, minHeight: 600)
                .darkMode()
        }
    }
}

extension View {
    func darkMode() -> some View {
        self.preferredColorScheme(.dark)
    }
}
