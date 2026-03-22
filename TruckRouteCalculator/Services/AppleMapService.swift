import Foundation
import MapKit
import CoreLocation

class AppleMapService: NSObject, MKLocalSearchCompleterDelegate {
    private let completer: MKLocalSearchCompleter
    private var onResultsUpdate: (([LocationSuggestion]) -> Void)?
    private let geocoder = CLGeocoder()

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
        let originItem = try await resolveLocation(origin)
        let destinationItem = try await resolveLocation(destination)

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
        if distanceMiles > 100 {
            let intermediateStates = await extractIntermediateStates(from: mkRoute.polyline, existingStates: states)
            states = mergeStatesInOrder(origin: states.first, destination: states.last, intermediate: intermediateStates)
        }

        return Route(
            origin: origin,
            destination: destination,
            distanceMiles: distanceMiles,
            statesTraversed: states,
            routePolyline: mkRoute.polyline,
            originCoordinate: originItem.placemark.coordinate,
            destinationCoordinate: destinationItem.placemark.coordinate
        )
    }

    // MARK: - State Extraction

    private func extractIntermediateStates(from polyline: MKPolyline, existingStates: [String]) async -> [String] {
        let pointCount = polyline.pointCount
        guard pointCount > 2 else { return [] }

        // Sample every ~100 miles (roughly every 150-200 points depending on route detail)
        let sampleInterval = max(pointCount / 10, 1)
        let points = polyline.points()

        var foundStates: [String] = []

        for i in stride(from: sampleInterval, to: pointCount - sampleInterval, by: sampleInterval) {
            let coord = points[i].coordinate
            if let state = await reverseGeocodeState(coordinate: coord) {
                if !foundStates.contains(state) && !existingStates.contains(state) {
                    foundStates.append(state)
                }
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
        return mapItem
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
