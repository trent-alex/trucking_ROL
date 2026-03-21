import Foundation

struct DriverProfile: Codable {
    // Truck Info
    var truckType: TruckType
    var truckYear: Int

    // Configuration
    var configuration: TruckConfiguration
    var trailerType: TrailerType?

    // Computed base MPG based on configuration
    var baseMPG: Double {
        switch configuration {
        case .bobtailOnly:
            return 12.0  // No trailer drag
        case .bobtailWithTrailer:
            guard let trailer = trailerType else { return 7.0 }
            switch trailer {
            case .dryvan:
                return 7.0  // Standard enclosed trailer
            case .reefer:
                return 6.0  // Reefer unit consumes additional fuel
            case .flatbed:
                return 7.5  // Less aerodynamic drag than enclosed
            case .tanker:
                return 6.5  // Heavy and less aerodynamic
            }
        }
    }

    // Estimated empty weight based on configuration
    var estimatedEmptyWeight: Double {
        let truckWeight: Double
        switch truckType {
        case .dayCab:
            truckWeight = 16000
        case .sleeperCab:
            truckWeight = 20000
        case .caboover:
            truckWeight = 15000
        }

        guard configuration == .bobtailWithTrailer, let trailer = trailerType else {
            return truckWeight
        }

        let trailerWeight: Double
        switch trailer {
        case .dryvan:
            trailerWeight = 14000
        case .reefer:
            trailerWeight = 16000  // Heavier due to refrigeration unit
        case .flatbed:
            trailerWeight = 12000
        case .tanker:
            trailerWeight = 15000
        }

        return truckWeight + trailerWeight
    }

    static var `default`: DriverProfile {
        DriverProfile(
            truckType: .sleeperCab,
            truckYear: 2020,
            configuration: .bobtailWithTrailer,
            trailerType: .dryvan
        )
    }
}

enum TruckType: String, Codable, CaseIterable, Identifiable {
    case dayCab = "Day Cab"
    case sleeperCab = "Sleeper Cab"
    case caboover = "Cabover (COE)"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .dayCab:
            return "No sleeper, local/regional hauls"
        case .sleeperCab:
            return "Long-haul with sleeping quarters"
        case .caboover:
            return "Cab over engine, compact design"
        }
    }
}

enum TruckConfiguration: String, Codable, CaseIterable, Identifiable {
    case bobtailOnly = "Bobtail Only"
    case bobtailWithTrailer = "Bobtail + Trailer"

    var id: String { rawValue }
}

enum TrailerType: String, Codable, CaseIterable, Identifiable {
    case dryvan = "Dry Van"
    case reefer = "Reefer"
    case flatbed = "Flatbed"
    case tanker = "Tanker"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .dryvan:
            return "Standard enclosed trailer"
        case .reefer:
            return "Refrigerated trailer"
        case .flatbed:
            return "Open platform trailer"
        case .tanker:
            return "Liquid/bulk transport"
        }
    }

    var icon: String {
        switch self {
        case .dryvan: return "shippingbox.fill"
        case .reefer: return "snowflake"
        case .flatbed: return "rectangle.split.3x1"
        case .tanker: return "drop.fill"
        }
    }
}

// MARK: - Persistence

extension DriverProfile {
    private static let storageKey = "driverProfile"
    private static let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    static func load() -> DriverProfile? {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let profile = try? JSONDecoder().decode(DriverProfile.self, from: data) else {
            return nil
        }
        return profile
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
            UserDefaults.standard.set(true, forKey: Self.hasCompletedOnboardingKey)
        }
    }

    static var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
    }

    static func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        UserDefaults.standard.removeObject(forKey: hasCompletedOnboardingKey)
    }
}
