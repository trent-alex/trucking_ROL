import Foundation

class CostCalculator {
    // MARK: - Settings (can be updated from UserDefaults/Settings)
    var baseMPG: Double
    var baseWeight: Double
    var mpgPenaltyPerPound: Double
    var fuelPricePerGallon: Double
    var milesPerDay: Double
    var nightlyRate: Double

    init(
        baseMPG: Double = Constants.defaultBaseMPG,
        baseWeight: Double = Constants.defaultBaseWeight,
        mpgPenaltyPerPound: Double = Constants.defaultMPGPenaltyPerPound,
        fuelPricePerGallon: Double = Constants.defaultFuelPrice,
        milesPerDay: Double = Constants.defaultMilesPerDay,
        nightlyRate: Double = Constants.defaultNightlyRate
    ) {
        self.baseMPG = baseMPG
        self.baseWeight = baseWeight
        self.mpgPenaltyPerPound = mpgPenaltyPerPound
        self.fuelPricePerGallon = fuelPricePerGallon
        self.milesPerDay = milesPerDay
        self.nightlyRate = nightlyRate
    }

    // MARK: - Fuel Efficiency Calculation

    /// Calculate effective MPG based on total weight
    /// Formula: effectiveMPG = baseMPG - (totalWeight - baseWeight) * penaltyPerPound
    func calculateEffectiveMPG(totalWeight: Double) -> Double {
        let weightOverBase = max(0, totalWeight - baseWeight)
        let penalty = weightOverBase * mpgPenaltyPerPound
        let effectiveMPG = baseMPG - penalty
        // Don't let MPG go below minimum
        return max(Constants.minimumMPG, effectiveMPG)
    }

    // MARK: - Fuel Cost Calculation

    /// Calculate total fuel cost for a trip
    func calculateFuelCost(distanceMiles: Double, totalWeight: Double) -> Double {
        let effectiveMPG = calculateEffectiveMPG(totalWeight: totalWeight)
        let gallonsNeeded = distanceMiles / effectiveMPG
        return gallonsNeeded * fuelPricePerGallon
    }

    // MARK: - Overnight Stays Calculation

    /// Calculate suggested number of overnight stays based on HOS rules
    /// Based on 11-hour driving limit at ~50 mph average = ~550 miles/day
    func calculateSuggestedNights(distanceMiles: Double) -> Int {
        guard distanceMiles > 0 else { return 0 }
        let daysNeeded = distanceMiles / milesPerDay
        // Subtract 1 because first day doesn't need overnight before starting
        return max(0, Int(ceil(daysNeeded)) - 1)
    }

    /// Calculate overnight stay cost
    func calculateOvernightCost(numberOfNights: Int) -> Double {
        return Double(numberOfNights) * nightlyRate
    }

    // MARK: - Full Cost Breakdown

    /// Generate complete cost breakdown for a route
    func calculateCostBreakdown(
        distanceMiles: Double,
        totalWeight: Double,
        overnightNightsOverride: Int? = nil
    ) -> CostBreakdown {
        let fuelCost = calculateFuelCost(distanceMiles: distanceMiles, totalWeight: totalWeight)
        let suggestedNights = calculateSuggestedNights(distanceMiles: distanceMiles)
        let nights = overnightNightsOverride ?? suggestedNights
        let overnightCost = calculateOvernightCost(numberOfNights: nights)

        return CostBreakdown(
            distanceMiles: distanceMiles,
            fuelCost: fuelCost,
            overnightCost: overnightCost,
            numberOfNights: nights
        )
    }
}
