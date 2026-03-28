import SwiftUI

struct ScenarioResultsView: View {
    @ObservedObject var viewModel: ScenarioCalculatorViewModel
    let scenario: LoadScenario
    @State private var showingCalculationLogic = false
    @State private var isDrivingMode = false

    // Profit margin for conditional formatting
    private var profitMargin: Double {
        guard scenario.loadRate > 0 else { return 0 }
        return (scenario.profit / scenario.loadRate) * 100
    }

    private var drivingModeBackground: Color {
        if profitMargin > 20 {
            return AppTheme.profit
        } else if profitMargin < 5 {
            return AppTheme.loss
        } else {
            return AppTheme.warning
        }
    }

    var body: some View {
        ZStack {
            if isDrivingMode {
                drivingModeView
            } else {
                regularResultsView
            }
        }
        .sheet(isPresented: $showingCalculationLogic) {
            calculationLogicSheet
        }
    }

    // MARK: - Driving Mode View

    private var drivingModeView: some View {
        ZStack {
            // Background based on profit margin
            drivingModeBackground
                .ignoresSafeArea()

            VStack(spacing: 40) {
                // Exit driving mode button
                HStack {
                    Spacer()
                    Button(action: { isDrivingMode = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }

                Spacer()

                // Profit status
                VStack(spacing: 8) {
                    Text(scenario.isProfitable ? "PROFIT" : "LOSS")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))

                    Text(scenario.profit >= 0 ? "+$\(String(format: "%.0f", scenario.profit))" : "-$\(String(format: "%.0f", abs(scenario.profit)))")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(.white)

                    Text("$\(String(format: "%.2f", scenario.profitPerMile))/mile")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                // Fuel cost
                VStack(spacing: 8) {
                    Text("FUEL COST")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    Text("$\(String(format: "%.0f", scenario.totalFuelCost))")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                // Route summary
                VStack(spacing: 4) {
                    Text("\(Int(scenario.totalMiles)) MILES")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    if profitMargin > 20 {
                        Text("EXCELLENT MARGIN (\(String(format: "%.0f", profitMargin))%)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    } else if profitMargin < 5 {
                        Text("LOW MARGIN (\(String(format: "%.0f", profitMargin))%)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Text("MARGIN: \(String(format: "%.0f", profitMargin))%")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Regular Results View

    private var regularResultsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Driving Mode Toggle
                drivingModeToggle

                // Legal Alert Banner (persistent at top for violations)
                if !viewModel.stateWeightViolations.isEmpty {
                    legalAlertBanner
                }

                // Profitability Summary
                profitabilitySummary

                // Confidence Intervals
                confidenceIntervalsSection

                // Route Map
                routeMapSection

                // Route Breakdown
                routeBreakdown

                // Cost Summary with Verified Badges
                costSummaryWithVerification

                // Action Buttons
                actionButtons
            }
            .padding()
        }
        .background(AppTheme.backgroundPrimary)
    }

    // MARK: - Driving Mode Toggle

    private var drivingModeToggle: some View {
        Button(action: { isDrivingMode = true }) {
            HStack {
                Image(systemName: "car.fill")
                Text("Driving Mode")
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "arrow.up.right.circle.fill")
            }
            .padding()
            .background(AppTheme.darkCard)
            .foregroundColor(AppTheme.textOnDark)
            .cornerRadius(12)
        }
    }

    // MARK: - Legal Alert Banner (Persistent)

    private var legalAlertBanner: some View {
        let violationCount = viewModel.stateWeightViolations.count
        let stateText = violationCount == 1 ? "state" : "states"

        return VStack(spacing: 8) {
            legalAlertHeader(violationCount: violationCount, stateText: stateText)
            legalAlertStatesList
            legalAlertFooter
        }
        .padding()
        .background(Color.red)
        .cornerRadius(16)
    }

    private func legalAlertHeader(violationCount: Int, stateText: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.octagon.fill")
                .font(.title2)
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("LEGAL ALERT")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("Weight exceeds limits in \(violationCount) \(stateText)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            Spacer()
        }
    }

    private var legalAlertStatesList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.stateWeightViolations) { violation in
                    violationBadge(violation)
                }
            }
        }
    }

    private func violationBadge(_ violation: StateWeightViolation) -> some View {
        HStack(spacing: 4) {
            Text(violation.stateCode)
                .fontWeight(.bold)
            Text("+\(Int(violation.overageAmount).formatted()) lbs")
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.2))
        .cornerRadius(8)
        .foregroundColor(.white)
    }

    private var legalAlertFooter: some View {
        Text("Verify permits or reduce load weight before proceeding")
            .font(.caption)
            .foregroundColor(.white.opacity(0.8))
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
        VStack(spacing: 16) {
            // Profit/Loss Badge
            HStack(spacing: 8) {
                Image(systemName: scenario.isProfitable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.title2)
                Text(scenario.isProfitable ? "PROFITABLE" : "LOSS")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .foregroundColor(scenario.isProfitable ? AppTheme.textOnAccent : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(scenario.isProfitable ? AppTheme.accent : AppTheme.loss)
            .cornerRadius(20)

            // Profit Amount
            Text(scenario.profit >= 0 ? "+$\(String(format: "%.2f", scenario.profit))" : "-$\(String(format: "%.2f", abs(scenario.profit)))")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(scenario.isProfitable ? AppTheme.profit : AppTheme.loss)

            // Per Mile Stats
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("Revenue/Mile")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text("$\(String(format: "%.2f", scenario.revenuePerMile))")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textPrimary)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(AppTheme.divider)
                    .frame(width: 1, height: 40)

                VStack(spacing: 4) {
                    Text("Cost/Mile")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text("$\(String(format: "%.2f", scenario.costPerMile))")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textPrimary)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(AppTheme.divider)
                    .frame(width: 1, height: 40)

                VStack(spacing: 4) {
                    Text("Profit/Mile")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text("$\(String(format: "%.2f", scenario.profitPerMile))")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(scenario.profitPerMile >= 0 ? AppTheme.profit : AppTheme.loss)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(AppTheme.backgroundCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
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

    // MARK: - Cost Summary with Verification

    private var costSummaryWithVerification: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Cost Summary", systemImage: "dollarsign.circle")
                    .font(.headline)
                Spacer()
                Button(action: { showingCalculationLogic = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                        Text("View Logic")
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                }
            }

            HStack {
                Text("Load Rate")
                Spacer()
                Text("$\(String(format: "%.2f", scenario.loadRate))")
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }

            Divider()

            // Fuel Cost with Verification Badge
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    HStack(spacing: 6) {
                        Label("Fuel Cost", systemImage: "fuelpump.fill")
                        // Verified badge
                        if viewModel.fuelPriceIsVerified {
                            HStack(spacing: 2) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption2)
                                Text("Verified")
                                    .font(.caption2)
                            }
                            .foregroundColor(AppTheme.profit)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.profit.opacity(0.15))
                            .cornerRadius(4)
                        }
                    }
                    Spacer()
                    Text("-$\(String(format: "%.2f", scenario.totalFuelCost))")
                        .foregroundColor(.orange)
                }

                // EIA source caption
                Text(viewModel.fuelPriceSourceText)
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
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

    // MARK: - Confidence Intervals

    private var confidenceIntervalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(AppTheme.textOnDark)
                    .padding(6)
                    .background(AppTheme.darkCard)
                    .cornerRadius(6)
                Text("Certainty Range")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text("±5% fuel")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            HStack(spacing: 12) {
                // Worst Case
                let worstCase = viewModel.worstCaseProfit(for: scenario)
                VStack(spacing: 4) {
                    Text("Worst Case")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text(worstCase >= 0 ? "+$\(String(format: "%.0f", worstCase))" : "-$\(String(format: "%.0f", abs(worstCase)))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(worstCase >= 0 ? AppTheme.profit : AppTheme.loss)
                    Text("If fuel +5%")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.backgroundSecondary)
                .cornerRadius(12)

                // Likely Case (current)
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Text("Likely Case")
                            .font(.caption)
                        Image(systemName: "star.fill")
                            .font(.caption2)
                    }
                    .foregroundColor(AppTheme.textSecondary)
                    Text(scenario.profit >= 0 ? "+$\(String(format: "%.0f", scenario.profit))" : "-$\(String(format: "%.0f", abs(scenario.profit)))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(scenario.isProfitable ? AppTheme.profit : AppTheme.loss)
                    Text("Current price")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(scenario.isProfitable ? AppTheme.profit.opacity(0.1) : AppTheme.loss.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(scenario.isProfitable ? AppTheme.profit : AppTheme.loss, lineWidth: 2)
                )

                // Best Case
                let bestCase = viewModel.bestCaseProfit(for: scenario)
                VStack(spacing: 4) {
                    Text("Best Case")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text(bestCase >= 0 ? "+$\(String(format: "%.0f", bestCase))" : "-$\(String(format: "%.0f", abs(bestCase)))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(bestCase >= 0 ? AppTheme.profit : AppTheme.loss)
                    Text("If fuel -5%")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.backgroundSecondary)
                .cornerRadius(12)
            }

            // Confidence note
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                Text("All scenarios remain \(viewModel.worstCaseProfit(for: scenario) >= 0 ? "profitable" : "unprofitable") across this range")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding()
        .background(AppTheme.backgroundCard)
        .cornerRadius(16)
    }

    // MARK: - Calculation Logic Sheet

    private var calculationLogicSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    let explanation = viewModel.getCalculationExplanation()

                    // MPG Calculation
                    calculationSection(
                        title: "Fuel Efficiency (MPG)",
                        icon: "gauge.with.needle.fill",
                        formula: explanation.mpgFormula
                    )

                    // Fuel Cost
                    calculationSection(
                        title: "Fuel Cost",
                        icon: "fuelpump.fill",
                        formula: explanation.fuelCostFormula
                    )

                    // Overnight Stays
                    calculationSection(
                        title: "Overnight Stays",
                        icon: "bed.double.fill",
                        formula: explanation.overnightFormula
                    )

                    // Profit Calculation
                    calculationSection(
                        title: "Profit Calculation",
                        icon: "chart.line.uptrend.xyaxis",
                        formula: explanation.profitFormula
                    )

                    // Data Sources
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Data Sources", systemImage: "server.rack")
                            .font(.headline)

                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(AppTheme.profit)
                            Text("Fuel prices from U.S. Energy Information Administration (EIA)")
                                .font(.caption)
                        }

                        HStack {
                            Image(systemName: "map.fill")
                                .foregroundColor(.blue)
                            Text("Routes calculated via Apple MapKit")
                                .font(.caption)
                        }

                        HStack {
                            Image(systemName: "scalemass.fill")
                                .foregroundColor(.orange)
                            Text("Weight limits from FHWA state data")
                                .font(.caption)
                        }
                    }
                    .padding()
                    .background(AppTheme.backgroundSecondary)
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Calculation Logic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showingCalculationLogic = false }
                }
            }
        }
    }

    private func calculationSection(title: String, icon: String, formula: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            Text(formula)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(AppTheme.textSecondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.darkCard.opacity(0.05))
                .cornerRadius(8)
        }
    }

    // MARK: - Action Buttons

    // Profitability level for button styling
    private var profitabilityLevel: ProfitabilityLevel {
        let worstCase = viewModel.worstCaseProfit(for: scenario)
        if scenario.profit < 0 {
            return .negative
        } else if worstCase < 0 {
            return .risky  // Positive but could go negative
        } else {
            return .solid  // Positive even in worst case
        }
    }

    private enum ProfitabilityLevel {
        case negative, risky, solid

        var buttonColor: Color {
            switch self {
            case .negative: return AppTheme.loss
            case .risky: return AppTheme.warning
            case .solid: return AppTheme.profit
            }
        }

        var buttonIcon: String {
            switch self {
            case .negative: return "exclamationmark.triangle.fill"
            case .risky: return "questionmark.circle.fill"
            case .solid: return "bookmark.fill"
            }
        }

        var buttonText: String {
            switch self {
            case .negative: return "Save Loss to Log"
            case .risky: return "Save (Risky) to Log"
            case .solid: return "Save to Log"
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Edit Route Button - return to input
            Button(action: { viewModel.showingResults = false }) {
                HStack {
                    Image(systemName: "pencil.circle.fill")
                    Text("Edit Route Details")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.backgroundSecondary)
                .foregroundColor(AppTheme.textPrimary)
                .fontWeight(.medium)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
            }

            // Save to Log Button - color based on profitability
            if !viewModel.isCurrentScenarioSaved {
                Button(action: viewModel.saveCurrentScenario) {
                    HStack {
                        Image(systemName: profitabilityLevel.buttonIcon)
                        Text(profitabilityLevel.buttonText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(profitabilityLevel.buttonColor)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .cornerRadius(12)
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(profitabilityLevel.buttonColor)
                    Text("Saved to Log")
                        .foregroundColor(profitabilityLevel.buttonColor)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(profitabilityLevel.buttonColor.opacity(0.15))
                .cornerRadius(12)
            }

            Button(action: viewModel.startNewScenario) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Calculate Next Load")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.accent)
                .foregroundColor(AppTheme.textOnAccent)
                .fontWeight(.semibold)
                .cornerRadius(12)
            }

            if viewModel.scenarios.count > 0 {
                NavigationLink(destination: ScenarioComparisonView(viewModel: viewModel)) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                        Text("Compare \(viewModel.scenarios.count) Saved Load\(viewModel.scenarios.count == 1 ? "" : "s")")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.darkCard)
                    .foregroundColor(AppTheme.textOnDark)
                    .fontWeight(.semibold)
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
                .background(AppTheme.backgroundSecondary)
                .foregroundColor(AppTheme.textPrimary)
                .fontWeight(.medium)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
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
