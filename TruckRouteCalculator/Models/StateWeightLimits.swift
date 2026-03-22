import Foundation

struct StateWeightLimit {
    let stateCode: String
    let stateName: String
    let grossWeightLimit: Double  // in lbs
    let notes: String?

    var isOverFederalLimit: Bool {
        grossWeightLimit > 80_000
    }

    var isUnderFederalLimit: Bool {
        grossWeightLimit < 80_000
    }
}

struct StateWeightDatabase {

    // Cached remote limits (populated by StateWeightService)
    static var remoteLimits: [String: StateWeightLimit]?

    // US State weight limits - Federal limit is 80,000 lbs for interstate
    // Some states have higher limits for intrastate or with permits
    static let limits: [String: StateWeightLimit] = [
        // States with HIGHER intrastate limits (permits may be required)
        "MI": StateWeightLimit(stateCode: "MI", stateName: "Michigan", grossWeightLimit: 164_000, notes: "Up to 11 axles, permits required"),
        "TX": StateWeightLimit(stateCode: "TX", stateName: "Texas", grossWeightLimit: 84_000, notes: "Intrastate only"),
        "UT": StateWeightLimit(stateCode: "UT", stateName: "Utah", grossWeightLimit: 129_000, notes: "Permit required"),
        "NV": StateWeightLimit(stateCode: "NV", stateName: "Nevada", grossWeightLimit: 129_000, notes: "Permit required"),
        "AZ": StateWeightLimit(stateCode: "AZ", stateName: "Arizona", grossWeightLimit: 129_000, notes: "Permit required"),
        "ID": StateWeightLimit(stateCode: "ID", stateName: "Idaho", grossWeightLimit: 105_500, notes: "Permit required"),
        "MT": StateWeightLimit(stateCode: "MT", stateName: "Montana", grossWeightLimit: 131_060, notes: "Permit required"),
        "ND": StateWeightLimit(stateCode: "ND", stateName: "North Dakota", grossWeightLimit: 105_500, notes: "Permit required"),
        "SD": StateWeightLimit(stateCode: "SD", stateName: "South Dakota", grossWeightLimit: 129_000, notes: "Permit required"),
        "WY": StateWeightLimit(stateCode: "WY", stateName: "Wyoming", grossWeightLimit: 117_000, notes: "Permit required"),
        "OR": StateWeightLimit(stateCode: "OR", stateName: "Oregon", grossWeightLimit: 105_500, notes: "Permit required"),
        "WA": StateWeightLimit(stateCode: "WA", stateName: "Washington", grossWeightLimit: 105_500, notes: "Permit required"),

        // States with LOWER or STRICT limits
        "CT": StateWeightLimit(stateCode: "CT", stateName: "Connecticut", grossWeightLimit: 80_000, notes: "Strict enforcement"),
        "MA": StateWeightLimit(stateCode: "MA", stateName: "Massachusetts", grossWeightLimit: 80_000, notes: "Strict enforcement"),
        "RI": StateWeightLimit(stateCode: "RI", stateName: "Rhode Island", grossWeightLimit: 80_000, notes: "Strict enforcement"),
        "NY": StateWeightLimit(stateCode: "NY", stateName: "New York", grossWeightLimit: 80_000, notes: "NYC has additional restrictions"),
        "NJ": StateWeightLimit(stateCode: "NJ", stateName: "New Jersey", grossWeightLimit: 80_000, notes: "Turnpike limits may vary"),

        // Standard federal limit states (80,000 lbs)
        "AL": StateWeightLimit(stateCode: "AL", stateName: "Alabama", grossWeightLimit: 80_000, notes: nil),
        "AK": StateWeightLimit(stateCode: "AK", stateName: "Alaska", grossWeightLimit: 80_000, notes: nil),
        "AR": StateWeightLimit(stateCode: "AR", stateName: "Arkansas", grossWeightLimit: 80_000, notes: nil),
        "CA": StateWeightLimit(stateCode: "CA", stateName: "California", grossWeightLimit: 80_000, notes: "CARB regulations apply"),
        "CO": StateWeightLimit(stateCode: "CO", stateName: "Colorado", grossWeightLimit: 80_000, notes: nil),
        "DE": StateWeightLimit(stateCode: "DE", stateName: "Delaware", grossWeightLimit: 80_000, notes: nil),
        "FL": StateWeightLimit(stateCode: "FL", stateName: "Florida", grossWeightLimit: 80_000, notes: nil),
        "GA": StateWeightLimit(stateCode: "GA", stateName: "Georgia", grossWeightLimit: 80_000, notes: nil),
        "HI": StateWeightLimit(stateCode: "HI", stateName: "Hawaii", grossWeightLimit: 80_000, notes: nil),
        "IL": StateWeightLimit(stateCode: "IL", stateName: "Illinois", grossWeightLimit: 80_000, notes: nil),
        "IN": StateWeightLimit(stateCode: "IN", stateName: "Indiana", grossWeightLimit: 80_000, notes: nil),
        "IA": StateWeightLimit(stateCode: "IA", stateName: "Iowa", grossWeightLimit: 80_000, notes: nil),
        "KS": StateWeightLimit(stateCode: "KS", stateName: "Kansas", grossWeightLimit: 80_000, notes: nil),
        "KY": StateWeightLimit(stateCode: "KY", stateName: "Kentucky", grossWeightLimit: 80_000, notes: nil),
        "LA": StateWeightLimit(stateCode: "LA", stateName: "Louisiana", grossWeightLimit: 80_000, notes: nil),
        "ME": StateWeightLimit(stateCode: "ME", stateName: "Maine", grossWeightLimit: 80_000, notes: nil),
        "MD": StateWeightLimit(stateCode: "MD", stateName: "Maryland", grossWeightLimit: 80_000, notes: nil),
        "MN": StateWeightLimit(stateCode: "MN", stateName: "Minnesota", grossWeightLimit: 80_000, notes: nil),
        "MS": StateWeightLimit(stateCode: "MS", stateName: "Mississippi", grossWeightLimit: 80_000, notes: nil),
        "MO": StateWeightLimit(stateCode: "MO", stateName: "Missouri", grossWeightLimit: 80_000, notes: nil),
        "NE": StateWeightLimit(stateCode: "NE", stateName: "Nebraska", grossWeightLimit: 80_000, notes: nil),
        "NH": StateWeightLimit(stateCode: "NH", stateName: "New Hampshire", grossWeightLimit: 80_000, notes: nil),
        "NM": StateWeightLimit(stateCode: "NM", stateName: "New Mexico", grossWeightLimit: 80_000, notes: nil),
        "NC": StateWeightLimit(stateCode: "NC", stateName: "North Carolina", grossWeightLimit: 80_000, notes: nil),
        "OH": StateWeightLimit(stateCode: "OH", stateName: "Ohio", grossWeightLimit: 80_000, notes: nil),
        "OK": StateWeightLimit(stateCode: "OK", stateName: "Oklahoma", grossWeightLimit: 80_000, notes: nil),
        "PA": StateWeightLimit(stateCode: "PA", stateName: "Pennsylvania", grossWeightLimit: 80_000, notes: nil),
        "SC": StateWeightLimit(stateCode: "SC", stateName: "South Carolina", grossWeightLimit: 80_000, notes: nil),
        "TN": StateWeightLimit(stateCode: "TN", stateName: "Tennessee", grossWeightLimit: 80_000, notes: nil),
        "VT": StateWeightLimit(stateCode: "VT", stateName: "Vermont", grossWeightLimit: 80_000, notes: nil),
        "VA": StateWeightLimit(stateCode: "VA", stateName: "Virginia", grossWeightLimit: 80_000, notes: nil),
        "WV": StateWeightLimit(stateCode: "WV", stateName: "West Virginia", grossWeightLimit: 80_000, notes: nil),
        "WI": StateWeightLimit(stateCode: "WI", stateName: "Wisconsin", grossWeightLimit: 80_000, notes: nil),
        "DC": StateWeightLimit(stateCode: "DC", stateName: "District of Columbia", grossWeightLimit: 80_000, notes: "Truck restrictions in downtown")
    ]

    static func limit(for stateCode: String) -> StateWeightLimit? {
        // Check remote limits first, fall back to bundled defaults
        if let remote = remoteLimits?[stateCode.uppercased()] {
            return remote
        }
        return limits[stateCode.uppercased()]
    }

    static func isCompliant(weight: Double, in stateCode: String) -> Bool {
        guard let limit = limit(for: stateCode) else { return true }
        return weight <= limit.grossWeightLimit
    }

    static func checkCompliance(weight: Double, states: [String]) -> [StateWeightViolation] {
        var violations: [StateWeightViolation] = []

        for stateCode in states {
            if let limit = limit(for: stateCode), weight > limit.grossWeightLimit {
                violations.append(StateWeightViolation(
                    stateCode: stateCode,
                    stateName: limit.stateName,
                    weightLimit: limit.grossWeightLimit,
                    actualWeight: weight,
                    overageAmount: weight - limit.grossWeightLimit,
                    notes: limit.notes
                ))
            }
        }

        return violations
    }

    static func lowestLimit(for states: [String]) -> StateWeightLimit? {
        states.compactMap { limit(for: $0) }
            .min { $0.grossWeightLimit < $1.grossWeightLimit }
    }
}

struct StateWeightViolation: Identifiable {
    let id = UUID()
    let stateCode: String
    let stateName: String
    let weightLimit: Double
    let actualWeight: Double
    let overageAmount: Double
    let notes: String?

    var formattedOverage: String {
        "\(Int(overageAmount).formatted()) lbs over"
    }
}
