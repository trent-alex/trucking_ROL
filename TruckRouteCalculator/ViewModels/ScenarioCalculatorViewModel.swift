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
    @Published var scenarios: [LoadScenario] = []
    @Published var showingResults: Bool = false

    // MARK: - Profile
    @Published var driverProfile: DriverProfile?

    // MARK: - Services
    private let mapService: AppleMapService
    private let fuelPriceService: FuelPriceService
    private var costCalculator: CostCalculator
    let locationManager: LocationManager

    // MARK: - Settings
    @Published var fuelPrice: Double = Constants.defaultFuelPrice
    @Published var nightlyRate: Double = Constants.defaultNightlyRate

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

        guard !loadPickupLocation.isEmpty || loadPickupSameAsTrailer else { return false }
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
    }

    func selectTrailerPickup(_ suggestion: LocationSuggestion) {
        trailerPickupLocation = suggestion.displayText
        trailerPickupSuggestions = []
    }

    func selectLoadPickup(_ suggestion: LocationSuggestion) {
        loadPickupLocation = suggestion.displayText
        loadPickupSuggestions = []
    }

    func selectDropLocation(_ suggestion: LocationSuggestion, at index: Int) {
        guard index < dropLocations.count else { return }
        dropLocations[index].address = suggestion.displayText
        if index < dropLocationSuggestions.count {
            dropLocationSuggestions[index] = []
        }
    }

    func selectTrailerDrop(_ suggestion: LocationSuggestion) {
        trailerDropLocation = suggestion.displayText
        trailerDropSuggestions = []
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
            if needsTrailerPickup && loadPickupSameAsTrailer {
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

    func saveCurrentScenario() {
        guard let scenario = currentScenario else { return }
        scenarios.append(scenario)
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
