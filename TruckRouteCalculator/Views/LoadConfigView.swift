import SwiftUI

struct LoadConfigView: View {
    @ObservedObject var viewModel: RouteCalculatorViewModel

    @State private var emptyWeightText: String = ""
    @State private var loadWeightText: String = ""

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "truck.box.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Load Configuration")
                    .font(.headline)
                Spacer()
            }

            // Empty Truck Weight
            VStack(alignment: .leading, spacing: 8) {
                Text("Empty Truck Weight")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    TextField("Weight", text: $emptyWeightText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
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

            // Load Weight
            VStack(alignment: .leading, spacing: 8) {
                Text("Load Weight")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    TextField("Weight", text: $loadWeightText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .onSubmit { commitLoadWeight() }
                        .onChange(of: loadWeightText) {
                            if let val = Double(loadWeightText) {
                                viewModel.loadWeight = val
                            }
                        }
                    Text("lbs")
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Total Weight & Efficiency
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Weight")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(viewModel.totalWeight).formatted()) lbs")
                        .font(.headline)
                        .foregroundColor(viewModel.totalWeight > Constants.maxLegalWeight ? .red : .primary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Est. MPG")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", viewModel.effectiveMPG))
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }

            // Weight Warning
            if viewModel.totalWeight > Constants.maxLegalWeight {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Exceeds federal weight limit of 80,000 lbs")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onAppear {
            emptyWeightText = formatWeight(viewModel.emptyTruckWeight)
            loadWeightText = formatWeight(viewModel.loadWeight)
        }
    }

    private func commitEmptyWeight() {
        if let val = Double(emptyWeightText) {
            viewModel.emptyTruckWeight = val
        }
        emptyWeightText = formatWeight(viewModel.emptyTruckWeight)
    }

    private func commitLoadWeight() {
        if let val = Double(loadWeightText) {
            viewModel.loadWeight = val
        }
        loadWeightText = formatWeight(viewModel.loadWeight)
    }

    private func formatWeight(_ value: Double) -> String {
        "\(Int(value))"
    }
}

#Preview {
    LoadConfigView(viewModel: RouteCalculatorViewModel())
        .padding()
}
