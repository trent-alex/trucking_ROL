import Foundation
import SwiftUI

@MainActor
class RouteCalculatorViewModel: ObservableObject {
    // MARK: - Route Input
    @Published var origin: String = ""
    @Published var destination: String = ""
    @Published var originSuggestions: [PlaceSuggestion] = []
    @Published var destinationSuggestions: [PlaceSuggestion] = []

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

    // MARK: - Services
    private let googleMapsService: GoogleMapsService
    private var costCalculator: CostCalculator

    // MARK: - Debounce
    private var searchTask: Task<Void, Never>?

    init() {
        self.googleMapsService = GoogleMapsService()
        self.costCalculator = CostCalculator()
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

    private func searchPlaces(query: String, completion: @escaping ([PlaceSuggestion]) -> Void) {
        searchTask?.cancel()
        searchTask = Task {
            // Debounce
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            do {
                let suggestions = try await googleMapsService.fetchPlaceSuggestions(query: query)
                completion(suggestions)
            } catch {
                completion([])
            }
        }
    }

    func selectOrigin(_ suggestion: PlaceSuggestion) {
        origin = suggestion.description
        originSuggestions = []
    }

    func selectDestination(_ suggestion: PlaceSuggestion) {
        destination = suggestion.description
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
                let fetchedRoute = try await googleMapsService.fetchRoute(
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

        let tollCost = route.tollInfo?.estimatedCost ?? 0
        suggestedNights = costCalculator.calculateSuggestedNights(distanceMiles: route.distanceMiles)

        costBreakdown = costCalculator.calculateCostBreakdown(
            distanceMiles: route.distanceMiles,
            totalWeight: totalWeight,
            tollCost: tollCost,
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
    }
}
