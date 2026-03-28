import Foundation

struct DriverProfile: Codable {
    // Truck Selection Mode
    var useCustomTruck: Bool = false

    // Predefined Truck (from database)
    var selectedTruckSpecId: String?
    var truckYear: Int

    // Custom Truck (user-entered)
    var customTruck: CustomTruck?

    // Legacy fields for backwards compatibility
    var truckType: TruckType

    // Configuration
    var configuration: TruckConfiguration
    var trailerType: TrailerType?

    // Custom MPG override
    var useCustomMPG: Bool = false
    var customMPGValue: Double?

    // Computed base MPG based on selection (or custom override)
    var baseMPG: Double {
        // If custom MPG is set, use it
        if useCustomMPG, let customMPG = customMPGValue {
            return max(4.0, customMPG) // Enforce minimum 4.0 MPG
        }

        let truckBaseMPG: Double

        if useCustomTruck, let custom = customTruck {
            truckBaseMPG = custom.baseMPG
        } else if let specId = selectedTruckSpecId, let spec = TruckDatabase.spec(id: specId) {
            truckBaseMPG = spec.baseMPG
        } else {
            // Fallback to legacy calculation
            truckBaseMPG = 7.0
        }

        // Adjust for trailer if bobtail only (better MPG without trailer)
        if configuration == .bobtailOnly {
            return truckBaseMPG + 2.0  // ~2 MPG better without trailer
        }

        // Adjust for trailer type (research-based values)
        // Source: Hale Trailer, Cargostore, TruckersReport forums
        guard let trailer = trailerType else { return truckBaseMPG }
        switch trailer {
        case .dryvan:
            // Baseline - most common trailer type
            return truckBaseMPG
        case .reefer:
            // Refrigeration unit burns 0.5-1.0 gal/hr extra
            // Over 500mi trip (~10hrs) = 5-10 extra gallons = ~1.0 MPG penalty
            return truckBaseMPG - 1.0
        case .flatbed:
            // Less aerodynamic drag than enclosed box trailer
            // Drivers report ~0.3-0.5 MPG better than dry van
            return truckBaseMPG + 0.4
        case .tanker:
            // Cylindrical shape = 5-10% better aerodynamics than box
            // But heavier construction offsets some gains
            return truckBaseMPG + 0.2
        }
    }

    // Estimated empty weight based on selection
    var estimatedEmptyWeight: Double {
        let truckWeight: Double

        if useCustomTruck, let custom = customTruck {
            truckWeight = custom.emptyWeight
        } else if let specId = selectedTruckSpecId, let spec = TruckDatabase.spec(id: specId) {
            truckWeight = spec.emptyWeight
        } else {
            // Fallback to legacy calculation
            switch truckType {
            case .dayCab:
                truckWeight = 16000
            case .sleeperCab:
                truckWeight = 20000
            case .caboover:
                truckWeight = 15000
            }
        }

        guard configuration == .bobtailWithTrailer, let trailer = trailerType else {
            return truckWeight
        }

        let trailerWeight: Double
        switch trailer {
        case .dryvan:
            trailerWeight = 14000
        case .reefer:
            trailerWeight = 16000
        case .flatbed:
            trailerWeight = 12000
        case .tanker:
            trailerWeight = 15000
        }

        return truckWeight + trailerWeight
    }

    // Display name for the truck
    var truckDisplayName: String {
        if useCustomTruck, let custom = customTruck {
            return "\(custom.makeName) \(custom.modelName)"
        } else if let specId = selectedTruckSpecId, let spec = TruckDatabase.spec(id: specId) {
            return spec.displayName
        }
        return truckType.rawValue
    }

    static var `default`: DriverProfile {
        DriverProfile(
            useCustomTruck: false,
            selectedTruckSpecId: nil,
            truckYear: 2020,
            customTruck: nil,
            truckType: .sleeperCab,
            configuration: .bobtailWithTrailer,
            trailerType: .dryvan
        )
    }

    // Initialize from a TruckSpec
    static func fromSpec(_ spec: TruckSpec, year: Int, configuration: TruckConfiguration, trailerType: TrailerType?) -> DriverProfile {
        DriverProfile(
            useCustomTruck: false,
            selectedTruckSpecId: spec.id,
            truckYear: year,
            customTruck: nil,
            truckType: spec.type,
            configuration: configuration,
            trailerType: trailerType
        )
    }

    // Initialize from custom truck
    static func fromCustom(_ custom: CustomTruck, year: Int, configuration: TruckConfiguration, trailerType: TrailerType?) -> DriverProfile {
        DriverProfile(
            useCustomTruck: true,
            selectedTruckSpecId: nil,
            truckYear: year,
            customTruck: custom,
            truckType: custom.type,
            configuration: configuration,
            trailerType: trailerType
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
