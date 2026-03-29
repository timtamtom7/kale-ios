import Foundation

// MARK: - Delivery Service

enum DeliveryService: String, CaseIterable, Identifiable {
    case instacart = "Instacart"
    case amazonFresh = "Amazon Fresh"
    case walmart = "Walmart"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .instacart: return "cart.fill"
        case .amazonFresh: return "shippingbox.fill"
        case .walmart: return "building.2.fill"
        }
    }

    var url: URL? {
        switch self {
        case .instacart: return URL(string: "https://www.instacart.com")
        case .amazonFresh: return URL(string: "https://www.amazon.com/fresh")
        case .walmart: return URL(string: "https://www.walmart.com/grocery")
        }
    }
}

// MARK: - GroceryItem extension for delivery

extension GroceryItem {
    var deliveryDescription: String {
        "\(quantity) \(unit) \(name)"
    }
}

// MARK: - Order

struct Order: Identifiable, Codable {
    let id: UUID
    let service: DeliveryService
    let items: [GroceryItem]
    let store: String
    let estimatedTotal: Double
    let status: OrderStatus
    let createdAt: Date
    var estimatedDelivery: Date?

    init(id: UUID = UUID(), service: DeliveryService, items: [GroceryItem], store: String, estimatedTotal: Double, status: OrderStatus = .pending, createdAt: Date = Date(), estimatedDelivery: Date? = nil) {
        self.id = id
        self.service = service
        self.items = items
        self.store = store
        self.estimatedTotal = estimatedTotal
        self.status = status
        self.createdAt = createdAt
        self.estimatedDelivery = estimatedDelivery
    }
}

enum OrderStatus: String, Codable {
    case pending = "Pending"
    case confirmed = "Confirmed"
    case preparing = "Preparing"
    case outForDelivery = "Out for Delivery"
    case delivered = "Delivered"
    case cancelled = "Cancelled"

    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .confirmed: return "checkmark.circle.fill"
        case .preparing: return "bag.fill"
        case .outForDelivery: return "car.fill"
        case .delivered: return "house.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
}

// MARK: - Store

struct GroceryStore: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let service: DeliveryService
    let address: String
    let deliveryFee: Double
    let minOrder: Double
    var isPreferred: Bool

    init(id: UUID = UUID(), name: String, service: DeliveryService, address: String = "", deliveryFee: Double = 0, minOrder: Double = 0, isPreferred: Bool = false) {
        self.id = id
        self.name = name
        self.service = service
        self.address = address
        self.deliveryFee = deliveryFee
        self.minOrder = minOrder
        self.isPreferred = isPreferred
    }
}

// MARK: - Price Quote

struct PriceQuote: Identifiable {
    let id: UUID
    let store: GroceryStore
    let items: [GroceryItem]
    let subtotal: Double
    let deliveryFee: Double
    let serviceFee: Double
    let estimatedTotal: Double

    init(id: UUID = UUID(), store: GroceryStore, items: [GroceryItem], subtotal: Double, deliveryFee: Double, serviceFee: Double) {
        self.id = id
        self.store = store
        self.items = items
        self.subtotal = subtotal
        self.deliveryFee = deliveryFee
        self.serviceFee = serviceFee
        self.estimatedTotal = subtotal + deliveryFee + serviceFee
    }
}

// MARK: - Grocery Delivery Service

final class GroceryDeliveryService {
    static let shared = GroceryDeliveryService()

    private init() {}

    /// Export grocery list items formatted for a specific delivery service
    func exportGroceryList(to service: DeliveryService) -> [GroceryItem] {
        // Return items that are checked/needed for ordering
        return []
    }

    /// Create an order for delivery from the selected store
    func orderGroceries(items: [GroceryItem], from store: String) -> Order {
        let service: DeliveryService = detectService(from: store)
        let estimatedTotal = items.reduce(0) { $0 + Double.random(in: 2...15) }

        return Order(
            service: service,
            items: items,
            store: store,
            estimatedTotal: estimatedTotal,
            status: .pending,
            estimatedDelivery: Calendar.current.date(byAdding: .hour, value: 2, to: Date())
        )
    }

    /// Get price quotes from available stores for the given items
    func getPriceQuotes(for items: [GroceryItem], from services: [DeliveryService] = DeliveryService.allCases) -> [PriceQuote] {
        return services.map { service in
            let mockStore = GroceryStore(
                name: service.rawValue,
                service: service,
                deliveryFee: service == .walmart ? 0 : 3.99,
                minOrder: 30,
                isPreferred: false
            )
            let subtotal = items.reduce(0) { $0 + Double.random(in: 1.5...12) }
            let serviceFee = subtotal * 0.05
            return PriceQuote(
                store: mockStore,
                items: items,
                subtotal: subtotal,
                deliveryFee: mockStore.deliveryFee,
                serviceFee: serviceFee
            )
        }.sorted { $0.estimatedTotal < $1.estimatedTotal }
    }

    /// Open the delivery service website to place the order
    func openStoreFront(for service: DeliveryService, items: [GroceryItem]) {
        guard let baseURL = service.url else { return }

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        if !items.isEmpty {
            let searchTerms = items.prefix(5).map { $0.name }.joined(separator: "+")
            components?.queryItems = [URLQueryItem(name: "search", value: searchTerms)]
        }

        if let url = components?.url {
            NSWorkspace.shared.open(url)
        }
    }

    /// Generate shareable text for grocery list
    func generateShareableText(for items: [GroceryItem], as service: DeliveryService) -> String {
        let header = "🛒 Grocery List for \(service.rawValue)"
        let itemList = items.map { "• \($0.quantity) \($0.unit) \($0.name)" }.joined(separator: "\n")
        return "\(header)\n\n\(itemList)\n\nSent from KaleMac 🍏"
    }

    // MARK: - Private

    private func detectService(from storeName: String) -> DeliveryService {
        let lower = storeName.lowercased()
        if lower.contains("instacart") { return .instacart }
        if lower.contains("amazon") || lower.contains("fresh") { return .amazonFresh }
        if lower.contains("walmart") { return .walmart }
        return .instacart
    }
}
