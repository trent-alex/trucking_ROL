import Foundation

class FuelPriceService {
    private let apiKey: String
    private let session: URLSession

    init(apiKey: String = Constants.eiaAPIKey) {
        self.apiKey = apiKey
        self.session = URLSession.shared
    }

    /// Fetch the latest US average retail diesel price from the EIA API.
    /// Returns the price per gallon, or nil if the request fails.
    func fetchDieselPrice() async -> Double? {
        guard apiKey != "YOUR_EIA_API_KEY" else { return nil }

        var components = URLComponents(string: "https://api.eia.gov/v2/petroleum/pri/gnd/data/")
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "frequency", value: "weekly"),
            URLQueryItem(name: "data[0]", value: "value"),
            URLQueryItem(name: "facets[product][]", value: "EPD2D"),
            URLQueryItem(name: "facets[duoarea][]", value: "NUS"),
            URLQueryItem(name: "sort[0][column]", value: "period"),
            URLQueryItem(name: "sort[0][direction]", value: "desc"),
            URLQueryItem(name: "length", value: "1"),
        ]

        guard let url = components?.url else { return nil }

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let responseObj = json["response"] as? [String: Any],
                  let dataArray = responseObj["data"] as? [[String: Any]],
                  let first = dataArray.first,
                  let value = first["value"] as? Double else {
                return nil
            }

            return value
        } catch {
            return nil
        }
    }
}
