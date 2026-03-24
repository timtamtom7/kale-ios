import Foundation

// MARK: - User Subscription Manager

final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    private let userDefaults = UserDefaults.standard
    private let tierKey = "subscription_tier"

    @Published var currentTier: SubscriptionTier {
        didSet {
            userDefaults.set(currentTier.rawValue, forKey: tierKey)
        }
    }

    private init() {
        let saved = userDefaults.string(forKey: tierKey) ?? SubscriptionTier.free.rawValue
        self.currentTier = SubscriptionTier(rawValue: saved) ?? .free
    }

    func upgrade(to tier: SubscriptionTier) {
        currentTier = tier
    }

    func canAccess(_ feature: FeatureAccess) -> Bool {
        switch feature {
        case .unlimitedVitamins:
            return currentTier != .free
        case .barcodeScanning:
            return currentTier != .free
        case .smartReminders:
            return currentTier != .free
        case .monthlyReports:
            return currentTier == .complete
        case .familySharing:
            return currentTier == .complete
        case .healthInsights:
            return currentTier == .complete
        case .communityRoutines:
            return currentTier == .complete
        }
    }
}

enum FeatureAccess {
    case unlimitedVitamins
    case barcodeScanning
    case smartReminders
    case monthlyReports
    case familySharing
    case healthInsights
    case communityRoutines
}
