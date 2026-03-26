import Foundation

// MARK: - Kale R12-R20: Smart Home, Pharmacy, Ecosystem

struct SmartHomeIntegration: Identifiable, Codable, Equatable {
    let id: UUID
    var deviceName: String
    var deviceType: DeviceType
    var isConnected: Bool
    var lastSyncAt: Date?
    
    enum DeviceType: String, Codable {
        case amazonEcho = "Amazon Echo"
        case googleHome = "Google Home"
        case appleHomePod = "Apple HomePod"
        case samsungSmartThings = "Samsung SmartThings"
        case philipsHue = "Philips Hue"
        case smartLock = "Smart Lock"
        case thermostat = "Smart Thermostat"
    }
    
    init(id: UUID = UUID(), deviceName: String, deviceType: DeviceType, isConnected: Bool = false, lastSyncAt: Date? = nil) {
        self.id = id
        self.deviceName = deviceName
        self.deviceType = deviceType
        self.isConnected = isConnected
        self.lastSyncAt = lastSyncAt
    }
}

struct PharmacyIntegration: Identifiable, Codable, Equatable {
    let id: UUID
    var pharmacyName: String
    var pharmacyID: String
    var isConnected: Bool
    var autoRefillEnabled: Bool
    var lastSyncAt: Date?
    
    init(id: UUID = UUID(), pharmacyName: String, pharmacyID: String = "", isConnected: Bool = false, autoRefillEnabled: Bool = false, lastSyncAt: Date? = nil) {
        self.id = id
        self.pharmacyName = pharmacyName
        self.pharmacyID = pharmacyID
        self.isConnected = isConnected
        self.autoRefillEnabled = autoRefillEnabled
        self.lastSyncAt = lastSyncAt
    }
}

struct AutoRefill: Identifiable, Codable, Equatable {
    let id: UUID
    var supplementID: UUID
    var pharmacyID: UUID
    var refillDate: Date
    var status: Status
    var daysSupply: Int
    
    enum Status: String, Codable {
        case pending, processing, ready, pickedUp, cancelled
    }
    
    init(id: UUID = UUID(), supplementID: UUID, pharmacyID: UUID, refillDate: Date, status: Status = .pending, daysSupply: Int = 30) {
        self.id = id
        self.supplementID = supplementID
        self.pharmacyID = pharmacyID
        self.refillDate = refillDate
        self.status = status
        self.daysSupply = daysSupply
    }
}

struct KaleSubscriptionTier: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var displayName: String
    var monthlyPrice: Decimal
    var annualPrice: Decimal
    var lifetimePrice: Decimal
    var features: [String]
    var isMostPopular: Bool
    
    static let free = KaleSubscriptionTier(id: UUID(), name: "free", displayName: "Free", monthlyPrice: 0, annualPrice: 0, lifetimePrice: 0, features: ["Basic tracking", "5 supplements", "Simple reminders"], isMostPopular: false)
    static let premium = KaleSubscriptionTier(id: UUID(), name: "premium", displayName: "Premium", monthlyPrice: 6.99, annualPrice: 69.99, lifetimePrice: 129, features: ["Unlimited supplements", "Smart home", "Auto-refill", "Analytics"], isMostPopular: true)
    static let family = KaleSubscriptionTier(id: UUID(), name: "family", displayName: "Family", monthlyPrice: 11.99, annualPrice: 119.99, lifetimePrice: 0, features: ["Up to 6 members", "Shared library", "Auto-refill", "Priority support"], isMostPopular: false)
}

struct SupportedLocale: Identifiable, Codable, Equatable {
    let id: UUID
    var code: String
    var displayName: String
    
    static let supported: [SupportedLocale] = [
        SupportedLocale(id: UUID(), code: "en", displayName: "English"),
        SupportedLocale(id: UUID(), code: "es", displayName: "Spanish"),
        SupportedLocale(id: UUID(), code: "fr", displayName: "French"),
        SupportedLocale(id: UUID(), code: "de", displayName: "German"),
    ]
}

struct CrossPlatformDevice: Identifiable, Codable, Equatable {
    let id: UUID
    var deviceName: String
    var platform: Platform
    
    enum Platform: String, Codable { case ios, android, web }
    
    init(id: UUID = UUID(), deviceName: String, platform: Platform) {
        self.id = id
        self.deviceName = deviceName
        self.platform = platform
    }
}

struct TeamMember: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var role: String
    var email: String
    
    init(id: UUID = UUID(), name: String, role: String, email: String) {
        self.id = id
        self.name = name
        self.role = role
        self.email = email
    }
}

struct AwardSubmission: Identifiable, Codable, Equatable {
    let id: UUID
    var awardName: String
    var category: String
    var status: Status
    
    enum Status: String, Codable { case draft, submitted, inReview, won, rejected }
    
    init(id: UUID = UUID(), awardName: String, category: String, status: Status = .draft) {
        self.id = id
        self.awardName = awardName
        self.category = category
        self.status = status
    }
}

struct PlatformIntegration: Identifiable, Codable, Equatable {
    let id: UUID
    var platform: String
    var isEnabled: Bool
    
    init(id: UUID = UUID(), platform: String, isEnabled: Bool = false) {
        self.id = id
        self.platform = platform
        self.isEnabled = isEnabled
    }
}

struct KaleAPI: Codable, Equatable {
    var clientID: String
    var tier: APITier
    
    enum APITier: String, Codable { case free, paid }
    
    init(clientID: String = UUID().uuidString, tier: APITier = .free) {
        self.clientID = clientID
        self.tier = tier
    }
}
