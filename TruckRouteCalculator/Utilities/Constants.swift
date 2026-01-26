import Foundation

enum Constants {
    // MARK: - API Configuration
    // Replace with your Google Maps API key
    static let googleMapsAPIKey = "YOUR_GOOGLE_MAPS_API_KEY"

    // MARK: - Fuel Calculation Defaults
    static let defaultBaseMPG: Double = 7.0
    static let defaultBaseWeight: Double = 30000  // pounds
    static let defaultMPGPenaltyPerPound: Double = 0.00003
    static let defaultFuelPrice: Double = 3.50  // per gallon
    static let minimumMPG: Double = 4.0  // floor to prevent unrealistic values

    // MARK: - Overnight Stay Defaults
    static let defaultMilesPerDay: Double = 550  // based on 11-hour HOS limit
    static let defaultNightlyRate: Double = 150.0

    // MARK: - Weight Limits
    static let maxLegalWeight: Double = 80000  // federal limit
    static let minTruckWeight: Double = 10000
}
