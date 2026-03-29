import Foundation
import CoreLocation

/// Offline state lookup service using AABB + Ray Casting algorithm
/// Replaces CLGeocoder to eliminate network dependency and hangs
struct StateLookupService {

    /// Returns the 2-letter state code for a given coordinate
    /// Performance: O(48) bounding box checks + O(n) ray casting for matches
    /// Typical execution: <1ms
    static func getStateCode(for coordinate: CLLocationCoordinate2D) -> String? {
        // Quick bounds check - is this even in the continental US?
        guard coordinate.latitude >= 24.0 && coordinate.latitude <= 50.0 &&
              coordinate.longitude >= -125.0 && coordinate.longitude <= -66.0 else {
            return nil
        }

        // 1. First Pass: Bounding Box (AABB) - Extremely fast filter
        let candidateStates = StateBoundaries.all.filter { state in
            coordinate.latitude >= state.boundingBox.minLat &&
            coordinate.latitude <= state.boundingBox.maxLat &&
            coordinate.longitude >= state.boundingBox.minLon &&
            coordinate.longitude <= state.boundingBox.maxLon
        }

        // If only one candidate, we're done (handles ~85% of US landmass)
        if candidateStates.count == 1 {
            return candidateStates[0].code
        }

        // 2. Second Pass: Point-in-Polygon (Ray Casting) - Precise check for overlaps/borders
        for state in candidateStates {
            if isPoint(coordinate, inPolygon: state.polygon) {
                return state.code
            }
        }

        // Fallback: return first candidate if ray casting fails (edge case)
        return candidateStates.first?.code
    }

    /// Ray Casting algorithm for point-in-polygon test
    /// Counts how many times a ray from the point crosses polygon edges
    /// Odd crossings = inside, Even crossings = outside
    private static func isPoint(_ point: CLLocationCoordinate2D, inPolygon polygon: [CLLocationCoordinate2D]) -> Bool {
        guard polygon.count >= 3 else { return false }

        var isInside = false
        var j = polygon.count - 1

        for i in 0..<polygon.count {
            let xi = polygon[i].longitude
            let yi = polygon[i].latitude
            let xj = polygon[j].longitude
            let yj = polygon[j].latitude

            // Check if ray crosses this edge
            if ((yi < point.latitude && yj >= point.latitude) ||
                (yj < point.latitude && yi >= point.latitude)) {
                // Calculate x coordinate of intersection
                let intersectX = xi + (point.latitude - yi) / (yj - yi) * (xj - xi)
                if intersectX < point.longitude {
                    isInside = !isInside
                }
            }
            j = i
        }

        return isInside
    }

    /// Batch lookup for multiple coordinates (used for polyline sampling)
    static func getStateCodes(for coordinates: [CLLocationCoordinate2D]) -> [String] {
        var states: [String] = []
        var lastState: String? = nil

        for coord in coordinates {
            if let state = getStateCode(for: coord) {
                // Only add if different from last (maintains order, removes duplicates)
                if state != lastState {
                    states.append(state)
                    lastState = state
                }
            }
        }

        return states
    }
}
