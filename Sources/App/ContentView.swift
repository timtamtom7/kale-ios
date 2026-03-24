import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }
                .tag(0)

            MonthlyView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(Color.accentGreen)
    }
}

#Preview {
    ContentView()
        .environmentObject(DatabaseService.shared)
        .environmentObject(NotificationService.shared)
}
