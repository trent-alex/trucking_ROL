import Foundation

class GoogleMapsService {
    private let apiKey: String
    private let session: URLSession

    init(apiKey: String = Constants.googleMapsAPIKey) {
        self.apiKey = apiKey
        self.session = URLSession.shared
    }

    // MARK: - Routes API

    /// Fetch route with toll information using Google Routes API
    func fetchRoute(
        from origin: String,
        to destination: String
    ) async throws -> Route {
        let url = URL(string: "https://routes.googleapis.com/directions/v2:computeRoutes")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        // Request toll info and route details
        request.setValue("routes.distanceMeters,routes.duration,routes.travelAdvisory,routes.legs.travelAdvisory", forHTTPHeaderField: "X-Goog-FieldMask")

        let body: [String: Any] = [
            "origin": [
                "address": origin
            ],
            "destination": [
                "address": destination
            ],
            "travelMode": "DRIVE",
            "routingPreference": "TRAFFIC_AWARE",
            "computeAlternativeRoutes": false,
            "extraComputations": ["TOLLS"],
            "routeModifiers": [
                "vehicleInfo": [
                    "emissionType": "DIESEL"
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleMapsError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw GoogleMapsError.apiError(message)
            }
            throw GoogleMapsError.httpError(httpResponse.statusCode)
        }

        return try parseRouteResponse(data: data, origin: origin, destination: destination)
    }

    // MARK: - Response Parsing

    private func parseRouteResponse(data: Data, origin: String, destination: String) throws -> Route {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let routes = json["routes"] as? [[String: Any]],
              let firstRoute = routes.first else {
            throw GoogleMapsError.parsingError
        }

        // Extract distance (API returns meters)
        let distanceMeters = firstRoute["distanceMeters"] as? Double ?? 0
        let distanceMiles = distanceMeters / 1609.34

        // Extract toll information
        var tollInfo: TollInfo?
        if let travelAdvisory = firstRoute["travelAdvisory"] as? [String: Any],
           let tollInfoJson = travelAdvisory["tollInfo"] as? [String: Any] {
            tollInfo = parseTollInfo(tollInfoJson)
        }

        return Route(
            origin: origin,
            destination: destination,
            distanceMiles: distanceMiles,
            tollInfo: tollInfo,
            statesTraversed: [] // Would need additional parsing for state info
        )
    }

    private func parseTollInfo(_ json: [String: Any]) -> TollInfo {
        var estimatedCost: Double = 0
        var segments: [TollSegment] = []

        if let estimatedPrice = json["estimatedPrice"] as? [[String: Any]] {
            for price in estimatedPrice {
                if let units = price["units"] as? String,
                   let nanos = price["nanos"] as? Int {
                    let dollars = Double(units) ?? 0
                    let cents = Double(nanos) / 1_000_000_000
                    estimatedCost += dollars + cents
                }
            }
        }

        return TollInfo(estimatedCost: estimatedCost, tollSegments: segments)
    }

    // MARK: - Places Autocomplete

    /// Get address suggestions for autocomplete
    func fetchPlaceSuggestions(query: String) async throws -> [PlaceSuggestion] {
        guard !query.isEmpty else { return [] }

        var components = URLComponents(string: "https://maps.googleapis.com/maps/api/place/autocomplete/json")!
        components.queryItems = [
            URLQueryItem(name: "input", value: query),
            URLQueryItem(name: "types", value: "geocode|establishment"),
            URLQueryItem(name: "components", value: "country:us"),
            URLQueryItem(name: "key", value: apiKey)
        ]

        guard let url = components.url else {
            throw GoogleMapsError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GoogleMapsError.invalidResponse
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let predictions = json["predictions"] as? [[String: Any]] else {
            throw GoogleMapsError.parsingError
        }

        return predictions.compactMap { prediction in
            guard let description = prediction["description"] as? String,
                  let placeId = prediction["place_id"] as? String else {
                return nil
            }
            return PlaceSuggestion(description: description, placeId: placeId)
        }
    }
}

// MARK: - Supporting Types

struct PlaceSuggestion: Identifiable {
    let id = UUID()
    let description: String
    let placeId: String
}

enum GoogleMapsError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case parsingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "API error: \(message)"
        case .parsingError:
            return "Failed to parse response"
        }
    }
}
