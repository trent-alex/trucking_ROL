import Foundation

struct LoadConfig {
    var emptyTruckWeight: Double  // in pounds
    var loadWeight: Double        // in pounds

    var totalWeight: Double {
        emptyTruckWeight + loadWeight
    }

    static let defaultConfig = LoadConfig(
        emptyTruckWeight: 30000,
        loadWeight: 0
    )
}
