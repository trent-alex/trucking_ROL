import Foundation

actor StateWeightService {
    static let shared = StateWeightService()

    // Optional remote URL for updates - set to nil to use bundled data only
    private let remoteURL: URL? = nil
    // To enable remote updates, uncomment:
    // private let remoteURL = URL(string: "https://yourserver.com/state-weight-limits.json")

    private let cacheKey = "cachedStateWeightLimits"
    private let cacheTimestampKey = "stateWeightLimitsCacheTimestamp"
    private let cacheDurationDays: Double = 30

    // MARK: - Public API

    /// Loads state weight limits - bundled first, then checks remote if configured
    func loadLimits() async -> [String: StateWeightLimit] {
        // 1. Try bundled JSON first (always available)
        var limits = loadBundledLimits()

        // 2. Check for cached remote updates
        if let cached = loadFromCache(), isCacheValid() {
            limits = cached
        }
        // 3. Optionally fetch remote updates in background
        else if remoteURL != nil {
            if let remote = try? await fetchFromRemote() {
                saveToCache(remote)
                limits = remote
            }
        }

        return limits
    }

    /// Loads limits synchronously from bundled JSON (for immediate use)
    func loadBundledLimits() -> [String: StateWeightLimit] {
        guard let url = Bundle.main.url(forResource: "state-weight-limits", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            // Fall back to hardcoded defaults
            return StateWeightDatabase.limits
        }

        do {
            let decoder = JSONDecoder()
            let bundled = try decoder.decode(StateWeightData.self, from: data)
            return bundled.toLimits()
        } catch {
            return StateWeightDatabase.limits
        }
    }

    /// Forces a refresh from remote (if configured)
    func forceRefresh() async -> [String: StateWeightLimit]? {
        guard remoteURL != nil else { return nil }

        do {
            let limits = try await fetchFromRemote()
            saveToCache(limits)
            return limits
        } catch {
            return nil
        }
    }

    /// Returns data source info
    func dataSourceInfo() -> (source: String, lastUpdated: String?) {
        if let cached = loadCachedMetadata() {
            return (cached.source, cached.lastUpdated)
        }

        if let bundled = loadBundledMetadata() {
            return (bundled.source, bundled.lastUpdated)
        }

        return ("Built-in defaults", nil)
    }

    /// Returns cache age in days, or nil if no cache
    func cacheAge() -> Double? {
        guard let timestamp = UserDefaults.standard.object(forKey: cacheTimestampKey) as? Date else {
            return nil
        }
        return Date().timeIntervalSince(timestamp) / 86400
    }

    // MARK: - Bundled Data

    private func loadBundledMetadata() -> StateWeightData? {
        guard let url = Bundle.main.url(forResource: "state-weight-limits", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(StateWeightData.self, from: data) else {
            return nil
        }
        return decoded
    }

    // MARK: - Remote Fetch

    private func fetchFromRemote() async throws -> [String: StateWeightLimit] {
        guard let url = remoteURL else {
            throw StateWeightError.remoteNotConfigured
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StateWeightError.fetchFailed
        }

        let decoder = JSONDecoder()
        let remoteData = try decoder.decode(StateWeightData.self, from: data)

        return remoteData.toLimits()
    }

    // MARK: - Cache Management

    private func loadFromCache() -> [String: StateWeightLimit]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let cached = try decoder.decode(StateWeightData.self, from: data)
            return cached.toLimits()
        } catch {
            return nil
        }
    }

    private func loadCachedMetadata() -> StateWeightData? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode(StateWeightData.self, from: data) else {
            return nil
        }
        return decoded
    }

    private func saveToCache(_ limits: [String: StateWeightLimit]) {
        let states = limits.map { (code, limit) in
            StateWeightEntry(
                stateCode: code,
                stateName: limit.stateName,
                grossWeightLimit: limit.grossWeightLimit,
                notes: limit.notes
            )
        }

        let data = StateWeightData(
            version: "1.0",
            lastUpdated: ISO8601DateFormatter().string(from: Date()),
            source: "Remote update",
            sourceUrl: remoteURL?.absoluteString,
            states: states
        )

        do {
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(data)
            UserDefaults.standard.set(encoded, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheTimestampKey)
        } catch {
            // Cache save failed
        }
    }

    private func isCacheValid() -> Bool {
        guard let age = cacheAge() else { return false }
        return age < cacheDurationDays
    }

    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheTimestampKey)
    }
}

// MARK: - Data Models

struct StateWeightData: Codable {
    let version: String
    let lastUpdated: String
    let source: String
    let sourceUrl: String?
    let states: [StateWeightEntry]

    func toLimits() -> [String: StateWeightLimit] {
        var result: [String: StateWeightLimit] = [:]
        for state in states {
            result[state.stateCode] = StateWeightLimit(
                stateCode: state.stateCode,
                stateName: state.stateName,
                grossWeightLimit: state.grossWeightLimit,
                notes: state.notes
            )
        }
        return result
    }
}

struct StateWeightEntry: Codable {
    let stateCode: String
    let stateName: String
    let grossWeightLimit: Double
    let notes: String?
}

enum StateWeightError: LocalizedError {
    case fetchFailed
    case remoteNotConfigured

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Failed to fetch state weight limits"
        case .remoteNotConfigured:
            return "Remote URL not configured"
        }
    }
}
