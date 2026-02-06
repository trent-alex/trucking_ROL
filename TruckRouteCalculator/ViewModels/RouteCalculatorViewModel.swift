import Foundation
import SwiftUI
import SwiftData
import CoreLocation
import Combine

@MainActor
class RouteCalculatorViewModel: ObservableObject {
    // MARK: - Route Input
    @Published var origin: String = ""
    @Published var destination: String = ""
    @Published var originSuggestions: [LocationSuggestion] = []
    @Published var destinationSuggestions: [LocationSuggestion] = []

    // MARK: - Load Configuration
    @Published var emptyTruckWeight: Double = Constants.defaultBaseWeight
    @Published var loadWeight: Double = 0

    var totalWeight: Double {
        emptyTruckWeight + loadWeight
    }

    // MARK: - Settings
    @Published var baseMPG: Double = Constants.defaultBaseMPG
    @Published var fuelPrice: Double = Constants.defaultFuelPrice
    @Published var nightlyRate: Double = Constants.defaultNightlyRate

    // MARK: - Results
    @Published var route: Route?
    @Published var costBreakdown: CostBreakdown = .empty
    @Published var overnightNightsOverride: Int?
    @Published var suggestedNights: Int = 0

    // MARK: - UI State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingResults: Bool = false
    @Published var routeSaved: Bool = false

    // MARK: - Fuel Price Source
    @Published var usingDefaultFuelPrice: Bool = false

    // MARK: - Services
    private let appleMapService: AppleMapService
    private let fuelPriceService: FuelPriceService
    private var costCalculator: CostCalculator

    // MARK: - Debounce
    private var searchTask: Task<Void, Never>?

    init() {
        self.appleMapService = AppleMapService()
        self.fuelPriceService = FuelPriceService()
        self.costCalculator = CostCalculator()
        Task { await fetchFuelPrice() }
    }

    private func fetchFuelPrice() async {
        if let price = await fuelPriceService.fetchDieselPrice() {
            self.fuelPrice = price
            self.usingDefaultFuelPrice = false
        } else {
            self.fuelPrice = Constants.defaultFuelPrice
            self.usingDefaultFuelPrice = true
        }
    }

    // MARK: - Computed Properties

    var effectiveMPG: Double {
        costCalculator.calculateEffectiveMPG(totalWeight: totalWeight)
    }

    var canCalculate: Bool {
        !origin.isEmpty && !destination.isEmpty
    }

    var actualNights: Int {
        overnightNightsOverride ?? suggestedNights
    }

    // MARK: - Actions

    func searchOrigin() {
        searchPlaces(query: origin) { [weak self] suggestions in
            self?.originSuggestions = suggestions
        }
    }

    func searchDestination() {
        searchPlaces(query: destination) { [weak self] suggestions in
            self?.destinationSuggestions = suggestions
        }
    }

    private func searchPlaces(query: String, completion: @escaping ([LocationSuggestion]) -> Void) {
        searchTask?.cancel()
        searchTask = Task {
            // Debounce
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            appleMapService.searchPlaces(query: query, completion: completion)
        }
    }

    func selectOrigin(_ suggestion: LocationSuggestion) {
        origin = suggestion.displayText
        originSuggestions = []
    }

    func selectDestination(_ suggestion: LocationSuggestion) {
        destination = suggestion.displayText
        destinationSuggestions = []
    }

    func calculateRoute() {
        guard canCalculate else { return }

        isLoading = true
        errorMessage = nil
        originSuggestions = []
        destinationSuggestions = []

        Task {
            do {
                let fetchedRoute = try await appleMapService.fetchRoute(
                    from: origin,
                    to: destination
                )

                self.route = fetchedRoute
                self.updateCostCalculator()
                self.calculateCosts()
                self.showingResults = true
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }

    private func updateCostCalculator() {
        costCalculator = CostCalculator(
            baseMPG: baseMPG,
            baseWeight: Constants.defaultBaseWeight,
            mpgPenaltyPerPound: Constants.defaultMPGPenaltyPerPound,
            fuelPricePerGallon: fuelPrice,
            milesPerDay: Constants.defaultMilesPerDay,
            nightlyRate: nightlyRate
        )
    }

    func calculateCosts() {
        guard let route = route else { return }

        suggestedNights = costCalculator.calculateSuggestedNights(distanceMiles: route.distanceMiles)

        costBreakdown = costCalculator.calculateCostBreakdown(
            distanceMiles: route.distanceMiles,
            totalWeight: totalWeight,
            overnightNightsOverride: overnightNightsOverride
        )
    }

    func updateOvernightNights(_ nights: Int) {
        overnightNightsOverride = nights
        calculateCosts()
    }

    func resetOvernightToSuggested() {
        overnightNightsOverride = nil
        calculateCosts()
    }

    func reset() {
        origin = ""
        destination = ""
        route = nil
        costBreakdown = .empty
        overnightNightsOverride = nil
        suggestedNights = 0
        showingResults = false
        errorMessage = nil
        routeSaved = false
    }

    // MARK: - Route History

    func saveCurrentRoute(context: ModelContext) {
        guard let route = route else { return }

        let saved = SavedRoute(
            origin: route.origin,
            destination: route.destination,
            distanceMiles: route.distanceMiles,
            statesTraversed: route.statesTraversed,
            originLatitude: route.originCoordinate?.latitude ?? 0,
            originLongitude: route.originCoordinate?.longitude ?? 0,
            destinationLatitude: route.destinationCoordinate?.latitude ?? 0,
            destinationLongitude: route.destinationCoordinate?.longitude ?? 0,
            fuelCost: costBreakdown.fuelCost,
            overnightCost: costBreakdown.overnightCost,
            numberOfNights: costBreakdown.numberOfNights,
            totalCost: costBreakdown.totalCost,
            costPerMile: costBreakdown.costPerMile,
            emptyTruckWeight: emptyTruckWeight,
            loadWeight: loadWeight,
            baseMPG: baseMPG,
            effectiveMPG: effectiveMPG,
            fuelPrice: fuelPrice,
            nightlyRate: nightlyRate
        )

        context.insert(saved)
        routeSaved = true
    }

    func loadSavedRoute(_ saved: SavedRoute) {
        origin = saved.origin
        destination = saved.destination
        emptyTruckWeight = saved.emptyTruckWeight
        loadWeight = saved.loadWeight
        baseMPG = saved.baseMPG
        fuelPrice = saved.fuelPrice
        nightlyRate = saved.nightlyRate
        routeSaved = false
        calculateRoute()
    }
}
