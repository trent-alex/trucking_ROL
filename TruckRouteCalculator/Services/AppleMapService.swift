import Foundation
import MapKit

class AppleMapService: NSObject, MKLocalSearchCompleterDelegate {
    private let completer: MKLocalSearchCompleter
    private var onResultsUpdate: (([LocationSuggestion]) -> Void)?

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

        let directions = MKDirections(request: request)
        let response = try await directions.calculate()

        guard let mkRoute = response.routes.first else {
            throw AppleMapError.noRouteFound
        }

        let distanceMiles = mkRoute.distance / 1609.34

        return Route(
            origin: origin,
            destination: destination,
            distanceMiles: distanceMiles,
            statesTraversed: [],
            routePolyline: mkRoute.polyline,
            originCoordinate: originItem.placemark.coordinate,
            destinationCoordinate: destinationItem.placemark.coordinate
        )
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
