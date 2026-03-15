import Foundation

class FuelPriceService {
    private let apiKey: String
    private let session: URLSession
    private let cacheKey = "cachedDieselPrices"
    private let cacheTimestampKey = "cachedDieselPricesTimestamp"
    private let cacheExpirationHours: Double = 24

    // PADD region codes for EIA API
    enum PADDRegion: String, CaseIterable {
        case eastCoast = "R1X"      // PADD 1: East Coast
        case midwest = "R2X"         // PADD 2: Midwest
        case gulfCoast = "R3X"       // PADD 3: Gulf Coast
        case rockyMountain = "R4X"   // PADD 4: Rocky Mountain
        case westCoast = "R5X"       // PADD 5: West Coast
        case california = "R5XCA"    // California (separate due to regulations)
        case national = "NUS"        // National average (fallback)

        var displayName: String {
            switch self {
            case .eastCoast: return "East Coast"
            case .midwest: return "Midwest"
            case .gulfCoast: return "Gulf Coast"
            case .rockyMountain: return "Rocky Mountain"
            case .westCoast: return "West Coast"
            case .california: return "California"
            case .national: return "National Average"
            }
        }
    }

    // Map US states to PADD regions
    private static let stateToPADD: [String: PADDRegion] = [
        // PADD 1 - East Coast
        "ME": .eastCoast, "NH": .eastCoast, "VT": .eastCoast, "MA": .eastCoast,
        "RI": .eastCoast, "CT": .eastCoast, "NY": .eastCoast, "NJ": .eastCoast,
        "PA": .eastCoast, "DE": .eastCoast, "MD": .eastCoast, "DC": .eastCoast,
        "VA": .eastCoast, "WV": .eastCoast, "NC": .eastCoast, "SC": .eastCoast,
        "GA": .eastCoast, "FL": .eastCoast,

        // PADD 2 - Midwest
        "OH": .midwest, "MI": .midwest, "IN": .midwest, "IL": .midwest,
        "WI": .midwest, "MN": .midwest, "IA": .midwest, "MO": .midwest,
        "ND": .midwest, "SD": .midwest, "NE": .midwest, "KS": .midwest,
        "OK": .midwest, "KY": .midwest, "TN": .midwest,

        // PADD 3 - Gulf Coast
        "TX": .gulfCoast, "LA": .gulfCoast, "MS": .gulfCoast, "AL": .gulfCoast,
        "AR": .gulfCoast, "NM": .gulfCoast,

        // PADD 4 - Rocky Mountain
        "MT": .rockyMountain, "ID": .rockyMountain, "WY": .rockyMountain,
        "CO": .rockyMountain, "UT": .rockyMountain,

        // PADD 5 - West Coast
        "WA": .westCoast, "OR": .westCoast, "NV": .westCoast, "AZ": .westCoast,
        "AK": .westCoast, "HI": .westCoast,

        // California (separate)
        "CA": .california
    ]

    init(apiKey: String = Constants.eiaAPIKey) {
        self.apiKey = apiKey
        self.session = URLSession.shared
    }

    // MARK: - Public Methods

    /// Get diesel price for a specific state, using cached data if available
    func getDieselPrice(forState state: String?) async -> (price: Double, region: String, fromCache: Bool) {
        let region = Self.stateToPADD[state?.uppercased() ?? ""] ?? .national

        // Check cache first
        if let cachedPrices = getCachedPrices(), !isCacheExpired() {
            if let price = cachedPrices[region.rawValue] {
                return (price, region.displayName, true)
            }
        }

        // Fetch fresh prices
        if let prices = await fetchAllRegionalPrices() {
            cachePrices(prices)
            if let price = prices[region.rawValue] {
                return (price, region.displayName, false)
            }
        }

        // Fallback to national or default
        if let cachedPrices = getCachedPrices(), let national = cachedPrices[PADDRegion.national.rawValue] {
            return (national, "National Average", true)
        }

        return (Constants.defaultFuelPrice, "Default", false)
    }

    /// Fetch the latest US average retail diesel price (legacy method for compatibility)
    func fetchDieselPrice() async -> Double? {
        let result = await getDieselPrice(forState: nil)
        return result.region == "Default" ? nil : result.price
    }

    /// Force refresh all regional prices
    func refreshPrices() async -> Bool {
        if let prices = await fetchAllRegionalPrices() {
            cachePrices(prices)
            return true
        }
        return false
    }

    /// Get region for a state
    func getRegion(forState state: String) -> String {
        return (Self.stateToPADD[state.uppercased()] ?? .national).displayName
    }

    // MARK: - Private Methods

    private func fetchAllRegionalPrices() async -> [String: Double]? {
        guard apiKey != "YOUR_EIA_API_KEY" else { return nil }

        // Fetch all regions in one request
        let regions = PADDRegion.allCases.map { $0.rawValue }

        var components = URLComponents(string: "https://api.eia.gov/v2/petroleum/pri/gnd/data/")
        var queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "frequency", value: "weekly"),
            URLQueryItem(name: "data[0]", value: "value"),
            URLQueryItem(name: "facets[product][]", value: "EPD2D"),
            URLQueryItem(name: "sort[0][column]", value: "period"),
            URLQueryItem(name: "sort[0][direction]", value: "desc"),
            URLQueryItem(name: "length", value: "10"),
        ]

        // Add all regions as facets
        for region in regions {
            queryItems.append(URLQueryItem(name: "facets[duoarea][]", value: region))
        }

        components?.queryItems = queryItems

        guard let url = components?.url else { return nil }

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let responseObj = json["response"] as? [String: Any],
                  let dataArray = responseObj["data"] as? [[String: Any]] else {
                return nil
            }

            // Parse prices by region (get most recent for each)
            var prices: [String: Double] = [:]
            var seenRegions: Set<String> = []

            for item in dataArray {
                guard let duoarea = item["duoarea"] as? String,
                      let value = item["value"] as? Double,
                      !seenRegions.contains(duoarea) else {
                    continue
                }
                prices[duoarea] = value
                seenRegions.insert(duoarea)
            }

            return prices.isEmpty ? nil : prices
        } catch {
            return nil
        }
    }

    // MARK: - Caching

    private func cachePrices(_ prices: [String: Double]) {
        UserDefaults.standard.set(prices, forKey: cacheKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
    }

    private func getCachedPrices() -> [String: Double]? {
        return UserDefaults.standard.dictionary(forKey: cacheKey) as? [String: Double]
    }

    private func isCacheExpired() -> Bool {
        let timestamp = UserDefaults.standard.double(forKey: cacheTimestampKey)
        guard timestamp > 0 else { return true }

        let cacheDate = Date(timeIntervalSince1970: timestamp)
        let hoursSinceCache = Date().timeIntervalSince(cacheDate) / 3600

        return hoursSinceCache >= cacheExpirationHours
    }

    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheTimestampKey)
    }
}
