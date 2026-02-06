import Foundation
import SwiftData

@Model
final class SavedRoute {
    // MARK: - Route Info
    var origin: String
    var destination: String
    var distanceMiles: Double
    var statesTraversed: [String]

    // MARK: - Coordinates (stored as Doubles since CLLocationCoordinate2D is not SwiftData-compatible)
    var originLatitude: Double
    var originLongitude: Double
    var destinationLatitude: Double
    var destinationLongitude: Double

    // MARK: - Costs
    var fuelCost: Double
    var overnightCost: Double
    var numberOfNights: Int
    var totalCost: Double
    var costPerMile: Double

    // MARK: - Settings at Save Time
    var emptyTruckWeight: Double
    var loadWeight: Double
    var baseMPG: Double
    var effectiveMPG: Double
    var fuelPrice: Double
    var nightlyRate: Double

    // MARK: - Metadata
    @Attribute(.unique) var id: UUID
    var savedAt: Date

    init(
        origin: String,
        destination: String,
        distanceMiles: Double,
        statesTraversed: [String],
        originLatitude: Double,
        originLongitude: Double,
        destinationLatitude: Double,
        destinationLongitude: Double,
        fuelCost: Double,
        overnightCost: Double,
        numberOfNights: Int,
        totalCost: Double,
        costPerMile: Double,
        emptyTruckWeight: Double,
        loadWeight: Double,
        baseMPG: Double,
        effectiveMPG: Double,
        fuelPrice: Double,
        nightlyRate: Double
    ) {
        self.origin = origin
        self.destination = destination
        self.distanceMiles = distanceMiles
        self.statesTraversed = statesTraversed
        self.originLatitude = originLatitude
        self.originLongitude = originLongitude
        self.destinationLatitude = destinationLatitude
        self.destinationLongitude = destinationLongitude
        self.fuelCost = fuelCost
        self.overnightCost = overnightCost
        self.numberOfNights = numberOfNights
        self.totalCost = totalCost
        self.costPerMile = costPerMile
        self.emptyTruckWeight = emptyTruckWeight
        self.loadWeight = loadWeight
        self.baseMPG = baseMPG
        self.effectiveMPG = effectiveMPG
        self.fuelPrice = fuelPrice
        self.nightlyRate = nightlyRate
        self.id = UUID()
        self.savedAt = Date()
    }
}
