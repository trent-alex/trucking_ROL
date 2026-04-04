import SwiftUI
import Combine

struct ScenarioInputView: View {
    @ObservedObject var viewModel: ScenarioCalculatorViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Saved Loads Gallery (if any)
                if !viewModel.scenarios.isEmpty {
                    savedLoadsGallery
                }

                // Load Rate Section
                loadRateSection

                // Current Location
                currentLocationSection

                // Trailer Pickup (only if driver needs to pick up a trailer)
                if viewModel.needsTrailerPickup {
                    trailerPickupSection
                }

                // Load Pickup
                loadPickupSection

                // Load Weight
                loadWeightSection

                // Drop Locations
                dropLocationsSection

                // Trailer Drop (if driver will have a trailer)
                if viewModel.willHaveTrailer {
                    trailerDropSection
                }

                // Calculate Button
                calculateButton

                // Error Message
                if let error = viewModel.errorMessage {
                    errorView(error)
                }
            }
            .padding()
            .frame(maxWidth: horizontalSizeClass == .regular ? 700 : .infinity)
            .frame(maxWidth: .infinity)
        }
        .background(AppTheme.backgroundPrimary)
    }

    // MARK: - Saved Loads Gallery

    private var savedLoadsGallery: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(AppTheme.textOnDark)
                    .padding(6)
                    .background(AppTheme.darkCard)
                    .cornerRadius(8)
                Text("Saved Loads")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text("\(viewModel.scenarios.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.backgroundSecondary)
                    .cornerRadius(8)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.scenarios.sorted(by: { $0.createdAt > $1.createdAt }).prefix(5)) { scenario in
                        savedLoadCard(scenario)
                    }

                    // View All button if more than 5
                    if viewModel.scenarios.count > 5 {
                        NavigationLink(destination: SavedLoadsView(viewModel: viewModel)) {
                            VStack {
                                Image(systemName: "ellipsis.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(AppTheme.textSecondary)
                                Text("View All")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            .frame(width: 80, height: 100)
                            .background(AppTheme.backgroundSecondary)
                            .cornerRadius(12)
                        }
                    }
                }
            }

            // Quick Stats
            HStack(spacing: 16) {
                let totalProfit = viewModel.scenarios.reduce(0) { $0 + $1.profit }
                let avgProfitPerMile = viewModel.scenarios.isEmpty ? 0 : viewModel.scenarios.reduce(0) { $0 + $1.profitPerMile } / Double(viewModel.scenarios.count)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Logged")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                    Text(totalProfit >= 0 ? "+$\(String(format: "%.0f", totalProfit))" : "-$\(String(format: "%.0f", abs(totalProfit)))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(totalProfit >= 0 ? AppTheme.profit : AppTheme.loss)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Avg $/Mile")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                    Text("$\(String(format: "%.2f", avgProfitPerMile))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(avgProfitPerMile >= 0 ? AppTheme.profit : AppTheme.loss)
                }

                Spacer()
            }
        }
        .themedCard()
    }

    private func savedLoadCard(_ scenario: LoadScenario) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Profit/Loss indicator
            HStack {
                Circle()
                    .fill(scenario.isProfitable ? AppTheme.profit : AppTheme.loss)
                    .frame(width: 8, height: 8)
                Text(scenario.isProfitable ? "Profit" : "Loss")
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
            }

            // Profit amount
            Text(scenario.profit >= 0 ? "+$\(String(format: "%.0f", scenario.profit))" : "-$\(String(format: "%.0f", abs(scenario.profit)))")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(scenario.isProfitable ? AppTheme.profit : AppTheme.loss)

            // Route info
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(scenario.totalMiles)) mi")
                    .font(.caption)
                    .foregroundColor(AppTheme.textPrimary)
                Text("$\(String(format: "%.2f", scenario.profitPerMile))/mi")
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
            }

            // Date
            Text(scenario.createdAt, style: .date)
                .font(.caption2)
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(12)
        .frame(width: 120)
        .background(AppTheme.backgroundCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(scenario.isProfitable ? AppTheme.profit.opacity(0.3) : AppTheme.loss.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Load Rate Section

    private var loadRateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(AppTheme.textOnAccent)
                    .padding(6)
                    .background(AppTheme.accent)
                    .cornerRadius(8)
                Text("Load Rate")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
            }

            HStack {
                Text("$")
                    .font(.title2)
                    .foregroundColor(AppTheme.textSecondary)
                TextField("0.00", text: $viewModel.loadRate)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .keyboardType(.decimalPad)
            }
            .padding()
            .background(AppTheme.backgroundSecondary)
            .cornerRadius(12)

            Text("Price offered for this load")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .themedCard()
    }

    // MARK: - Current Location

    private var currentLocationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Current Location", systemImage: "location.fill")
                    .font(.headline)
                Spacer()
                gpsButton
            }

            locationTextField(
                text: $viewModel.currentLocation,
                placeholder: "Where are you now?",
                suggestions: viewModel.currentLocationSuggestions,
                onSearch: viewModel.searchCurrentLocation,
                onSelect: viewModel.selectCurrentLocation,
                fieldName: "currentLocation"
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .onReceive(viewModel.locationManager.$currentAddress) { newAddress in
            if let address = newAddress, !address.isEmpty {
                viewModel.currentLocation = address
                viewModel.currentLocationSuggestions = []
            }
        }
    }

    private var gpsButton: some View {
        Button(action: {
            viewModel.useCurrentGPSLocation()
        }) {
            HStack(spacing: 4) {
                if viewModel.locationManager.isLocating {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(AppTheme.textOnAccent)
                } else {
                    Image(systemName: "location.circle.fill")
                }
                Text("GPS")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(viewModel.locationManager.isAuthorized ? AppTheme.darkCard : AppTheme.border)
            .foregroundColor(viewModel.locationManager.isAuthorized ? AppTheme.textOnDark : AppTheme.textSecondary)
            .cornerRadius(8)
        }
        .disabled(viewModel.locationManager.isLocating)
    }

    // MARK: - Trailer Pickup

    private var trailerPickupSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Pickup Trailer", systemImage: "arrow.right.circle")
                .font(.headline)

            locationTextField(
                text: $viewModel.trailerPickupLocation,
                placeholder: "Trailer pickup location",
                suggestions: viewModel.trailerPickupSuggestions,
                onSearch: viewModel.searchTrailerPickup,
                onSelect: viewModel.selectTrailerPickup,
                fieldName: "trailerPickup"
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Load Pickup

    private var loadPickupSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Pickup Load", systemImage: "shippingbox.fill")
                .font(.headline)

            // Use current location toggle
            Toggle(isOn: $viewModel.loadPickupSameAsCurrentLocation) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    Text("Use current location")
                }
            }
            .tint(.blue)
            .onChange(of: viewModel.loadPickupSameAsCurrentLocation) { _, isOn in
                if isOn {
                    viewModel.loadPickupSameAsTrailer = false
                }
            }

            if viewModel.needsTrailerPickup && !viewModel.loadPickupSameAsCurrentLocation {
                Toggle("Same as trailer pickup", isOn: $viewModel.loadPickupSameAsTrailer)
                    .tint(.blue)
                    .onChange(of: viewModel.loadPickupSameAsTrailer) { _, isOn in
                        if isOn {
                            viewModel.loadPickupSameAsCurrentLocation = false
                        }
                    }
            }

            if !viewModel.loadPickupSameAsTrailer && !viewModel.loadPickupSameAsCurrentLocation {
                locationTextField(
                    text: $viewModel.loadPickupLocation,
                    placeholder: "Load pickup location",
                    suggestions: viewModel.loadPickupSuggestions,
                    onSearch: viewModel.searchLoadPickup,
                    onSelect: viewModel.selectLoadPickup,
                    fieldName: "loadPickup"
                )
            }

            // Pickup lumper charge
            HStack {
                Image(systemName: "person.fill.badge.plus")
                    .foregroundColor(.orange)
                Text("Pickup Lumper:")
                    .font(.subheadline)
                Spacer()
                Text("$")
                    .foregroundColor(.secondary)
                TextField(viewModel.defaultLumperCharge > 0 ? String(format: "%.0f", viewModel.defaultLumperCharge) : "0", value: $viewModel.pickupLumperCharge, format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)
            }
            if viewModel.defaultLumperCharge > 0 && viewModel.pickupLumperCharge == 0 {
                Text("Last used: $\(String(format: "%.0f", viewModel.defaultLumperCharge))")
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Load Weight

    private var loadWeightSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Load Weight", systemImage: "scalemass.fill")
                .font(.headline)

            HStack {
                TextField("0", value: $viewModel.totalLoadWeight, format: .number)
                    .font(.title2)
                    .keyboardType(.numberPad)
                Text("lbs")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)

            if let profile = viewModel.driverProfile {
                let totalWeight = profile.estimatedEmptyWeight + viewModel.totalLoadWeight
                HStack {
                    Text("Total weight:")
                    Spacer()
                    Text("\(Int(totalWeight).formatted()) lbs")
                        .fontWeight(.semibold)
                        .foregroundColor(totalWeight > 80000 ? .red : .primary)
                }
                .font(.caption)

                if totalWeight > 80000 {
                    Label("Exceeds 80,000 lb federal limit", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Drop Locations

    private var dropLocationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Delivery Stops", systemImage: "mappin.circle.fill")
                    .font(.headline)
                Spacer()
                Button(action: viewModel.addDropLocation) {
                    Label("Add Stop", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
            }

            ForEach(Array(viewModel.dropLocations.enumerated()), id: \.element.id) { index, drop in
                dropLocationRow(index: index, drop: drop)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private func dropLocationRow(index: Int, drop: DropLocation) -> some View {
        let fieldName = "drop_\(index)"
        let isInvalid = viewModel.isLocationInvalid(fieldName)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Stop \(index + 1)")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if isInvalid {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Spacer()
                if viewModel.dropLocations.count > 1 {
                    Button(action: { viewModel.removeDropLocation(at: index) }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }

            TextField("Delivery address", text: Binding(
                get: { viewModel.dropLocations[safe: index]?.address ?? "" },
                set: { viewModel.updateDropAddress($0, at: index) }
            ))
            .textFieldStyle(.roundedBorder)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isInvalid ? Color.red : Color.clear, lineWidth: 2)
            )
            .onChange(of: viewModel.dropLocations[safe: index]?.address ?? "") { _, _ in
                viewModel.searchDropLocation(query: viewModel.dropLocations[safe: index]?.address ?? "", index: index)
                if isInvalid {
                    viewModel.clearValidationError(for: fieldName)
                }
            }

            if isInvalid {
                Text("Location not found")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            // Suggestions
            if index < viewModel.dropLocationSuggestions.count {
                let stableSuggestions = Array(viewModel.dropLocationSuggestions[index].prefix(3))
                ForEach(stableSuggestions) { suggestion in
                    dropSuggestionRow(suggestion: suggestion, index: index)
                }
            }

            if viewModel.dropLocations.count > 1 {
                HStack {
                    Text("Weight to drop:")
                    TextField("0", value: Binding(
                        get: { viewModel.dropLocations[safe: index]?.weightToDrop ?? 0 },
                        set: { viewModel.updateDropWeight($0, at: index) }
                    ), format: .number)
                    .keyboardType(.numberPad)
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)
                    Text("lbs")
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
            }

            // Drop lumper charge
            HStack {
                Image(systemName: "person.fill.badge.minus")
                    .foregroundColor(.orange)
                Text("Lumper:")
                    .font(.caption)
                Spacer()
                Text("$")
                    .foregroundColor(.secondary)
                    .font(.caption)
                TextField("0", value: Binding(
                    get: { viewModel.dropLocations[safe: index]?.lumperCharge ?? 0 },
                    set: { viewModel.updateDropLumperCharge($0, at: index) }
                ), format: .number)
                .keyboardType(.decimalPad)
                .frame(width: 70)
                .textFieldStyle(.roundedBorder)
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Trailer Drop

    private var trailerDropSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Drop Trailer", systemImage: "arrow.left.circle")
                .font(.headline)

            Toggle("Same as last delivery", isOn: $viewModel.trailerDropSameAsLastDelivery)
                .tint(.blue)

            if !viewModel.trailerDropSameAsLastDelivery {
                locationTextField(
                    text: $viewModel.trailerDropLocation,
                    placeholder: "Trailer drop location",
                    suggestions: viewModel.trailerDropSuggestions,
                    onSearch: viewModel.searchTrailerDrop,
                    onSelect: viewModel.selectTrailerDrop,
                    fieldName: "trailerDrop"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Calculate Button

    private var calculateButton: some View {
        VStack(spacing: 12) {
            // Show validation errors if any
            if !viewModel.invalidLocations.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(viewModel.validationMessage ?? "Some locations could not be found")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            if viewModel.isValidatingLocations {
                // Validating state
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Validating locations...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            } else if viewModel.isCalculating {
                // Calculating state - show progress and cancel
                calculatingView
            } else {
                // Normal calculate button
                Button(action: {
                    viewModel.startCalculation()
                }) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Calculate Profitability")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canCalculate ? AppTheme.accent : AppTheme.border)
                    .foregroundColor(viewModel.canCalculate ? AppTheme.textOnAccent : AppTheme.textSecondary)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.canCalculate)
            }
        }
    }

    // MARK: - Calculating View

    private var calculatingView: some View {
        VStack(spacing: 20) {
            // Animated truck icon
            HStack(spacing: 12) {
                Image(systemName: "truck.box.fill")
                    .font(.title)
                    .foregroundColor(AppTheme.accent)
                    .symbolEffect(.pulse)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Calculating Route")
                        .font(.headline)
                        .foregroundColor(.primary)

                    EncouragementView()
                }

                Spacer()
            }

            // Cancel button
            Button(action: {
                viewModel.cancelCalculation()
            }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("Cancel & Edit Addresses")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.red)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(error)
                .font(.subheadline)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Location TextField Helper

    private func locationTextField(
        text: Binding<String>,
        placeholder: String,
        suggestions: [LocationSuggestion],
        onSearch: @escaping () -> Void,
        onSelect: @escaping (LocationSuggestion) -> Void,
        fieldName: String = ""
    ) -> some View {
        let isInvalid = viewModel.isLocationInvalid(fieldName)

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                TextField(placeholder, text: text)
                    .textFieldStyle(.roundedBorder)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isInvalid ? Color.red : Color.clear, lineWidth: 2)
                    )
                    .onChange(of: text.wrappedValue) { _, _ in
                        onSearch()
                        // Clear validation error when user edits
                        if isInvalid {
                            viewModel.clearValidationError(for: fieldName)
                        }
                    }

                if isInvalid {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                }
            }

            if isInvalid {
                Text("Location not found")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            // Use a stable array to prevent re-renders during tap
            let stableSuggestions = Array(suggestions.prefix(3))
            ForEach(stableSuggestions) { suggestion in
                suggestionRow(suggestion: suggestion, onSelect: onSelect)
            }
        }
    }

    /// Separate view for suggestion row to prevent re-render issues
    private func suggestionRow(
        suggestion: LocationSuggestion,
        onSelect: @escaping (LocationSuggestion) -> Void
    ) -> some View {
        // Capture suggestion value immediately to survive re-renders
        let capturedSuggestion = suggestion

        return Button {
            // Dismiss keyboard first
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            // Select immediately - Button handles tap reliably
            onSelect(capturedSuggestion)
        } label: {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.blue)
                Text(suggestion.displayText)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "arrow.up.left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
            .foregroundColor(.primary)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    /// Suggestion row for drop locations
    private func dropSuggestionRow(suggestion: LocationSuggestion, index: Int) -> some View {
        // Capture values immediately to survive re-renders
        let capturedSuggestion = suggestion
        let capturedIndex = index

        return Button {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            viewModel.selectDropLocation(capturedSuggestion, at: capturedIndex)
        } label: {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.blue)
                Text(suggestion.displayText)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "arrow.up.left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
            .foregroundColor(.primary)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Encouragement View

struct EncouragementView: View {
    @State private var currentMessage: String = ""
    @State private var messageIndex: Int = 0
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    private let messages = [
        "Load profit around the corner...",
        "Building you an honest number...",
        "Crunching the miles...",
        "Calculating your bottom line...",
        "Finding the best route...",
        "Running the numbers...",
        "Checking fuel costs...",
        "Every mile counts...",
        "Your profit matters...",
        "Mapping your journey..."
    ]

    var body: some View {
        Text(currentMessage)
            .font(.caption)
            .foregroundColor(.secondary)
            .italic()
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.5), value: currentMessage)
            .onAppear {
                currentMessage = messages.randomElement() ?? messages[0]
            }
            .onReceive(timer) { _ in
                withAnimation {
                    // Pick a different random message
                    var newMessage = messages.randomElement() ?? messages[0]
                    while newMessage == currentMessage && messages.count > 1 {
                        newMessage = messages.randomElement() ?? messages[0]
                    }
                    currentMessage = newMessage
                }
            }
    }
}

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Saved Loads Full View

struct SavedLoadsView: View {
    @ObservedObject var viewModel: ScenarioCalculatorViewModel
    @Environment(\.dismiss) private var dismiss

    var sortedScenarios: [LoadScenario] {
        viewModel.scenarios.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        List {
            // Summary Section
            Section {
                VStack(spacing: 16) {
                    HStack(spacing: 24) {
                        summaryStatView(
                            title: "Total Loads",
                            value: "\(viewModel.scenarios.count)",
                            color: AppTheme.textPrimary
                        )

                        let totalProfit = viewModel.scenarios.reduce(0) { $0 + $1.profit }
                        summaryStatView(
                            title: "Total Profit",
                            value: totalProfit >= 0 ? "+$\(String(format: "%.0f", totalProfit))" : "-$\(String(format: "%.0f", abs(totalProfit)))",
                            color: totalProfit >= 0 ? AppTheme.profit : AppTheme.loss
                        )

                        let totalMiles = viewModel.scenarios.reduce(0) { $0 + $1.totalMiles }
                        summaryStatView(
                            title: "Total Miles",
                            value: "\(Int(totalMiles).formatted())",
                            color: AppTheme.textPrimary
                        )
                    }

                    let avgProfitPerMile = viewModel.scenarios.isEmpty ? 0 : viewModel.scenarios.reduce(0) { $0 + $1.profitPerMile } / Double(viewModel.scenarios.count)
                    HStack {
                        Text("Average Profit per Mile:")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        Text("$\(String(format: "%.2f", avgProfitPerMile))")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(avgProfitPerMile >= 0 ? AppTheme.profit : AppTheme.loss)
                    }
                }
                .padding(.vertical, 8)
            }

            // Loads List
            Section("Load History") {
                ForEach(sortedScenarios) { scenario in
                    savedLoadRow(scenario)
                }
                .onDelete(perform: deleteScenarios)
            }
        }
        .navigationTitle("Saved Loads")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.scenarios.isEmpty {
                    Button("Clear All") {
                        viewModel.clearAllScenarios()
                    }
                    .foregroundColor(AppTheme.loss)
                }
            }
        }
    }

    private func summaryStatView(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func savedLoadRow(_ scenario: LoadScenario) -> some View {
        HStack {
            // Profit indicator
            Circle()
                .fill(scenario.isProfitable ? AppTheme.profit : AppTheme.loss)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text("$\(String(format: "%.0f", scenario.loadRate)) load")
                    .fontWeight(.semibold)

                HStack(spacing: 8) {
                    Text("\(Int(scenario.totalMiles)) mi")
                    Text("•")
                    Text("\(scenario.segments.count) stops")
                }
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)

                Text(scenario.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(scenario.profit >= 0 ? "+$\(String(format: "%.0f", scenario.profit))" : "-$\(String(format: "%.0f", abs(scenario.profit)))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(scenario.isProfitable ? AppTheme.profit : AppTheme.loss)

                Text("$\(String(format: "%.2f", scenario.profitPerMile))/mi")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func deleteScenarios(at offsets: IndexSet) {
        let scenariosToDelete = offsets.map { sortedScenarios[$0] }
        for scenario in scenariosToDelete {
            viewModel.deleteScenario(scenario)
        }
    }
}

#Preview {
    ScenarioInputView(viewModel: ScenarioCalculatorViewModel())
}

#Preview("Saved Loads") {
    NavigationView {
        SavedLoadsView(viewModel: ScenarioCalculatorViewModel())
    }
}
