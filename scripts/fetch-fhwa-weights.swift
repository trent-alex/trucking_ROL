#!/usr/bin/env swift
//
// fetch-fhwa-weights.swift
// Scrapes FHWA website and generates state-weight-limits.json
//
// Usage: swift scripts/fetch-fhwa-weights.swift > state-weight-limits.json
//

import Foundation

// FHWA State Weight Limits page
let fhwaURL = URL(string: "https://ops.fhwa.dot.gov/freight/policy/rpt_congress/truck_sw_laws/app_a.htm")!

// State name to code mapping
let stateCodes: [String: String] = [
    "Alabama": "AL", "Alaska": "AK", "Arizona": "AZ", "Arkansas": "AR",
    "California": "CA", "Colorado": "CO", "Connecticut": "CT", "Delaware": "DE",
    "District of Columbia": "DC", "Florida": "FL", "Georgia": "GA", "Hawaii": "HI",
    "Idaho": "ID", "Illinois": "IL", "Indiana": "IN", "Iowa": "IA",
    "Kansas": "KS", "Kentucky": "KY", "Louisiana": "LA", "Maine": "ME",
    "Maryland": "MD", "Massachusetts": "MA", "Michigan": "MI", "Minnesota": "MN",
    "Mississippi": "MS", "Missouri": "MO", "Montana": "MT", "Nebraska": "NE",
    "Nevada": "NV", "New Hampshire": "NH", "New Jersey": "NJ", "New Mexico": "NM",
    "New York": "NY", "North Carolina": "NC", "North Dakota": "ND", "Ohio": "OH",
    "Oklahoma": "OK", "Oregon": "OR", "Pennsylvania": "PA", "Rhode Island": "RI",
    "South Carolina": "SC", "South Dakota": "SD", "Tennessee": "TN", "Texas": "TX",
    "Utah": "UT", "Vermont": "VT", "Virginia": "VA", "Washington": "WA",
    "West Virginia": "WV", "Wisconsin": "WI", "Wyoming": "WY"
]

struct StateLimit: Codable {
    let stateCode: String
    let stateName: String
    let grossWeightLimit: Double
    let notes: String?
}

struct OutputData: Codable {
    let version: String
    let lastUpdated: String
    let source: String
    let sourceUrl: String
    let states: [StateLimit]
}

// Fetch HTML synchronously
func fetchHTML() -> String? {
    // Use synchronous Data(contentsOf:) for command-line script
    do {
        let data = try Data(contentsOf: fhwaURL)
        return String(data: data, encoding: .utf8)
    } catch {
        fputs("Fetch error: \(error.localizedDescription)\n", stderr)
        return nil
    }
}

// Parse weight from text (e.g., "80,000" -> 80000)
func parseWeight(_ text: String) -> Double? {
    let cleaned = text.replacingOccurrences(of: ",", with: "")
                      .replacingOccurrences(of: " ", with: "")

    // Extract number
    let pattern = #"(\d{5,6})"#
    if let range = cleaned.range(of: pattern, options: .regularExpression) {
        return Double(cleaned[range])
    }
    return nil
}

// Find weight limit in context around state name
func findWeightInContext(_ context: String, stateName: String) -> (weight: Double, notes: String?)? {
    var notes: [String] = []
    var foundWeight: Double = 80000  // Default federal limit

    let lowerContext = context.lowercased()

    // Look for explicit gross weight values
    // Pattern: numbers like 80,000 or 80000 near "gross", "weight", "lbs", "pounds"
    let weightPattern = #"(\d{2,3}),?(\d{3})"#

    var weights: [Double] = []
    var searchRange = context.startIndex..<context.endIndex

    while let range = context.range(of: weightPattern, options: .regularExpression, range: searchRange) {
        let match = String(context[range]).replacingOccurrences(of: ",", with: "")
        if let w = Double(match), w >= 70000 && w <= 170000 {
            weights.append(w)
        }
        searchRange = range.upperBound..<context.endIndex
    }

    // Use the most common weight found, or the first one
    if !weights.isEmpty {
        // Group by value and find most common
        let grouped = Dictionary(grouping: weights, by: { $0 })
        if let mostCommon = grouped.max(by: { $0.value.count < $1.value.count }) {
            foundWeight = mostCommon.key
        }
    }

    // Check for special conditions
    if lowerContext.contains("permit") && foundWeight > 80000 {
        notes.append("Permit required for over 80,000 lbs")
    }
    if lowerContext.contains("intrastate") && !lowerContext.contains("interstate") {
        notes.append("Intrastate limits shown")
    }
    if lowerContext.contains("toll road") || lowerContext.contains("turnpike") {
        notes.append("Toll road limits may vary")
    }

    return (foundWeight, notes.isEmpty ? nil : notes.joined(separator: "; "))
}

// Extract state sections from HTML
func parseStates(html: String) -> [StateLimit] {
    var states: [StateLimit] = []

    // Sort state names by length descending to match longer names first
    let sortedStates = stateCodes.keys.sorted { $0.count > $1.count }

    for stateName in sortedStates {
        guard let stateCode = stateCodes[stateName] else { continue }

        // Find state name in HTML (case insensitive, word boundary)
        let pattern = "(?i)\\b\(NSRegularExpression.escapedPattern(for: stateName))\\b"

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range, in: html) else {
            // State not found, use default
            states.append(StateLimit(
                stateCode: stateCode,
                stateName: stateName,
                grossWeightLimit: 80000,
                notes: nil
            ))
            continue
        }

        // Get context around the state name (up to 3000 chars after)
        let startIndex = range.lowerBound
        let endOffset = min(3000, html.distance(from: startIndex, to: html.endIndex))
        let endIndex = html.index(startIndex, offsetBy: endOffset)
        let context = String(html[startIndex..<endIndex])

        // Find weight in context
        let result = findWeightInContext(context, stateName: stateName)

        states.append(StateLimit(
            stateCode: stateCode,
            stateName: stateName,
            grossWeightLimit: result?.weight ?? 80000,
            notes: result?.notes
        ))
    }

    return states.sorted { $0.stateCode < $1.stateCode }
}

// Main
fputs("Fetching FHWA data from \(fhwaURL.absoluteString)...\n", stderr)

guard let html = fetchHTML() else {
    fputs("Error: Failed to fetch FHWA page\n", stderr)
    exit(1)
}

fputs("Received \(html.count) characters\n", stderr)
fputs("Parsing state weight limits...\n", stderr)

let states = parseStates(html: html)

let formatter = ISO8601DateFormatter()
let output = OutputData(
    version: "1.0",
    lastUpdated: formatter.string(from: Date()),
    source: "FHWA Compilation of Existing State Truck Size and Weight Limit Laws",
    sourceUrl: fhwaURL.absoluteString,
    states: states
)

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

if let jsonData = try? encoder.encode(output),
   let jsonString = String(data: jsonData, encoding: .utf8) {
    print(jsonString)
    fputs("\nGenerated \(states.count) state entries\n", stderr)

    // Summary of non-80K states
    let special = states.filter { $0.grossWeightLimit != 80000 }
    if !special.isEmpty {
        fputs("\nStates with non-standard limits:\n", stderr)
        for s in special {
            fputs("  \(s.stateCode): \(Int(s.grossWeightLimit)) lbs\n", stderr)
        }
    }
} else {
    fputs("Error: Failed to encode JSON\n", stderr)
    exit(1)
}
