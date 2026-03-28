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
        // Check route cache first
        let routeCacheKey = "\(origin.lowercased())|\(destination.lowercased())"
        if let cached = cacheQueue.sync(execute: { routeCache[routeCacheKey] }) {
            return cached
        }

        // Resolve both locations in parallel
        async let originItemTask = resolveLocation(origin)
        async let destinationItemTask = resolveLocation(destination)

        let originItem = try await originItemTask
        let destinationItem = try await destinationItemTask

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

        // For longer routes, sample intermediate points for state crossings
        // Only do this for routes > 200 miles to reduce API calls
        if distanceMiles > 200 {
            let intermediateStates = await extractIntermediateStatesParallel(from: mkRoute.polyline, existingStates: states)
            states = mergeStatesInOrder(origin: states.first, destination: states.last, intermediate: intermediateStates)
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

    private func extractIntermediateStates(from polyline: MKPolyline, existingStates: [String]) async -> [String] {
        // Use parallel version for better performance
        return await extractIntermediateStatesParallel(from: polyline, existingStates: existingStates)
    }

    /// Parallel version of state extraction - all geocoding happens concurrently
    private func extractIntermediateStatesParallel(from polyline: MKPolyline, existingStates: [String]) async -> [String] {
        let pointCount = polyline.pointCount
        guard pointCount > 2 else { return [] }

        // Sample 5 points along the route (reduced from 10 for speed)
        let sampleInterval = max(pointCount / 5, 1)
        let points = polyline.points()

        // Collect sample coordinates
        var sampleCoordinates: [(index: Int, coordinate: CLLocationCoordinate2D)] = []
        for i in stride(from: sampleInterval, to: pointCount - sampleInterval, by: sampleInterval) {
            sampleCoordinates.append((index: i, coordinate: points[i].coordinate))
        }

        // Fetch all states in parallel using TaskGroup
        var indexedStates: [(index: Int, state: String)] = []

        await withTaskGroup(of: (Int, String?).self) { group in
            for sample in sampleCoordinates {
                group.addTask {
                    let state = await self.reverseGeocodeState(coordinate: sample.coordinate)
                    return (sample.index, state)
                }
            }

            for await (index, state) in group {
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
        // Check cache first
        let cacheKey = address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
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

    /// Clear caches (call when starting fresh calculation)
    func clearCaches() {
        cacheQueue.sync {
            locationCache.removeAll()
            routeCache.removeAll()
        }
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
