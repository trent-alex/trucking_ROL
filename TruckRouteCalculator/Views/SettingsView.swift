import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: RouteCalculatorViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                // Fuel Settings
                Section(header: Text("Fuel Settings")) {
                    HStack {
                        Text("Base MPG")
                        Spacer()
                        TextField("MPG", value: $viewModel.baseMPG, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }

                    HStack {
                        Text("Fuel Price")
                        Spacer()
                        Text("$")
                        TextField("Price", value: $viewModel.fuelPrice, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("/gal")
                            .foregroundColor(.secondary)
                    }
                }

                // Truck Settings
                Section(header: Text("Truck Settings")) {
                    HStack {
                        Text("Empty Weight")
                        Spacer()
                        TextField("Weight", value: $viewModel.emptyTruckWeight, format: .number.precision(.fractionLength(0)))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
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
                        TextField("Rate", value: $viewModel.nightlyRate, format: .number.precision(.fractionLength(0)))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
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
                        dismiss()
                    }
                }
            }
        }
    }

    private func resetToDefaults() {
        viewModel.baseMPG = Constants.defaultBaseMPG
        viewModel.fuelPrice = Constants.defaultFuelPrice
        viewModel.emptyTruckWeight = Constants.defaultBaseWeight
        viewModel.nightlyRate = Constants.defaultNightlyRate
    }
}

#Preview {
    SettingsView(viewModel: RouteCalculatorViewModel())
}
