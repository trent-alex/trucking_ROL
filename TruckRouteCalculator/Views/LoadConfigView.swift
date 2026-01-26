import SwiftUI

struct LoadConfigView: View {
    @ObservedObject var viewModel: RouteCalculatorViewModel

    private let weightFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

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
                    TextField("Weight", value: $viewModel.emptyTruckWeight, formatter: weightFormatter)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
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
                    TextField("Weight", value: $viewModel.loadWeight, formatter: weightFormatter)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
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
    }
}

#Preview {
    LoadConfigView(viewModel: RouteCalculatorViewModel())
        .padding()
}
