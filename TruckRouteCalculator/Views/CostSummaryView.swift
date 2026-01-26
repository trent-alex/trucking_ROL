import SwiftUI

struct CostSummaryView: View {
    @ObservedObject var viewModel: RouteCalculatorViewModel

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("Cost Breakdown")
                    .font(.headline)
                Spacer()
            }

            // Route Summary
            if let route = viewModel.route {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(route.origin)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Image(systemName: "arrow.down")
                            .font(.caption)
                        Text("\(Int(route.distanceMiles)) miles")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    Text("\(route.destination)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }

            // Cost Items
            VStack(spacing: 12) {
                CostItemRow(
                    icon: "fuelpump.fill",
                    iconColor: .orange,
                    title: "Fuel",
                    subtitle: String(format: "%.1f MPG @ $%.2f/gal", viewModel.effectiveMPG, viewModel.fuelPrice),
                    amount: viewModel.costBreakdown.fuelCost
                )

                CostItemRow(
                    icon: "road.lanes",
                    iconColor: .purple,
                    title: "Tolls",
                    subtitle: "Estimated toll costs",
                    amount: viewModel.costBreakdown.tollCost
                )

                // Overnight Stays with stepper
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.indigo)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Overnight Stays")
                            .font(.subheadline)
                        HStack(spacing: 4) {
                            Text("@ $\(Int(viewModel.nightlyRate))/night")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if viewModel.overnightNightsOverride != nil {
                                Button(action: viewModel.resetOvernightToSuggested) {
                                    Text("(Reset)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }

                    Spacer()

                    Stepper(
                        value: Binding(
                            get: { viewModel.actualNights },
                            set: { viewModel.updateOvernightNights($0) }
                        ),
                        in: 0...30
                    ) {
                        Text("\(viewModel.actualNights) nights")
                            .font(.subheadline)
                            .monospacedDigit()
                    }
                    .fixedSize()

                    Text(formatCurrency(viewModel.costBreakdown.overnightCost))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .monospacedDigit()
                        .frame(width: 80, alignment: .trailing)
                }
            }

            Divider()

            // Total
            HStack {
                Text("Total Cost")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Text(formatCurrency(viewModel.costBreakdown.totalCost))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }

            // Cost Per Mile
            HStack {
                Text("Cost Per Mile")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatCurrency(viewModel.costBreakdown.costPerMile) + "/mi")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func formatCurrency(_ value: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

struct CostItemRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let amount: Double

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(currencyFormatter.string(from: NSNumber(value: amount)) ?? "$0.00")
                .font(.subheadline)
                .fontWeight(.medium)
                .monospacedDigit()
        }
    }
}

#Preview {
    let viewModel = RouteCalculatorViewModel()
    viewModel.route = Route(
        origin: "Los Angeles, CA",
        destination: "New York, NY",
        distanceMiles: 2775,
        tollInfo: TollInfo(estimatedCost: 156.50, tollSegments: []),
        statesTraversed: ["CA", "AZ", "NM", "TX", "OK", "AR", "TN", "VA", "PA", "NJ", "NY"]
    )
    viewModel.costBreakdown = CostBreakdown(
        distanceMiles: 2775,
        fuelCost: 1750.25,
        tollCost: 156.50,
        overnightCost: 600,
        numberOfNights: 4
    )

    return CostSummaryView(viewModel: viewModel)
        .padding()
}
