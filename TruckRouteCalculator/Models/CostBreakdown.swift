import Foundation

struct CostBreakdown {
    var distanceMiles: Double
    var fuelCost: Double
    var overnightCost: Double
    var numberOfNights: Int

    var totalCost: Double {
        fuelCost + overnightCost
    }

    var costPerMile: Double {
        guard distanceMiles > 0 else { return 0 }
        return totalCost / distanceMiles
    }

    static let empty = CostBreakdown(
        distanceMiles: 0,
        fuelCost: 0,
        overnightCost: 0,
        numberOfNights: 0
    )
}
