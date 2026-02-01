import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: RouteCalculatorViewModel
    @Environment(\.dismiss) var dismiss

    @State private var baseMPGText: String = ""
    @State private var fuelPriceText: String = ""
    @State private var emptyWeightText: String = ""
    @State private var nightlyRateText: String = ""

    var body: some View {
        NavigationView {
            Form {
                // Fuel Settings
                Section(header: Text("Fuel Settings")) {
                    HStack {
                        Text("Base MPG")
                        Spacer()
                        TextField("MPG", text: $baseMPGText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .onSubmit { commitBaseMPG() }
                            .onChange(of: baseMPGText) {
                                if let val = Double(baseMPGText) {
                                    viewModel.baseMPG = val
                                }
                            }
                    }

                    HStack {
                        Text("Fuel Price")
                        if viewModel.usingDefaultFuelPrice {
                            Image(systemName: "wifi.slash")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        Spacer()
                        Text("$")
                        TextField("Price", text: $fuelPriceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .onSubmit { commitFuelPrice() }
                            .onChange(of: fuelPriceText) {
                                if let val = Double(fuelPriceText) {
                                    viewModel.fuelPrice = val
                                }
                            }
                        Text("/gal")
                            .foregroundColor(.secondary)
                    }
                    if viewModel.usingDefaultFuelPrice {
                        Text("EIA API unavailable — using default $3.50/gal")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                // Truck Settings
                Section(header: Text("Truck Settings")) {
                    HStack {
                        Text("Empty Weight")
                        Spacer()
                        TextField("Weight", text: $emptyWeightText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .onSubmit { commitEmptyWeight() }
                            .onChange(of: emptyWeightText) {
                                if let val = Double(emptyWeightText) {
                                    viewModel.emptyTruckWeight = val
                                }
                            }
                        Text("lbs")
                            .foregroundColor(.secondary)
                    }
                }

                // Overnight Settings
                Section(header: Text("Overnight Stays")) {
                    HStack {
                        Text("Nightly Rate")
                        Spacer()
                        Text("$")
                        TextField("Rate", text: $nightlyRateText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .onSubmit { commitNightlyRate() }
                            .onChange(of: nightlyRateText) {
                                if let val = Double(nightlyRateText) {
                                    viewModel.nightlyRate = val
                                }
                            }
                    }
                }

                // Info Section
                Section(header: Text("Calculation Info")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fuel Efficiency Formula")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("MPG = Base MPG - (Weight over 30,000 lbs x 0.00003)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overnight Stays")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Based on DOT Hours of Service: 11-hour driving limit (~550 miles/day at 50 mph average)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                // Reset
                Section {
                    Button(action: resetToDefaults) {
                        HStack {
                            Spacer()
                            Text("Reset to Defaults")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        commitAll()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            syncFromViewModel()
        }
    }

    private func syncFromViewModel() {
        baseMPGText = String(format: "%.1f", viewModel.baseMPG)
        fuelPriceText = String(format: "%.2f", viewModel.fuelPrice)
        emptyWeightText = "\(Int(viewModel.emptyTruckWeight))"
        nightlyRateText = "\(Int(viewModel.nightlyRate))"
    }

    private func commitBaseMPG() {
        if let val = Double(baseMPGText) { viewModel.baseMPG = val }
        baseMPGText = String(format: "%.1f", viewModel.baseMPG)
    }

    private func commitFuelPrice() {
        if let val = Double(fuelPriceText) { viewModel.fuelPrice = val }
        fuelPriceText = String(format: "%.2f", viewModel.fuelPrice)
    }

    private func commitEmptyWeight() {
        if let val = Double(emptyWeightText) { viewModel.emptyTruckWeight = val }
        emptyWeightText = "\(Int(viewModel.emptyTruckWeight))"
    }

    private func commitNightlyRate() {
        if let val = Double(nightlyRateText) { viewModel.nightlyRate = val }
        nightlyRateText = "\(Int(viewModel.nightlyRate))"
    }

    private func commitAll() {
        commitBaseMPG()
        commitFuelPrice()
        commitEmptyWeight()
        commitNightlyRate()
    }

    private func resetToDefaults() {
        viewModel.baseMPG = Constants.defaultBaseMPG
        viewModel.fuelPrice = Constants.defaultFuelPrice
        viewModel.emptyTruckWeight = Constants.defaultBaseWeight
        viewModel.nightlyRate = Constants.defaultNightlyRate
        syncFromViewModel()
    }
}

#Preview {
    SettingsView(viewModel: RouteCalculatorViewModel())
}
