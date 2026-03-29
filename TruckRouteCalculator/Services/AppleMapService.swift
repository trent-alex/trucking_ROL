import Foundation
import MapKit
import CoreLocation

class AppleMapService: NSObject, MKLocalSearchCompleterDelegate {
    private let completer: MKLocalSearchCompleter
    private var onResultsUpdate: (([LocationSuggestion]) -> Void)?
    private let geocoder = CLGeocoder()

    // MARK: - Caching for Performance
    private var locationCache: [String: MKMapItem] = [:]
    private var routeCache: [String: Route] = [:]
    private let cacheQueue = DispatchQueue(label: "com.trucking.mapservice.cache")

    override init() {
        self.completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        // Bias results toward the continental US
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
            span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 60)
        )
    }

    // MARK: - Place Search

    func searchPlaces(query: String, completion: @escaping ([LocationSuggestion]) -> Void) {
        guard !query.isEmpty else {
            completion([])
            return
        }
        self.onResultsUpdate = completion
        completer.queryFragment = query
    }

    func cancelSearch() {
        completer.queryFragment = ""
        onResultsUpdate = nil
    }

    // MARK: - MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let suggestions = completer.results.map { result in
            LocationSuggestion(
                title: result.title,
                subtitle: result.subtitle
            )
        }
        onResultsUpdate?(suggestions)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        onResultsUpdate?([])
    }

    // MARK: - Route Calculation

    func fetchRoute(from origin: String, to destination: String) async throws -> Route {
        // Check for cancellation
        try Task.checkCancellation()

        // Check route cache first with normalized keys
        let routeCacheKey = "\(normalizeAddressForCache(origin))|\(normalizeAddressForCache(destination))"
        if let cached = cacheQueue.sync(execute: { routeCache[routeCacheKey] }) {
            return cached
        }

        // Resolve both locations in parallel
        async let originItemTask = resolveLocation(origin)
        async let destinationItemTask = resolveLocation(destination)

        let originItem = try await originItemTask
        let destinationItem = try await destinationItemTask

        // Check for cancellation after location resolution
        try Task.checkCancellation()

        let request = MKDirections.Request()
        request.source = originItem
        request.destination = destinationItem
        request.transportType = .automobile
        request.requestsAlternateRoutes = false

        // iOS 18+: Prefer highways (default behavior, but explicit)
        if #available(iOS 18.0, *) {
            request.highwayPreference = .any  // Don't avoid highways
            request.tollPreference = .any     // Allow tolls for faster routes
        }

        let directions = MKDirections(request: request)
        let response = try await directions.calculate()

        // Check for cancellation after directions
        try Task.checkCancellation()

        guard let mkRoute = response.routes.first else {
            throw AppleMapError.noRouteFound
        }

        let distanceMiles = mkRoute.distance / 1609.34

        // Extract states from origin and destination
        var states: [String] = []
        if let originState = originItem.placemark.administrativeArea {
            states.append(stateCodeFromName(originState))
        }
        if let destState = destinationItem.placemark.administrativeArea,
           destState != originItem.placemark.administrativeArea {
            states.append(stateCodeFromName(destState))
        }

        // Extract intermediate states using offline coordinate lookup (no network calls)
        // This is synchronous and fast (<2ms) - no hanging possible
        if distanceMiles > 100 {
            states = extractStatesFromPolyline(mkRoute.polyline, existingStates: states)
        }

        let route = Route(
            origin: origin,
            destination: destination,
            distanceMiles: distanceMiles,
            statesTraversed: states,
            routePolyline: mkRoute.polyline,
            originCoordinate: originItem.placemark.coordinate,
            destinationCoordinate: destinationItem.placemark.coordinate
        )

        // Cache the route
        cacheQueue.sync { routeCache[routeCacheKey] = route }

        return route
    }

    // MARK: - State Extraction

    /// Check if we should bother with intermediate state detection based on bounding box
    private func shouldCheckIntermediateStates(polyline: MKPolyline, knownStates: [String]) -> Bool {
        // If we already have 2+ states from origin/destination, likely crossing multiple
        if knownStates.count >= 2 {
            return true
        }

        // Check bounding box size - approximate state widths
        let boundingRect = polyline.boundingMapRect
        let region = MKCoordinateRegion(boundingRect)

        // Average US state is ~3 degrees lat/lon wide
        // If bounding box spans > 4 degrees in either direction, likely multiple states
        let latSpan = region.span.latitudeDelta
        let lonSpan = region.span.longitudeDelta

        return latSpan > 4.0 || lonSpan > 4.0
    }

    private func extractIntermediateStates(from polyline: MKPolyline, existingStates: [String]) async -> [String] {
        // Use parallel version for better performance
        return await extractIntermediateStatesParallel(from: polyline, existingStates: existingStates)
    }

    /// Parallel version of state extraction - all geocoding happens concurrently
    /// Now with cancellation support and 3-second per-geocode timeout
    private func extractIntermediateStatesParallel(from polyline: MKPolyline, existingStates: [String]) async -> [String] {
        let pointCount = polyline.pointCount
        guard pointCount > 2 else { return [] }

        // Check for cancellation early
        guard !Task.isCancelled else { return [] }

        // Sample only 3 points for speed (reduced from 5)
        let sampleInterval = max(pointCount / 3, 1)
        let points = polyline.points()

        // Collect sample coordinates
        var sampleCoordinates: [(index: Int, coordinate: CLLocationCoordinate2D)] = []
        for i in stride(from: sampleInterval, to: pointCount - sampleInterval, by: sampleInterval) {
            sampleCoordinates.append((index: i, coordinate: points[i].coordinate))
        }

        // Limit to max 3 samples
        if sampleCoordinates.count > 3 {
            sampleCoordinates = Array(sampleCoordinates.prefix(3))
        }

        // Fetch all states in parallel using TaskGroup with timeout
        var indexedStates: [(index: Int, state: String)] = []
        let geocodeTimeout: UInt64 = 3_000_000_000 // 3 seconds per geocode

        await withTaskGroup(of: (Int, String?).self) { group in
            for sample in sampleCoordinates {
                group.addTask {
                    // Check for cancellation
                    guard !Task.isCancelled else { return (sample.index, nil) }

                    // Race between geocode and timeout
                    let state = await self.reverseGeocodeStateWithTimeout(
                        coordinate: sample.coordinate,
                        timeoutNanoseconds: geocodeTimeout
                    )
                    return (sample.index, state)
                }
            }

            for await (index, state) in group {
                // Check for cancellation between results
                if Task.isCancelled { break }

                if let state = state {
                    indexedStates.append((index: index, state: state))
                }
            }
        }

        // Sort by index to maintain route order, then deduplicate
        indexedStates.sort { $0.index < $1.index }

        var foundStates: [String] = []
        for (_, state) in indexedStates {
            if !foundStates.contains(state) && !existingStates.contains(state) {
                foundStates.append(state)
            }
        }

        return foundStates
    }

    /// Reverse geocode with a timeout - returns nil if geocode takes too long
    private func reverseGeocodeStateWithTimeout(coordinate: CLLocationCoordinate2D, timeoutNanoseconds: UInt64) async -> String? {
        // Use a simple race: start geocode, but give up after timeout
        return await withTaskGroup(of: String?.self) { group in
            group.addTask {
                await self.reverseGeocodeState(coordinate: coordinate)
            }

            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutNanoseconds)
                return nil as String?
            }

            // Return first result (either the state or nil from timeout)
            let result = await group.next() ?? nil
            group.cancelAll()
            return result
        }
    }

    private func reverseGeocodeState(coordinate: CLLocationCoordinate2D) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let state = placemarks.first?.administrativeArea {
                return stateCodeFromName(state)
            }
        } catch {
            // Geocoding failed, skip this point
        }

        return nil
    }

    private func mergeStatesInOrder(origin: String?, destination: String?, intermediate: [String]) -> [String] {
        var result: [String] = []

        if let origin = origin {
            result.append(origin)
        }

        for state in intermediate {
            if !result.contains(state) {
                result.append(state)
            }
        }

        if let destination = destination, !result.contains(destination) {
            result.append(destination)
        }

        return result
    }

    // MARK: - Offline State Extraction (Synchronous)

    /// Extract states from polyline using offline coordinate lookup
    /// This is synchronous, fast (<2ms), and never hangs
    private func extractStatesFromPolyline(_ polyline: MKPolyline, existingStates: [String]) -> [String] {
        let pointCount = polyline.pointCount
        guard pointCount > 2 else { return existingStates }

        // Sample 20 points along the route (CPU-cheap local lookup)
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

        // Also check the last point to ensure destination state is included
        let lastCoord = points[pointCount - 1].coordinate
        if let lastState = StateLookupService.getStateCode(for: lastCoord) {
            if !foundStates.contains(lastState) {
                foundStates.append(lastState)
            }
        }

        return foundStates
    }

    private func stateCodeFromName(_ stateName: String) -> String {
        // Map full state names to codes
        let stateMap: [String: String] = [
            "Alabama": "AL", "Alaska": "AK", "Arizona": "AZ", "Arkansas": "AR",
            "California": "CA", "Colorado": "CO", "Connecticut": "CT", "Delaware": "DE",
            "Florida": "FL", "Georgia": "GA", "Hawaii": "HI", "Idaho": "ID",
            "Illinois": "IL", "Indiana": "IN", "Iowa": "IA", "Kansas": "KS",
            "Kentucky": "KY", "Louisiana": "LA", "Maine": "ME", "Maryland": "MD",
            "Massachusetts": "MA", "Michigan": "MI", "Minnesota": "MN", "Mississippi": "MS",
            "Missouri": "MO", "Montana": "MT", "Nebraska": "NE", "Nevada": "NV",
            "New Hampshire": "NH", "New Jersey": "NJ", "New Mexico": "NM", "New York": "NY",
            "North Carolina": "NC", "North Dakota": "ND", "Ohio": "OH", "Oklahoma": "OK",
            "Oregon": "OR", "Pennsylvania": "PA", "Rhode Island": "RI", "South Carolina": "SC",
            "South Dakota": "SD", "Tennessee": "TN", "Texas": "TX", "Utah": "UT",
            "Vermont": "VT", "Virginia": "VA", "Washington": "WA", "West Virginia": "WV",
            "Wisconsin": "WI", "Wyoming": "WY", "District of Columbia": "DC"
        ]

        // If already a code, return as-is
        if stateName.count == 2 {
            return stateName.uppercased()
        }

        return stateMap[stateName] ?? stateName
    }

    // MARK: - Private

    private func resolveLocation(_ address: String) async throws -> MKMapItem {
        // Check cache first with normalized key
        let cacheKey = normalizeAddressForCache(address)
        if let cached = cacheQueue.sync(execute: { locationCache[cacheKey] }) {
            return cached
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = address
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
            span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 60)
        )

        let search = MKLocalSearch(request: request)
        let response = try await search.start()

        guard let mapItem = response.mapItems.first else {
            throw AppleMapError.locationNotFound(address)
        }

        // Cache the result
        cacheQueue.sync { locationCache[cacheKey] = mapItem }

        return mapItem
    }

    /// Pre-resolve a location when user selects it (background caching)
    func preResolveLocation(_ address: String) {
        Task {
            _ = try? await resolveLocation(address)
        }
    }

    /// Test if a location can be resolved (for validation)
    func testResolveLocation(_ address: String) async throws -> Bool {
        _ = try await resolveLocation(address)
        return true
    }

    /// Clear caches (call when starting fresh calculation)
    func clearCaches() {
        cacheQueue.sync {
            locationCache.removeAll()
            routeCache.removeAll()
        }
    }

    // MARK: - Cache Normalization

    /// Normalize address strings for better cache hit rates
    private func normalizeAddressForCache(_ address: String) -> String {
        var normalized = address
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove common suffixes that don't affect geocoding
        let removals = [", usa", ", united states", " usa", " united states", ".", ","]
        for removal in removals {
            normalized = normalized.replacingOccurrences(of: removal, with: "")
        }

        // Normalize state abbreviations with/without comma
        // "dallas tx" -> "dallas tx", "dallas, tx" -> "dallas tx"
        normalized = normalized.replacingOccurrences(of: ", ", with: " ")

        // Collapse multiple spaces
        while normalized.contains("  ") {
            normalized = normalized.replacingOccurrences(of: "  ", with: " ")
        }

        return normalized.trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Supporting Types

struct LocationSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String

    var displayText: String {
        if subtitle.isEmpty {
            return title
        }
        return "\(title), \(subtitle)"
    }
}

enum AppleMapError: LocalizedError {
    case locationNotFound(String)
    case noRouteFound

    var errorDescription: String? {
        switch self {
        case .locationNotFound(let address):
            return "Could not find location: \(address)"
        case .noRouteFound:
            return "No route found between the specified locations"
        }
    }
}
