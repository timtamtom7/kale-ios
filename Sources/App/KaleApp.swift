import SwiftUI

@main
struct KaleApp: App {
    @StateObject private var databaseService = DatabaseService.shared
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var calendarService = CalendarService.shared
    @StateObject private var familyService = FamilyService.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var healthInsightsService = HealthInsightsService.shared
    @StateObject private var communityService = CommunityService.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(databaseService)
                    .environmentObject(notificationService)
                    .environmentObject(calendarService)
                    .environmentObject(familyService)
                    .environmentObject(subscriptionManager)
                    .environmentObject(healthInsightsService)
                    .environmentObject(communityService)
            } else {
                OnboardingView(onComplete: {
                    hasCompletedOnboarding = true
                })
                .environmentObject(databaseService)
                .environmentObject(notificationService)
                .environmentObject(calendarService)
                .environmentObject(familyService)
                .environmentObject(subscriptionManager)
                .environmentObject(healthInsightsService)
                .environmentObject(communityService)
            }
        }
    }
}

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var subscriptionManager: SubscriptionManager

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

            HealthInsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)

            CommunityView()
                .tabItem {
                    Label("Community", systemImage: "person.3.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(Color.accentGreen)
    }
}

#Preview {
    MainTabView()
        .environmentObject(DatabaseService.shared)
        .environmentObject(NotificationService.shared)
}
