import SwiftUI

@main
struct KaleApp: App {
    @StateObject private var databaseService = DatabaseService.shared
    @StateObject private var notificationService = NotificationService.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(databaseService)
                    .environmentObject(notificationService)
            } else {
                OnboardingView(onComplete: {
                    hasCompletedOnboarding = true
                })
                .environmentObject(databaseService)
                .environmentObject(notificationService)
            }
        }
    }
}

import SwiftUI

struct MainTabView: View {
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
    MainTabView()
        .environmentObject(DatabaseService.shared)
        .environmentObject(NotificationService.shared)
}
