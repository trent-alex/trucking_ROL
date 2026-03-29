# Implementation Specification: Offline State Detection (v1.0)

## 1. Problem Statement: The "Chain of Failure"
The current implementation uses `CLGeocoder.reverseGeocodeLocation()` for intermediate state detection on long routes. This API:
- Makes network requests to Apple's servers.
- Has no timeout or cancellation support.
- Can hang for 30+ seconds on unreliable networks (common for truck drivers).
- Is rate-limited, causing intermittent failures during high-volume calculations.

## 2. Solution: Offline Coordinate Lookup
Replace the network-dependent geocoder with a local **Axis-Aligned Bounding Box (AABB)** and **Ray Casting (Point-in-Polygon)** algorithm.

### 3. Implementation Blueprint for AI Assistant
> **Instruction:** Follow these steps to implement the offline state detection system exactly as described.
> 1. Create `Services/StateLookupService.swift` using the Ray Casting implementation provided below.
> 2. Create `Models/StateBoundaries.swift` to house the static coordinate data for the US Lower 48 states.
> 3. Refactor `Services/AppleMapService.swift`: Replace the asynchronous `extractIntermediateStatesParallel` with a synchronous `extractStatesFromPolyline` method.
> 4. Ensure 100% offline-ready calculations by removing all geocoding dependencies from the routing loop.

---

## 4. Proposed Code Components

### Component A: `Services/StateLookupService.swift`
```swift
import Foundation
import CoreLocation

struct StateLookupService {
    /// Returns the 2-letter state code for a given coordinate
    static func getStateCode(for coordinate: CLLocationCoordinate2D) -> String? {
        // 1. First Pass: Bounding Box (AABB) - Extremely fast filter
        let candidateStates = StateBoundaries.all.filter { state in
            coordinate.latitude >= state.boundingBox.minLat &&
            coordinate.latitude <= state.boundingBox.maxLat &&
            coordinate.longitude >= state.boundingBox.minLon &&
            coordinate.longitude <= state.boundingBox.maxLon
        }
        
        // 2. Second Pass: Point-in-Polygon (Ray Casting) - Precise check for overlaps/borders
        for state in candidateStates {
            if isPoint(coordinate, inPolygon: state.polygon) {
                return state.code
            }
        }
        
        return nil
    }
    
    private static func isPoint(_ point: CLLocationCoordinate2D, inPolygon polygon: [CLLocationCoordinate2D]) -> Bool {
        var isInside = false
        var j = polygon.count - 1
        
        for i in 0..<polygon.count {
            if (polygon[i].longitude < point.longitude && polygon[j].longitude >= point.longitude || 
                polygon[j].longitude < point.longitude && polygon[i].longitude >= point.longitude) {
                if (polygon[i].latitude + (point.longitude - polygon[i].longitude) / (polygon[j].longitude - polygon[i].longitude) * (polygon[j].latitude - polygon[i].latitude) < point.latitude) {
                    isInside = !isInside
                }
            }
            j = i
        }
        return isInside
    }
}
```

### Component B: `Models/StateBoundaries.swift`
(Template for the AI Assistant to populate with US Lower 48 data)
```swift
import Foundation
import CoreLocation

struct StateBoundary {
    let code: String
    let name: String
    let boundingBox: (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double)
    let polygon: [CLLocationCoordinate2D]
}

struct StateBoundaries {
    // AI Assistant: Generate the full list for all 48 continental states here.
    // Use simplified polygons (10-15 vertices each) for performance.
    static let all: [StateBoundary] = [
        StateBoundary(
            code: "TX",
            name: "Texas",
            boundingBox: (25.83, 36.50, -106.64, -93.51),
            polygon: [/* Simplified vertices */]
        ),
        // ... rest of 48 states
    ]
}
```

### Component C: Refactor of `Services/AppleMapService.swift`
```swift
// REPLACEMENT METHOD:
func extractStatesFromPolyline(_ polyline: MKPolyline, existingStates: [String]) -> [String] {
    let pointCount = polyline.pointCount
    guard pointCount > 2 else { return existingStates }

    // INCREASE sampling density (15-20 points) because local lookup is CPU-cheap
    let sampleCount = 20
    let interval = max(pointCount / sampleCount, 1)
    let points = polyline.points()
    
    var foundStates = existingStates

    for i in stride(from: 0, to: pointCount, by: interval) {
        let coord = points[i].coordinate
        if let stateCode = StateLookupService.getStateCode(for: coord) {
            if !foundStates.contains(stateCode) {
                foundStates.append(stateCode)
            }
        }
    }
    
    return foundStates
}
```

## 5. Success Metrics
- **Calculation Latency:** Reduced from **>2,000ms** to **<2ms**.
- **User Experience:** Zero "Calculated Hangs" on poor connectivity.
- **Offline Readiness:** 100% of state-weight limit logic now functions without cellular data.
