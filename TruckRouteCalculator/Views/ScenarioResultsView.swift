import SwiftUI

struct ScenarioResultsView: View {
    @ObservedObject var viewModel: ScenarioCalculatorViewModel
    let scenario: LoadScenario

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Profitability Summary
                profitabilitySummary

                // State Weight Compliance
                if !viewModel.stateWeightViolations.isEmpty {
                    stateComplianceSection
                }

                // Route Map
                routeMapSection

                // Route Breakdown
                routeBreakdown

                // Cost Summary
                costSummary

                // Action Buttons
                actionButtons
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - State Compliance

    private var stateComplianceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Label("Weight Limit Warnings", systemImage: "scalemass")
                    .font(.headline)
            }

            Text("Your load weight exceeds limits in the following states:")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(viewModel.stateWeightViolations) { violation in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(violation.stateName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Limit: \(Int(violation.weightLimit).formatted()) lbs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let notes = violation.notes {
                            Text(notes)
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(violation.formattedOverage)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        Text("over limit")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            // Show all states in route
            if !scenario.allStatesTraversed.isEmpty {
                Divider()
                HStack {
                    Text("Route passes through:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(scenario.allStatesTraversed.joined(separator: " → "))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Route Map

    private var routeMapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Route Map", systemImage: "map.fill")
                    .font(.headline)
                Spacer()
                Text("\(Int(scenario.totalMiles)) mi")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Check if we have polylines to display
            if scenario.segments.contains(where: { $0.routePolyline != nil }) {
                ScenarioRouteMapView(segments: scenario.segments)
                    .frame(height: 250)
                    .cornerRadius(12)

                // Legend
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 10, height: 10)
                        Text("Loaded")
                            .font(.caption)
                    }
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.gray)
                            .frame(width: 10, height: 10)
                        Text("Deadhead")
                            .font(.caption)
                    }
                    Spacer()
                }
                .foregroundColor(.secondary)

                // Truck routing disclaimer
                HStack {
                    Image(systemName: "info.circle")
                    Text("Route shown for reference. Verify truck-legal routing before departing.")
                        .font(.caption2)
                }
                .foregroundColor(.orange)
                .padding(.top, 4)
            } else {
                // Fallback if no polylines
                Text("Map unavailable")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Profitability Summary

    private var profitabilitySummary: some View {
        VStack(spacing: 12) {
            // Profit/Loss Badge
            HStack {
                Image(systemName: scenario.isProfitable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.title)
                Text(scenario.isProfitable ? "PROFITABLE" : "LOSS")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(scenario.isProfitable ? .green : .red)

            // Profit Amount
            Text(scenario.profit >= 0 ? "+$\(String(format: "%.2f", scenario.profit))" : "-$\(String(format: "%.2f", abs(scenario.profit)))")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(scenario.isProfitable ? .green : .red)

            // Per Mile Stats
            HStack(spacing: 20) {
                VStack {
                    Text("Revenue/Mile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(String(format: "%.2f", scenario.revenuePerMile))")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Divider()
                    .frame(height: 30)

                VStack {
                    Text("Cost/Mile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(String(format: "%.2f", scenario.costPerMile))")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Divider()
                    .frame(height: 30)

                VStack {
                    Text("Profit/Mile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(String(format: "%.2f", scenario.profitPerMile))")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(scenario.profitPerMile >= 0 ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Route Breakdown

    private var routeBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Route Breakdown", systemImage: "map")
                .font(.headline)

            ForEach(scenario.segments) { segment in
                segmentRow(segment)
            }

            // Total
            HStack {
                Text("Total Distance")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(Int(scenario.totalMiles)) miles")
                    .fontWeight(.bold)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private func segmentRow(_ segment: RouteSegment) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: segment.segmentType.icon)
                    .foregroundColor(segment.segmentType.isLoaded ? .blue : .gray)
                Text(segment.segmentType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(segment.distanceMiles)) mi")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                VStack(alignment: .leading) {
                    Text(segment.origin)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Image(systemName: "arrow.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(segment.destination)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(String(format: "%.1f", segment.effectiveMPG)) MPG")
                        .font(.caption)
                    Text("$\(String(format: "%.2f", segment.fuelCost))")
                        .font(.caption)
                        .foregroundColor(.orange)
                    if segment.numberOfNights > 0 {
                        Text("+\(segment.numberOfNights) night\(segment.numberOfNights > 1 ? "s" : "")")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
            }

            if let dropWeight = segment.dropWeight, dropWeight > 0 {
                HStack {
                    Image(systemName: "arrow.down.to.line")
                    Text("Drop \(Int(dropWeight).formatted()) lbs")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            // States traversed
            if !segment.statesTraversed.isEmpty {
                HStack {
                    Image(systemName: "map")
                    Text(segment.statesTraversed.joined(separator: " → "))
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }

    // MARK: - Cost Summary

    private var costSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Cost Summary", systemImage: "dollarsign.circle")
                .font(.headline)

            HStack {
                Text("Load Rate")
                Spacer()
                Text("$\(String(format: "%.2f", scenario.loadRate))")
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }

            Divider()

            HStack {
                Label("Fuel Cost", systemImage: "fuelpump.fill")
                Spacer()
                Text("-$\(String(format: "%.2f", scenario.totalFuelCost))")
                    .foregroundColor(.orange)
            }

            if scenario.totalOvernightCost > 0 {
                HStack {
                    Label("Overnight Stays", systemImage: "bed.double.fill")
                    Spacer()
                    Text("-$\(String(format: "%.2f", scenario.totalOvernightCost))")
                        .foregroundColor(.purple)
                }
            }

            if scenario.totalLumperCharges > 0 {
                HStack {
                    Label("Lumper Charges", systemImage: "person.2.fill")
                    Spacer()
                    Text("-$\(String(format: "%.2f", scenario.totalLumperCharges))")
                        .foregroundColor(.orange)
                }

                // Breakdown if there are multiple lumper charges
                if scenario.pickupLumperCharge > 0 {
                    HStack {
                        Text("  Pickup")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("-$\(String(format: "%.2f", scenario.pickupLumperCharge))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                ForEach(Array(scenario.dropLumperCharges.enumerated()), id: \.offset) { index, charge in
                    if charge > 0 {
                        HStack {
                            Text("  Drop \(index + 1)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("-$\(String(format: "%.2f", charge))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Divider()

            HStack {
                Text("Total Costs")
                    .fontWeight(.semibold)
                Spacer()
                Text("-$\(String(format: "%.2f", scenario.totalCost))")
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }

            HStack {
                Text("Net Profit")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text(scenario.profit >= 0 ? "+$\(String(format: "%.2f", scenario.profit))" : "-$\(String(format: "%.2f", abs(scenario.profit)))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(scenario.isProfitable ? .green : .red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: viewModel.startNewScenario) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Calculate Next Scenario")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            if !viewModel.scenarios.isEmpty {
                NavigationLink(destination: ScenarioComparisonView(viewModel: viewModel)) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                        Text("Compare \(viewModel.scenarios.count + 1) Scenarios")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }

            Button(action: shareScenario) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Quote")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Share

    private func shareScenario() {
        var costs = [
            "• Fuel: $\(String(format: "%.2f", scenario.totalFuelCost))"
        ]
        if scenario.totalOvernightCost > 0 {
            costs.append("• Overnight: $\(String(format: "%.2f", scenario.totalOvernightCost))")
        }
        if scenario.totalLumperCharges > 0 {
            costs.append("• Lumper: $\(String(format: "%.2f", scenario.totalLumperCharges))")
        }
        costs.append("• Total: $\(String(format: "%.2f", scenario.totalCost))")

        let quote = """
        Load Profitability Analysis
        ===========================

        Load Rate: $\(String(format: "%.2f", scenario.loadRate))
        Total Miles: \(Int(scenario.totalMiles))

        Route:
        \(scenario.segments.map { "• \($0.segmentType.rawValue): \($0.origin) → \($0.destination) (\(Int($0.distanceMiles)) mi)" }.joined(separator: "\n"))

        Costs:
        \(costs.joined(separator: "\n"))

        NET PROFIT: \(scenario.profit >= 0 ? "+" : "")$\(String(format: "%.2f", scenario.profit))
        Profit/Mile: $\(String(format: "%.2f", scenario.profitPerMile))

        Generated by ROL - Route Cost Calculator
        """

        let activityVC = UIActivityViewController(
            activityItems: [quote],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Comparison View

struct ScenarioComparisonView: View {
    @ObservedObject var viewModel: ScenarioCalculatorViewModel

    var allScenarios: [LoadScenario] {
        var all = viewModel.scenarios
        if let current = viewModel.currentScenario {
            all.append(current)
        }
        return all.sorted { $0.profitPerMile > $1.profitPerMile }
    }

    var body: some View {
        List {
            ForEach(Array(allScenarios.enumerated()), id: \.element.id) { index, scenario in
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            if index == 0 {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                            }
                            Text("Scenario \(index + 1)")
                                .fontWeight(.semibold)
                        }
                        Text("\(Int(scenario.totalMiles)) miles")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text(scenario.profit >= 0 ? "+$\(String(format: "%.0f", scenario.profit))" : "-$\(String(format: "%.0f", abs(scenario.profit)))")
                            .fontWeight(.bold)
                            .foregroundColor(scenario.isProfitable ? .green : .red)
                        Text("$\(String(format: "%.2f", scenario.profitPerMile))/mi")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    if index < allScenarios.count {
                        viewModel.deleteScenario(allScenarios[index])
                    }
                }
            }
        }
        .navigationTitle("Compare Scenarios")
    }
}

#Preview {
    NavigationView {
        ScenarioResultsView(
            viewModel: ScenarioCalculatorViewModel(),
            scenario: LoadScenario(loadRate: 2500)
        )
    }
}
