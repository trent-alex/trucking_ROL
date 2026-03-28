import Foundation
import CoreLocation
import MapKit

// MARK: - Load Scenario

struct LoadScenario: Identifiable, Codable {
    let id: UUID
    var loadRate: Double  // Price offered for the load
    var segments: [RouteSegment]
    var createdAt: Date

    // Lumper charges (loading/unloading fees)
    var pickupLumperCharge: Double
    var dropLumperCharges: [Double]  // One per drop location

    // Computed totals
    var totalMiles: Double {
        segments.reduce(0) { $0 + $1.distanceMiles }
    }

    var totalFuelCost: Double {
        segments.reduce(0) { $0 + $1.fuelCost }
    }

    var totalOvernightCost: Double {
        segments.reduce(0) { $0 + $1.overnightCost }
    }

    var totalLumperCharges: Double {
        pickupLumperCharge + dropLumperCharges.reduce(0, +)
    }

    var totalCost: Double {
        totalFuelCost + totalOvernightCost + totalLumperCharges
    }

    var profit: Double {
        loadRate - totalCost
    }

    var profitPerMile: Double {
        guard totalMiles > 0 else { return 0 }
        return profit / totalMiles
    }

    var revenuePerMile: Double {
        guard totalMiles > 0 else { return 0 }
        return loadRate / totalMiles
    }

    var costPerMile: Double {
        guard totalMiles > 0 else { return 0 }
        return totalCost / totalMiles
    }

    var isProfitable: Bool {
        profit > 0
    }

    // All unique states traversed across all segments
    var allStatesTraversed: [String] {
        var states: [String] = []
        for segment in segments {
            for state in segment.statesTraversed {
                if !states.contains(state) {
                    states.append(state)
                }
            }
        }
        return states
    }

    // Maximum weight in the scenario (for compliance checking)
    var maxWeight: Double {
        segments.map { $0.weightAtSegment }.max() ?? 0
    }

    init(loadRate: Double = 0, pickupLumperCharge: Double = 0, dropLumperCharges: [Double] = []) {
        self.id = UUID()
        self.loadRate = loadRate
        self.segments = []
        self.createdAt = Date()
        self.pickupLumperCharge = pickupLumperCharge
        self.dropLumperCharges = dropLumperCharges
    }
}

// MARK: - Route Segment

struct RouteSegment: Identifiable, Codable {
    let id: UUID
    var segmentType: SegmentType
    var origin: String
    var destination: String
    var originCoordinate: CLLocationCoordinate2D?
    var destinationCoordinate: CLLocationCoordinate2D?
    var distanceMiles: Double
    var weightAtSegment: Double  // Weight during this segment
    var dropWeight: Double?  // Weight dropped at destination (for multi-drop)
    var statesTraversed: [String]  // State codes traversed in this segment

    // Route polyline (not codable - transient for display only)
    var routePolyline: MKPolyline?

    // Calculated costs
    var effectiveMPG: Double
    var fuelCost: Double
    var overnightCost: Double
    var numberOfNights: Int

    var totalCost: Double {
        fuelCost + overnightCost
    }

    // Custom Codable to exclude polyline
    enum CodingKeys: String, CodingKey {
        case id, segmentType, origin, destination
        case originCoordinate, destinationCoordinate
        case distanceMiles, weightAtSegment, dropWeight, statesTraversed
        case effectiveMPG, fuelCost, overnightCost, numberOfNights
    }

    init(
        segmentType: SegmentType,
        origin: String = "",
        destination: String = "",
        distanceMiles: Double = 0,
        weightAtSegment: Double = 0,
        dropWeight: Double? = nil,
        statesTraversed: [String] = []
    ) {
        self.id = UUID()
        self.segmentType = segmentType
        self.origin = origin
        self.destination = destination
        self.distanceMiles = distanceMiles
        self.weightAtSegment = weightAtSegment
        self.dropWeight = dropWeight
        self.statesTraversed = statesTraversed
        self.effectiveMPG = 7.0
        self.fuelCost = 0
        self.overnightCost = 0
        self.numberOfNights = 0
    }
}

// MARK: - Segment Type

enum SegmentType: String, Codable, CaseIterable, Identifiable {
    case deadheadToTrailer = "Deadhead to Trailer"
    case deadheadToPickup = "Deadhead to Pickup"
    case pickupToDelivery = "Loaded to Delivery"
    case deliveryToDelivery = "Delivery to Delivery"
    case deadheadToDropTrailer = "Deadhead to Drop Trailer"
    case deadheadHome = "Deadhead Home"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .deadheadToTrailer: return "arrow.right.circle"
        case .deadheadToPickup: return "arrow.right.circle"
        case .pickupToDelivery: return "shippingbox.fill"
        case .deliveryToDelivery: return "shippingbox"
        case .deadheadToDropTrailer: return "arrow.left.circle"
        case .deadheadHome: return "house"
        }
    }

    var isLoaded: Bool {
        switch self {
        case .pickupToDelivery, .deliveryToDelivery:
            return true
        default:
            return false
        }
    }

    var isDeadhead: Bool {
        !isLoaded
    }
}

// MARK: - Drop Location

struct DropLocation: Identifiable, Codable {
    let id: UUID
    var address: String
    var weightToDrop: Double
    var lumperCharge: Double
    var coordinate: CLLocationCoordinate2D?

    init(address: String = "", weightToDrop: Double = 0, lumperCharge: Double = 0) {
        self.id = UUID()
        self.address = address
        self.weightToDrop = weightToDrop
        self.lumperCharge = lumperCharge
    }
}

// MARK: - Calculation Explanation (for Transparency UI)

struct CalculationExplanation {
    let baseMPG: Double
    let fuelPrice: Double
    let nightlyRate: Double
    let milesPerDay: Double
    let baseWeight: Double
    let mpgPenaltyPerPound: Double

    var mpgFormula: String {
        """
        Effective MPG = Base MPG - (Total Weight - \(Int(baseWeight).formatted()) lbs) × \(String(format: "%.5f", mpgPenaltyPerPound))

        Your truck's base MPG: \(String(format: "%.1f", baseMPG))
        Minimum enforced: 4.0 MPG
        """
    }

    var fuelCostFormula: String {
        """
        Fuel Cost = (Distance ÷ Effective MPG) × Fuel Price

        Current fuel price: $\(String(format: "%.2f", fuelPrice))/gal
        """
    }

    var overnightFormula: String {
        """
        Overnight Stays = ⌈Distance ÷ \(Int(milesPerDay)) miles/day⌉ - 1

        Based on DOT 11-hour driving limit (~\(Int(milesPerDay)) mi/day at 50 mph)
        Nightly rate: $\(String(format: "%.0f", nightlyRate))
        """
    }

    var profitFormula: String {
        """
        Net Profit = Load Rate - (Fuel Cost + Overnight Cost + Lumper Charges)

        Profit per Mile = Net Profit ÷ Total Miles
        """
    }
}

// MARK: - CLLocationCoordinate2D Codable

extension CLLocationCoordinate2D: Codable {
    enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
}
