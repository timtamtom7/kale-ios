import Foundation
import Combine

final class KaleR12R20Service: ObservableObject, @unchecked Sendable {
    static let shared = KaleR12R20Service()
    
    @Published var smartHomeDevices: [SmartHomeIntegration] = []
    @Published var pharmacyIntegrations: [PharmacyIntegration] = []
    @Published var autoRefills: [AutoRefill] = []
    @Published var currentTier: KaleSubscriptionTier = .free
    @Published var crossPlatformDevices: [CrossPlatformDevice] = []
    @Published var awardSubmissions: [AwardSubmission] = []
    @Published var apiCredentials: KaleAPI?
    
    private let userDefaults = UserDefaults.standard
    
    private init() { loadFromDisk() }
    
    func connectSmartHome(name: String, type: SmartHomeIntegration.DeviceType) -> SmartHomeIntegration {
        let device = SmartHomeIntegration(deviceName: name, deviceType: type, isConnected: true, lastSyncAt: Date())
        smartHomeDevices.append(device)
        saveToDisk()
        return device
    }
    
    func connectPharmacy(name: String) -> PharmacyIntegration {
        let pharmacy = PharmacyIntegration(pharmacyName: name, isConnected: true)
        pharmacyIntegrations.append(pharmacy)
        saveToDisk()
        return pharmacy
    }
    
    func createAutoRefill(supplementID: UUID, pharmacyID: UUID) -> AutoRefill {
        let refill = AutoRefill(supplementID: supplementID, pharmacyID: pharmacyID, refillDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date())
        autoRefills.append(refill)
        saveToDisk()
        return refill
    }
    
    func subscribe(to tier: KaleSubscriptionTier) async -> Bool {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run { currentTier = tier; saveToDisk() }
        return true
    }
    
    func registerDevice(name: String, platform: CrossPlatformDevice.Platform) -> CrossPlatformDevice {
        let device = CrossPlatformDevice(deviceName: name, platform: platform)
        crossPlatformDevices.append(device)
        saveToDisk()
        return device
    }
    
    func submitAward(name: String, category: String) -> AwardSubmission {
        let award = AwardSubmission(awardName: name, category: category)
        awardSubmissions.append(award)
        saveToDisk()
        return award
    }
    
    private func saveToDisk() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(smartHomeDevices) { userDefaults.set(data, forKey: "kale_smart_home") }
        if let data = try? encoder.encode(pharmacyIntegrations) { userDefaults.set(data, forKey: "kale_pharmacies") }
        if let data = try? encoder.encode(autoRefills) { userDefaults.set(data, forKey: "kale_refills") }
        if let data = try? encoder.encode(crossPlatformDevices) { userDefaults.set(data, forKey: "kale_devices") }
        if let data = try? encoder.encode(awardSubmissions) { userDefaults.set(data, forKey: "kale_awards") }
    }
    
    private func loadFromDisk() {
        let decoder = JSONDecoder()
        if let data = userDefaults.data(forKey: "kale_smart_home"),
           let decoded = try? decoder.decode([SmartHomeIntegration].self, from: data) { smartHomeDevices = decoded }
        if let data = userDefaults.data(forKey: "kale_pharmacies"),
           let decoded = try? decoder.decode([PharmacyIntegration].self, from: data) { pharmacyIntegrations = decoded }
        if let data = userDefaults.data(forKey: "kale_refills"),
           let decoded = try? decoder.decode([AutoRefill].self, from: data) { autoRefills = decoded }
        if let data = userDefaults.data(forKey: "kale_devices"),
           let decoded = try? decoder.decode([CrossPlatformDevice].self, from: data) { crossPlatformDevices = decoded }
        if let data = userDefaults.data(forKey: "kale_awards"),
           let decoded = try? decoder.decode([AwardSubmission].self, from: data) { awardSubmissions = decoded }
    }
}
