import Foundation

struct Route: Identifiable {
    let id = UUID()
    var origin: String
    var destination: String
    var distanceMiles: Double
    var tollInfo: TollInfo?
    var statesTraversed: [String]
}

struct TollInfo {
    var estimatedCost: Double
    var tollSegments: [TollSegment]
}

struct TollSegment: Identifiable {
    let id = UUID()
    var name: String
    var cost: Double
    var state: String
}
