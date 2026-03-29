import Foundation
import SwiftUI
import CoreLocation
import Combine

/// Error thrown when calculation exceeds timeout
struct TimeoutError: Error, LocalizedError {
    var errorDescription: String? {
        "Operation timed out"
    }
}

@MainActor
class ScenarioCalculatorViewModel: ObservableObject {
    // MARK: - Current Scenario
    @Published var loadRate: String = ""
    @Published var currentLocation: String = ""
    @Published var trailerPickupLocation: String = ""
    @Published var loadPickupLocation: String = ""
    @Published var loadPickupSameAsTrailer: Bool = false
    @Published var loadPickupSameAsCurrentLocation: Bool = false
    @Published var dropLocations: [DropLocation] = [DropLocation()]
    @Published var trailerDropLocation: String = ""
    @Published var trailerDropSameAsLastDelivery: Bool = false

    // MARK: - Load Details
    @Published var totalLoadWeight: Double = 0
    @Published var pickupLumperCharge: Double = 0

    // MARK: - Location Suggestions
    @Published var currentLocationSuggestions: [LocationSuggestion] = []
    @Published var trailerPickupSuggestions: [LocationSuggestion] = []
    @Published var loadPickupSuggestions: [LocationSuggestion] = []
    @Published var dropLocationSuggestions: [[LocationSuggestion]] = [[]]
    @Published var trailerDropSuggestions: [LocationSuggestion] = []

    // MARK: - State
    @Published var isCalculating: Bool = false
    @Published var errorMessage: String?
    @Published var currentScenario: LoadScenario?
    @Published var scenarios: [LoadScenario] = [] {
        didSet { saveScenarios() }
    }
    @Published var showingResults: Bool = false
    @Published var showSaveConfirmation: Bool = false

    // MARK: - Calculation Progress
    @Published var calculationProgress: String = ""
    @Published var calculationStartTime: Date?
    @Published var estimatedSegments: Int = 0
    @Published var completedSegments: Int = 0
    private var calculationTask: Task<Void, Never>?

    /// Timeout for route calculation (30 seconds - if it takes longer, addresses are bad)
    private let calculationTimeout: TimeInterval = 30

    // MARK: - Location Validation
    @Published var invalidLocations: Set<String> = []  // Field names with invalid locations
    @Published var isValidatingLocations: Bool = false
    @Published var validationMessage: String?

    // MARK: - Profile
    @Published var driverProfile: DriverProfile?

    // MARK: - Services
    private let mapService: AppleMapService
    private let fuelPriceService: FuelPriceService
    private var costCalculator: CostCalculator
    let locationManager: LocationManager

    // MARK: - Settings (persisted)
    @Published var fuelPrice: Double = Constants.defaultFuelPrice {
        didSet { UserDefaults.standard.set(fuelPrice, forKey: Self.fuelPriceKey) }
    }
    @Published var nightlyRate: Double = Constants.defaultNightlyRate {
        didSet { UserDefaults.standard.set(nightlyRate, forKey: Self.nightlyRateKey) }
    }
    @Published var defaultLumperCharge: Double = 0 {
        didSet { UserDefaults.standard.set(defaultLumperCharge, forKey: Self.lumperChargeKey) }
    }

    private static let fuelPriceKey = "savedFuelPrice"
    private static let nightlyRateKey = "savedNightlyRate"
    private static let lumperChargeKey = "savedLumperCharge"

    // MARK: - Fuel Price Metadata (for Trust UI)

    var fuelPriceCacheStatus: FuelPriceService.CacheStatus {
        fuelPriceService.getCacheStatus()
    }

    var fuelPriceIsVerified: Bool {
        fuelPriceService.hasValidCache()
    }

    var fuelPriceSourceText: String {
        fuelPriceService.getCacheStatus().displayText
    }

    // MARK: - Confidence Intervals

    /// Calculate profit with fuel price increased by percentage
    func profitWithFuelIncrease(_ percentage: Double, for scenario: LoadScenario) -> Double {
        let increasedFuelPrice = fuelPrice * (1 + percentage / 100)
        let fuelCostIncrease = scenario.totalFuelCost * (percentage / 100)
        return scenario.profit - fuelCostIncrease
    }

    /// Calculate worst case profit (5% fuel increase)
    func worstCaseProfit(for scenario: LoadScenario) -> Double {
        return profitWithFuelIncrease(5, for: scenario)
    }

    /// Calculate best case profit (5% fuel decrease)
    func bestCaseProfit(for scenario: LoadScenario) -> Double {
        return profitWithFuelIncrease(-5, for: scenario)
    }

    // MARK: - Calculation Logic for Transparency

    func getCalculationExplanation() -> CalculationExplanation {
        let profile = driverProfile ?? DriverProfile.default
        return CalculationExplanation(
            baseMPG: profile.baseMPG,
            fuelPrice: fuelPrice,
            nightlyRate: nightlyRate,
            milesPerDay: Constants.defaultMilesPerDay,
            baseWeight: Constants.defaultBaseWeight,
            mpgPenaltyPerPound: Constants.defaultMPGPenaltyPerPound
        )
    }

    private var searchTask: Task<Void, Never>?

    var isBobtailOnly: Bool {
        driverProfile?.configuration == .bobtailOnly
    }

    /// Returns true if the driver needs to pick up a trailer
    var needsTrailerPickup: Bool {
        // bobtailOnly = driver has no trailer, must pick one up
        // bobtailWithTrailer = already has trailer attached, no pickup needed
        driverProfile?.configuration == .bobtailOnly
    }

    /// Returns true if the driver will have a trailer during the trip (either picks up or already has)
    var willHaveTrailer: Bool {
        // Both configurations involve a trailer at some point
        true
    }

    // State weight compliance for current scenario
    var stateWeightViolations: [StateWeightViolation] {
        guard let scenario = currentScenario else { return [] }
        let maxWeight = scenario.maxWeight
        let allStates = scenario.allStatesTraversed
        return StateWeightDatabase.checkCompliance(weight: maxWeight, states: allStates)
    }

    var lowestStateLimit: StateWeightLimit? {
        guard let scenario = currentScenario else { return nil }
        return StateWeightDatabase.lowestLimit(for: scenario.allStatesTraversed)
    }

    var canCalculate: Bool {
        guard let rate = Double(loadRate), rate > 0 else { return false }
        guard !currentLocation.isEmpty else { return false }

        if needsTrailerPickup {
            guard !trailerPickupLocation.isEmpty || loadPickupSameAsTrailer else { return false }
        }

        guard !loadPickupLocation.isEmpty || loadPickupSameAsTrailer || loadPickupSameAsCurrentLocation else { return false }
        guard dropLocations.allSatisfy({ !$0.address.isEmpty }) else { return false }

        // Trailer drop is needed if driver will have a trailer
        if willHaveTrailer {
            guard !trailerDropLocation.isEmpty || trailerDropSameAsLastDelivery else { return false }
        }

        return true
    }

    init() {
        self.mapService = AppleMapService()
        self.fuelPriceService = FuelPriceService()
        self.costCalculator = CostCalculator()
        self.locationManager = LocationManager()

        // Load driver profile
        if let profile = DriverProfile.load() {
            self.driverProfile = profile
        }

        // Load saved scenarios
        loadScenarios()

        // Load saved settings
        loadSettings()
    }

    private func loadSettings() {
        let defaults = UserDefaults.standard

        if defaults.object(forKey: Self.fuelPriceKey) != nil {
            fuelPrice = defaults.double(forKey: Self.fuelPriceKey)
        }

        if defaults.object(forKey: Self.nightlyRateKey) != nil {
            nightlyRate = defaults.double(forKey: Self.nightlyRateKey)
        }

        if defaults.object(forKey: Self.lumperChargeKey) != nil {
            defaultLumperCharge = defaults.double(forKey: Self.lumperChargeKey)
            // Pre-fill pickup lumper with last used value
            pickupLumperCharge = defaultLumperCharge
        }
    }

    // MARK: - Persistence

    private static let scenariosKey = "savedLoadScenarios"

    private func saveScenarios() {
        do {
            let data = try JSONEncoder().encode(scenarios)
            UserDefaults.standard.set(data, forKey: Self.scenariosKey)
        } catch {
            print("Failed to save scenarios: \(error)")
        }
    }

    private func loadScenarios() {
        guard let data = UserDefaults.standard.data(forKey: Self.scenariosKey) else { return }
        do {
            scenarios = try JSONDecoder().decode([LoadScenario].self, from: data)
        } catch {
            print("Failed to load scenarios: \(error)")
        }
    }

    // MARK: - GPS Location

    func useCurrentGPSLocation() {
        locationManager.requestCurrentLocation()
    }

    func applyGPSLocation() {
        if let address = locationManager.currentAddress {
            currentLocation = address
            currentLocationSuggestions = []
        }
    }

    // MARK: - Drop Location Management

    func addDropLocation() {
        dropLocations.append(DropLocation())
        dropLocationSuggestions.append([])
    }

    func removeDropLocation(at index: Int) {
        guard dropLocations.count > 1 else { return }
        dropLocations.remove(at: index)
        if index < dropLocationSuggestions.count {
            dropLocationSuggestions.remove(at: index)
        }
    }

    func updateDropAddress(_ address: String, at index: Int) {
        guard index < dropLocations.count else { return }
        dropLocations[index].address = address
        searchDropLocation(query: address, index: index)
    }

    func updateDropWeight(_ weight: Double, at index: Int) {
        guard index < dropLocations.count else { return }
        dropLocations[index].weightToDrop = weight
    }

    func updateDropLumperCharge(_ charge: Double, at index: Int) {
        guard index < dropLocations.count else { return }
        dropLocations[index].lumperCharge = charge
    }

    // MARK: - Search

    func searchCurrentLocation() {
        searchPlaces(query: currentLocation) { [weak self] suggestions in
            self?.currentLocationSuggestions = suggestions
        }
    }

    func searchTrailerPickup() {
        searchPlaces(query: trailerPickupLocation) { [weak self] suggestions in
            self?.trailerPickupSuggestions = suggestions
        }
    }

    func searchLoadPickup() {
        searchPlaces(query: loadPickupLocation) { [weak self] suggestions in
            self?.loadPickupSuggestions = suggestions
        }
    }

    func searchDropLocation(query: String, index: Int) {
        searchPlaces(query: query) { [weak self] suggestions in
            guard let self = self else { return }
            while self.dropLocationSuggestions.count <= index {
                self.dropLocationSuggestions.append([])
            }
            self.dropLocationSuggestions[index] = suggestions
        }
    }

    func searchTrailerDrop() {
        searchPlaces(query: trailerDropLocation) { [weak self] suggestions in
            self?.trailerDropSuggestions = suggestions
        }
    }

    private func searchPlaces(query: String, completion: @escaping ([LocationSuggestion]) -> Void) {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            mapService.searchPlaces(query: query, completion: completion)
        }
    }

    // MARK: - Selection

    func selectCurrentLocation(_ suggestion: LocationSuggestion) {
        currentLocation = suggestion.displayText
        currentLocationSuggestions = []
        // Pre-resolve for faster calculation
        mapService.preResolveLocation(suggestion.displayText)
    }

    func selectTrailerPickup(_ suggestion: LocationSuggestion) {
        trailerPickupLocation = suggestion.displayText
        trailerPickupSuggestions = []
        mapService.preResolveLocation(suggestion.displayText)
    }

    func selectLoadPickup(_ suggestion: LocationSuggestion) {
        loadPickupLocation = suggestion.displayText
        loadPickupSuggestions = []
        mapService.preResolveLocation(suggestion.displayText)
    }

    func selectDropLocation(_ suggestion: LocationSuggestion, at index: Int) {
        guard index < dropLocations.count else { return }
        dropLocations[index].address = suggestion.displayText
        if index < dropLocationSuggestions.count {
            dropLocationSuggestions[index] = []
        }
        mapService.preResolveLocation(suggestion.displayText)
    }

    func selectTrailerDrop(_ suggestion: LocationSuggestion) {
        trailerDropLocation = suggestion.displayText
        trailerDropSuggestions = []
        mapService.preResolveLocation(suggestion.displayText)
    }

    // MARK: - Calculate

    /// Start calculation with cancellation support
    func startCalculation() {
        // Cancel any existing calculation
        calculationTask?.cancel()

        calculationTask = Task {
            // Validate locations first
            let isValid = await validateAllLocations()
            if isValid {
                await calculateScenario()
            }
        }
    }

    // MARK: - Location Validation

    /// Validate all entered locations before calculation
    func validateAllLocations() async -> Bool {
        isValidatingLocations = true
        invalidLocations.removeAll()
        validationMessage = nil

        var locationsToValidate: [(fieldName: String, address: String)] = []

        // Current location
        if !currentLocation.isEmpty {
            locationsToValidate.append(("currentLocation", currentLocation))
        }

        // Trailer pickup
        if needsTrailerPickup && !trailerPickupLocation.isEmpty {
            locationsToValidate.append(("trailerPickup", trailerPickupLocation))
        }

        // Load pickup
        if !loadPickupSameAsTrailer && !loadPickupSameAsCurrentLocation && !loadPickupLocation.isEmpty {
            locationsToValidate.append(("loadPickup", loadPickupLocation))
        }

        // Drop locations
        for (index, drop) in dropLocations.enumerated() where !drop.address.isEmpty {
            locationsToValidate.append(("drop_\(index)", drop.address))
        }

        // Trailer drop
        if willHaveTrailer && !trailerDropSameAsLastDelivery && !trailerDropLocation.isEmpty {
            locationsToValidate.append(("trailerDrop", trailerDropLocation))
        }

        // Validate all in parallel
        await withTaskGroup(of: (String, Bool).self) { group in
            for (fieldName, address) in locationsToValidate {
                group.addTask {
                    let isValid = await self.validateLocation(address)
                    return (fieldName, isValid)
                }
            }

            for await (fieldName, isValid) in group {
                if !isValid {
                    invalidLocations.insert(fieldName)
                }
            }
        }

        isValidatingLocations = false

        if !invalidLocations.isEmpty {
            let count = invalidLocations.count
            validationMessage = count == 1
                ? "1 location could not be found. Please check the highlighted field."
                : "\(count) locations could not be found. Please check the highlighted fields."
            errorMessage = validationMessage
            return false
        }

        return true
    }

    /// Validate a single location
    private func validateLocation(_ address: String) async -> Bool {
        do {
            _ = try await mapService.testResolveLocation(address)
            return true
        } catch {
            return false
        }
    }

    /// Check if a specific field has an invalid location
    func isLocationInvalid(_ fieldName: String) -> Bool {
        invalidLocations.contains(fieldName)
    }

    /// Clear validation error for a field when user edits it
    func clearValidationError(for fieldName: String) {
        invalidLocations.remove(fieldName)
        if invalidLocations.isEmpty {
            validationMessage = nil
        }
    }

    /// Cancel ongoing calculation
    func cancelCalculation() {
        calculationTask?.cancel()
        calculationTask = nil
        isCalculating = false
        calculationProgress = ""
        errorMessage = "Calculation cancelled"
    }

    func calculateScenario() async {
        guard canCalculate else { return }

        isCalculating = true
        errorMessage = nil
        calculationStartTime = Date()
        calculationProgress = "Preparing route..."
        completedSegments = 0

        do {
            // Check for cancellation
            try Task.checkCancellation()

            var scenario = LoadScenario(
                loadRate: Double(loadRate) ?? 0,
                pickupLumperCharge: pickupLumperCharge,
                dropLumperCharges: dropLocations.map { $0.lumperCharge }
            )

            let profile = driverProfile ?? DriverProfile.default
            let emptyWeight = profile.estimatedEmptyWeight

            // Update cost calculator
            costCalculator = CostCalculator(
                baseMPG: profile.baseMPG,
                baseWeight: Constants.defaultBaseWeight,
                mpgPenaltyPerPound: Constants.defaultMPGPenaltyPerPound,
                fuelPricePerGallon: fuelPrice,
                milesPerDay: Constants.defaultMilesPerDay,
                nightlyRate: nightlyRate
            )

            // Build all route requests upfront
            let segmentRequests = buildSegmentRequests(emptyWeight: emptyWeight)
            estimatedSegments = segmentRequests.count
            calculationProgress = "Fetching \(segmentRequests.count) route segments..."

            try Task.checkCancellation()

            // Fetch all routes in parallel with timeout
            let routes = try await withTimeout(seconds: calculationTimeout) {
                try await self.fetchRoutesInParallel(requests: segmentRequests)
            }

            try Task.checkCancellation()
            calculationProgress = "Building cost analysis..."

            // Build segments from cached routes
            var segments: [RouteSegment] = []
            for (index, request) in segmentRequests.enumerated() {
                try Task.checkCancellation()

                guard let route = routes["\(request.origin)|\(request.destination)"] else {
                    throw AppleMapError.noRouteFound
                }

                var segment = buildSegmentFromRoute(
                    route: route,
                    type: request.type,
                    weight: request.weight
                )
                segment.dropWeight = request.dropWeight
                segments.append(segment)

                completedSegments = index + 1
            }

            scenario.segments = segments
            currentScenario = scenario
            showingResults = true
            calculationProgress = ""

            // Save last used lumper charge for prefill
            let maxLumper = max(pickupLumperCharge, dropLocations.map { $0.lumperCharge }.max() ?? 0)
            if maxLumper > 0 {
                defaultLumperCharge = maxLumper
            }

        } catch is CancellationError {
            // Already handled in cancelCalculation
            return
        } catch is TimeoutError {
            errorMessage = "Unable to calculate route. One or more addresses could not be resolved. Use specific addresses (e.g., '1234 Main St, Dallas, TX 75201')."
        } catch let error as AppleMapError {
            switch error {
            case .locationNotFound(let address):
                errorMessage = "Address not found: \(address)"
            case .noRouteFound:
                errorMessage = "No driving route exists between these locations."
            }
        } catch {
            errorMessage = "Route calculation failed. Check addresses and try again."
        }

        isCalculating = false
        isValidatingLocations = false
        calculationProgress = ""
    }

    /// Execute async work with a timeout
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }

            // Return first result, cancel the other
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    // MARK: - Parallel Route Fetching

    private struct SegmentRequest {
        let type: SegmentType
        let origin: String
        let destination: String
        let weight: Double
        let dropWeight: Double
    }

    /// Build all segment requests upfront so we know all origin-destination pairs
    private func buildSegmentRequests(emptyWeight: Double) -> [SegmentRequest] {
        var requests: [SegmentRequest] = []
        var previousLocation = currentLocation

        // Segment 1: Deadhead to trailer
        if needsTrailerPickup && !trailerPickupLocation.isEmpty {
            requests.append(SegmentRequest(
                type: .deadheadToTrailer,
                origin: previousLocation,
                destination: trailerPickupLocation,
                weight: emptyWeight - 14000,
                dropWeight: 0
            ))
            previousLocation = trailerPickupLocation
        }

        // Segment 2: Deadhead to pickup
        let actualPickupLocation: String
        if loadPickupSameAsCurrentLocation {
            actualPickupLocation = currentLocation
        } else if needsTrailerPickup && loadPickupSameAsTrailer {
            actualPickupLocation = trailerPickupLocation
        } else {
            actualPickupLocation = loadPickupLocation
        }
        if previousLocation != actualPickupLocation && !actualPickupLocation.isEmpty {
            requests.append(SegmentRequest(
                type: .deadheadToPickup,
                origin: previousLocation,
                destination: actualPickupLocation,
                weight: emptyWeight,
                dropWeight: 0
            ))
            previousLocation = actualPickupLocation
        }

        // Segment 3+: Loaded segments to each drop
        var remainingWeight = totalLoadWeight
        for (index, drop) in dropLocations.enumerated() {
            let currentWeight = emptyWeight + remainingWeight
            let segmentType: SegmentType = index == 0 ? .pickupToDelivery : .deliveryToDelivery

            requests.append(SegmentRequest(
                type: segmentType,
                origin: previousLocation,
                destination: drop.address,
                weight: currentWeight,
                dropWeight: drop.weightToDrop
            ))

            remainingWeight -= drop.weightToDrop
            previousLocation = drop.address
        }

        // Final segment: Deadhead to drop trailer
        if willHaveTrailer {
            let actualTrailerDrop = trailerDropSameAsLastDelivery ? dropLocations.last?.address ?? "" : trailerDropLocation
            if !actualTrailerDrop.isEmpty && previousLocation != actualTrailerDrop {
                requests.append(SegmentRequest(
                    type: .deadheadToDropTrailer,
                    origin: previousLocation,
                    destination: actualTrailerDrop,
                    weight: emptyWeight,
                    dropWeight: 0
                ))
            }
        }

        return requests
    }

    /// Fetch all routes in parallel using TaskGroup
    private func fetchRoutesInParallel(requests: [SegmentRequest]) async throws -> [String: Route] {
        // Deduplicate route requests (same origin-destination may appear multiple times)
        var uniquePairs: Set<String> = []
        var pairsToFetch: [(origin: String, destination: String)] = []

        for request in requests {
            let key = "\(request.origin)|\(request.destination)"
            if !uniquePairs.contains(key) {
                uniquePairs.insert(key)
                pairsToFetch.append((request.origin, request.destination))
            }
        }

        // Fetch all routes in parallel (no nested timeout - outer timeout handles overall time)
        var routes: [String: Route] = [:]

        try await withThrowingTaskGroup(of: (String, Route?).self) { group in
            for pair in pairsToFetch {
                group.addTask {
                    // Check for cancellation before starting
                    try Task.checkCancellation()

                    let route = try await self.mapService.fetchRoute(from: pair.origin, to: pair.destination)
                    return ("\(pair.origin)|\(pair.destination)", route)
                }
            }

            for try await (key, route) in group {
                // Check for cancellation between results
                try Task.checkCancellation()

                if let route = route {
                    routes[key] = route
                }
            }
        }

        return routes
    }

    /// Build a segment from a pre-fetched route
    private func buildSegmentFromRoute(route: Route, type: SegmentType, weight: Double) -> RouteSegment {
        let effectiveMPG = costCalculator.calculateEffectiveMPG(totalWeight: weight)
        let breakdown = costCalculator.calculateCostBreakdown(
            distanceMiles: route.distanceMiles,
            totalWeight: weight,
            overnightNightsOverride: nil
        )

        var segment = RouteSegment(
            segmentType: type,
            origin: route.origin,
            destination: route.destination,
            distanceMiles: route.distanceMiles,
            weightAtSegment: weight
        )
        segment.originCoordinate = route.originCoordinate
        segment.destinationCoordinate = route.destinationCoordinate
        segment.routePolyline = route.routePolyline
        segment.statesTraversed = route.statesTraversed
        segment.effectiveMPG = effectiveMPG
        segment.fuelCost = breakdown.fuelCost
        segment.overnightCost = breakdown.overnightCost
        segment.numberOfNights = breakdown.numberOfNights

        return segment
    }

    // MARK: - Scenario Management

    var isCurrentScenarioSaved: Bool {
        guard let current = currentScenario else { return false }
        return scenarios.contains { $0.id == current.id }
    }

    func saveCurrentScenario() {
        guard let scenario = currentScenario else { return }
        // Check if already saved
        guard !scenarios.contains(where: { $0.id == scenario.id }) else { return }
        scenarios.append(scenario)
        showSaveConfirmation = true

        // Hide confirmation after delay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showSaveConfirmation = false
        }
    }

    func startNewScenario() {
        // Save current if exists
        if let current = currentScenario {
            scenarios.append(current)
        }

        // Reset form
        loadRate = ""
        currentLocation = ""
        trailerPickupLocation = ""
        loadPickupLocation = ""
        loadPickupSameAsTrailer = false
        loadPickupSameAsCurrentLocation = false
        dropLocations = [DropLocation()]
        trailerDropLocation = ""
        trailerDropSameAsLastDelivery = false
        totalLoadWeight = 0
        pickupLumperCharge = 0
        currentScenario = nil
        showingResults = false
        errorMessage = nil
    }

    func clearAllScenarios() {
        scenarios.removeAll()
        startNewScenario()
    }

    func deleteScenario(_ scenario: LoadScenario) {
        scenarios.removeAll { $0.id == scenario.id }
    }

}
