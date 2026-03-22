import SwiftUI

struct ScenarioInputView: View {
    @ObservedObject var viewModel: ScenarioCalculatorViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
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
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Load Rate Section

    private var loadRateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Load Rate", systemImage: "dollarsign.circle.fill")
                .font(.headline)
                .foregroundColor(.green)

            HStack {
                Text("$")
                    .font(.title2)
                    .foregroundColor(.secondary)
                TextField("0.00", text: $viewModel.loadRate)
                    .font(.title)
                    .fontWeight(.bold)
                    .keyboardType(.decimalPad)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)

            Text("Price offered for this load")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
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
                onSelect: viewModel.selectCurrentLocation
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .onChange(of: viewModel.locationManager.currentAddress) { _, newAddress in
            if let address = newAddress {
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
                } else {
                    Image(systemName: "location.circle.fill")
                }
                Text("GPS")
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(viewModel.locationManager.isAuthorized ? Color.blue : Color.gray)
            .foregroundColor(.white)
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
                onSelect: viewModel.selectTrailerPickup
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

            if viewModel.needsTrailerPickup {
                Toggle("Same as trailer pickup", isOn: $viewModel.loadPickupSameAsTrailer)
                    .tint(.blue)
            }

            if !viewModel.loadPickupSameAsTrailer || !viewModel.needsTrailerPickup {
                locationTextField(
                    text: $viewModel.loadPickupLocation,
                    placeholder: "Load pickup location",
                    suggestions: viewModel.loadPickupSuggestions,
                    onSearch: viewModel.searchLoadPickup,
                    onSelect: viewModel.selectLoadPickup
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
                TextField("0", value: $viewModel.pickupLumperCharge, format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Stop \(index + 1)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
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
            .onChange(of: viewModel.dropLocations[safe: index]?.address ?? "") { _, _ in
                viewModel.searchDropLocation(query: viewModel.dropLocations[safe: index]?.address ?? "", index: index)
            }

            // Suggestions
            if index < viewModel.dropLocationSuggestions.count {
                ForEach(viewModel.dropLocationSuggestions[index]) { suggestion in
                    Button(action: { viewModel.selectDropLocation(suggestion, at: index) }) {
                        HStack {
                            Image(systemName: "mappin")
                            Text(suggestion.displayText)
                                .lineLimit(1)
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
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
                    onSelect: viewModel.selectTrailerDrop
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Calculate Button

    private var calculateButton: some View {
        Button(action: {
            Task { await viewModel.calculateScenario() }
        }) {
            HStack {
                if viewModel.isCalculating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                }
                Text(viewModel.isCalculating ? "Calculating..." : "Calculate Profitability")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.canCalculate ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!viewModel.canCalculate || viewModel.isCalculating)
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
        onSelect: @escaping (LocationSuggestion) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
                .onChange(of: text.wrappedValue) { _, _ in
                    onSearch()
                }

            ForEach(suggestions.prefix(3)) { suggestion in
                Button(action: { onSelect(suggestion) }) {
                    HStack {
                        Image(systemName: "mappin")
                        Text(suggestion.displayText)
                            .lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
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

#Preview {
    ScenarioInputView(viewModel: ScenarioCalculatorViewModel())
}
