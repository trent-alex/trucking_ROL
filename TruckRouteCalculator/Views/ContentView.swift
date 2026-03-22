import SwiftUI
import SwiftData
import MapKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ScenarioCalculatorViewModel()
    @State private var showingSettings = false
    @State private var showingHistory = false
    @State private var showingOnboarding = !DriverProfile.hasCompletedOnboarding

    var body: some View {
        NavigationView {
            Group {
                if viewModel.showingResults, let scenario = viewModel.currentScenario {
                    ScenarioResultsView(viewModel: viewModel, scenario: scenario)
                } else {
                    ScenarioInputView(viewModel: viewModel)
                }
            }
            .navigationTitle("Load Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.showingResults {
                        Button(action: { viewModel.showingResults = false }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Edit")
                            }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        if !viewModel.scenarios.isEmpty {
                            Button(action: { showingHistory = true }) {
                                Image(systemName: "clock.arrow.circlepath")
                            }
                        }
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gear")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                ScenarioSettingsView(viewModel: viewModel) {
                    // Save current calculation before resetting profile
                    viewModel.saveCurrentScenario()
                    // Reopen profile setup
                    showingOnboarding = true
                }
            }
            .sheet(isPresented: $showingHistory) {
                ScenarioHistoryView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $showingOnboarding) {
                ProfileSetupView(isPresented: $showingOnboarding) { profile in
                    viewModel.driverProfile = profile
                }
            }
        }
    }
}

// MARK: - Settings View

struct ScenarioSettingsView: View {
    @ObservedObject var viewModel: ScenarioCalculatorViewModel
    @Environment(\.dismiss) private var dismiss
    var onResetProfile: (() -> Void)?

    var body: some View {
        NavigationView {
            Form {
                Section("Fuel") {
                    HStack {
                        Text("Fuel Price")
                        Spacer()
                        Text("$")
                        TextField("0.00", value: $viewModel.fuelPrice, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                        Text("/gal")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Overnight") {
                    HStack {
                        Text("Nightly Rate")
                        Spacer()
                        Text("$")
                        TextField("0.00", value: $viewModel.nightlyRate, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                    }
                }

                if let profile = viewModel.driverProfile {
                    Section("Truck Profile") {
                        HStack {
                            Text("Truck")
                            Spacer()
                            Text(profile.truckDisplayName)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Configuration")
                            Spacer()
                            Text(profile.configuration.rawValue)
                                .foregroundColor(.secondary)
                        }

                        if let trailer = profile.trailerType {
                            HStack {
                                Text("Trailer")
                                Spacer()
                                Text(trailer.rawValue)
                                    .foregroundColor(.secondary)
                            }
                        }

                        HStack {
                            Text("Base MPG")
                            Spacer()
                            Text(String(format: "%.1f", profile.baseMPG))
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Empty Weight")
                            Spacer()
                            Text("\(Int(profile.estimatedEmptyWeight).formatted()) lbs")
                                .foregroundColor(.secondary)
                        }

                        Button("Reset Profile") {
                            DriverProfile.resetOnboarding()
                            dismiss()
                            onResetProfile?()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - History View

struct ScenarioHistoryView: View {
    @ObservedObject var viewModel: ScenarioCalculatorViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                if viewModel.scenarios.isEmpty {
                    Text("No saved scenarios")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.scenarios) { scenario in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("$\(String(format: "%.0f", scenario.loadRate)) load")
                                    .fontWeight(.semibold)
                                Text("\(Int(scenario.totalMiles)) miles • \(scenario.segments.count) stops")
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
                            viewModel.scenarios.remove(at: index)
                        }
                    }
                }
            }
            .navigationTitle("Scenarios")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.scenarios.isEmpty {
                        Button("Clear All") {
                            viewModel.clearAllScenarios()
                        }
                        .foregroundColor(.red)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
