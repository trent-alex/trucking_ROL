import Foundation
import SwiftUI
import CoreLocation
import Combine

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

    func calculateScenario() async {
        guard canCalculate else { return }

        isCalculating = true
        errorMessage = nil

        do {
            var scenario = LoadScenario(
                loadRate: Double(loadRate) ?? 0,
                pickupLumperCharge: pickupLumperCharge,
                dropLumperCharges: dropLocations.map { $0.lumperCharge }
            )
            var segments: [RouteSegment] = []

            let profile = driverProfile ?? DriverProfile.default
            let emptyWeight = profile.estimatedEmptyWeight
            let loadedWeight = emptyWeight + totalLoadWeight

            // Update cost calculator
            costCalculator = CostCalculator(
                baseMPG: profile.baseMPG,
                baseWeight: Constants.defaultBaseWeight,
                mpgPenaltyPerPound: Constants.defaultMPGPenaltyPerPound,
                fuelPricePerGallon: fuelPrice,
                milesPerDay: Constants.defaultMilesPerDay,
                nightlyRate: nightlyRate
            )

            // Pre-resolve happens on location selection, no delay needed here

            // Build route segments based on configuration
            var previousLocation = currentLocation

            // Segment 1: Deadhead to trailer (only if driver needs to pick up a trailer)
            if needsTrailerPickup && !trailerPickupLocation.isEmpty {
                let segment = try await buildSegment(
                    type: .deadheadToTrailer,
                    from: previousLocation,
                    to: trailerPickupLocation,
                    weight: emptyWeight - 14000  // Bobtail weight without trailer
                )
                segments.append(segment)
                previousLocation = trailerPickupLocation
            }

            // Segment 2: Deadhead to pickup (if different from current location or trailer)
            let actualPickupLocation: String
            if loadPickupSameAsCurrentLocation {
                actualPickupLocation = currentLocation
            } else if needsTrailerPickup && loadPickupSameAsTrailer {
                actualPickupLocation = trailerPickupLocation
            } else {
                actualPickupLocation = loadPickupLocation
            }
            if previousLocation != actualPickupLocation && !actualPickupLocation.isEmpty {
                let segment = try await buildSegment(
                    type: .deadheadToPickup,
                    from: previousLocation,
                    to: actualPickupLocation,
                    weight: emptyWeight
                )
                segments.append(segment)
                previousLocation = actualPickupLocation
            }

            // Segment 3+: Loaded segments to each drop
            var remainingWeight = totalLoadWeight
            for (index, drop) in dropLocations.enumerated() {
                let currentWeight = emptyWeight + remainingWeight
                let segmentType: SegmentType = index == 0 ? .pickupToDelivery : .deliveryToDelivery

                var segment = try await buildSegment(
                    type: segmentType,
                    from: previousLocation,
                    to: drop.address,
                    weight: currentWeight
                )
                segment.dropWeight = drop.weightToDrop
                segments.append(segment)

                remainingWeight -= drop.weightToDrop
                previousLocation = drop.address
            }

            // Segment: Deadhead to drop trailer (if different from last delivery)
            if willHaveTrailer {
                let actualTrailerDrop = trailerDropSameAsLastDelivery ? dropLocations.last?.address ?? "" : trailerDropLocation
                if !actualTrailerDrop.isEmpty && previousLocation != actualTrailerDrop {
                    let segment = try await buildSegment(
                        type: .deadheadToDropTrailer,
                        from: previousLocation,
                        to: actualTrailerDrop,
                        weight: emptyWeight
                    )
                    segments.append(segment)
                }
            }

            scenario.segments = segments
            currentScenario = scenario
            showingResults = true

            // Save last used lumper charge for prefill
            let maxLumper = max(pickupLumperCharge, dropLocations.map { $0.lumperCharge }.max() ?? 0)
            if maxLumper > 0 {
                defaultLumperCharge = maxLumper
            }

        } catch {
            errorMessage = error.localizedDescription
        }

        isCalculating = false
    }

    private func buildSegment(
        type: SegmentType,
        from origin: String,
        to destination: String,
        weight: Double
    ) async throws -> RouteSegment {
        let route = try await mapService.fetchRoute(from: origin, to: destination)

        let effectiveMPG = costCalculator.calculateEffectiveMPG(totalWeight: weight)
        let breakdown = costCalculator.calculateCostBreakdown(
            distanceMiles: route.distanceMiles,
            totalWeight: weight,
            overnightNightsOverride: nil
        )

        var segment = RouteSegment(
            segmentType: type,
            origin: origin,
            destination: destination,
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

    // MARK: - Performance Optimization

    /// Pre-resolve all locations in parallel before route calculation
    private func preResolveAllLocations() async {
        var locationsToResolve: [String] = []

        // Current location
        if !currentLocation.isEmpty {
            locationsToResolve.append(currentLocation)
        }

        // Trailer pickup
        if needsTrailerPickup && !trailerPickupLocation.isEmpty {
            locationsToResolve.append(trailerPickupLocation)
        }

        // Load pickup
        if !loadPickupSameAsTrailer && !loadPickupLocation.isEmpty {
            locationsToResolve.append(loadPickupLocation)
        }

        // All drop locations
        for drop in dropLocations where !drop.address.isEmpty {
            locationsToResolve.append(drop.address)
        }

        // Trailer drop
        if willHaveTrailer && !trailerDropSameAsLastDelivery && !trailerDropLocation.isEmpty {
            locationsToResolve.append(trailerDropLocation)
        }

        // Fire off all pre-resolutions (each spawns its own background task)
        for location in locationsToResolve {
            mapService.preResolveLocation(location)
        }

        // Brief pause to let geocoding requests start
        try? await Task.sleep(nanoseconds: 150_000_000) // 150ms head start
    }
}
