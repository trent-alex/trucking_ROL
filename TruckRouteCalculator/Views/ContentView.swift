import SwiftUI
import SwiftData
import MapKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ScenarioCalculatorViewModel()
    @State private var showingSettings = false
    @State private var showingHistory = false
    @State private var showingOnboarding = !DriverProfile.hasCompletedOnboarding

    private var saveConfirmationBanner: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white)
            Text("Saved to Load Log")
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppTheme.profit)
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
        .padding(.top, 8)
    }

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
                NavigationView {
                    SavedLoadsView(viewModel: viewModel)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Done") {
                                    showingHistory = false
                                }
                            }
                        }
                }
            }
            .overlay(alignment: .top) {
                if viewModel.showSaveConfirmation {
                    saveConfirmationBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3), value: viewModel.showSaveConfirmation)
            .fullScreenCover(isPresented: $showingOnboarding) {
                ProfileSetupView(isPresented: $showingOnboarding) { profile in
                    viewModel.driverProfile = profile
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Settings View

struct ScenarioSettingsView: View {
    @ObservedObject var viewModel: ScenarioCalculatorViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var onResetProfile: (() -> Void)?

    // Editable profile settings
    @State private var editedConfiguration: TruckConfiguration = .bobtailWithTrailer
    @State private var editedTrailerType: TrailerType = .dryvan
    @State private var editedMPG: Double = 7.0
    @State private var useCustomMPG: Bool = false
    @State private var hasChanges: Bool = false

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
                        TextField("150", value: $viewModel.nightlyRate, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                    }
                    Text("Default: $150/night. Saved automatically.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Lumper Charges") {
                    HStack {
                        Text("Default Lumper")
                        Spacer()
                        Text("$")
                        TextField("0", value: $viewModel.defaultLumperCharge, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                    }
                    Text("Pre-fills lumper fields. Updates with last used value.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let profile = viewModel.driverProfile {
                    Section("Truck Profile") {
                        HStack {
                            Text("Truck")
                            Spacer()
                            Text(profile.truckDisplayName)
                                .foregroundColor(.secondary)
                        }

                        // Editable Configuration
                        Picker("Configuration", selection: $editedConfiguration) {
                            ForEach(TruckConfiguration.allCases) { config in
                                Text(config.rawValue).tag(config)
                            }
                        }
                        .onChange(of: editedConfiguration) { _, _ in
                            hasChanges = true
                        }

                        // Editable Trailer Type (only if bobtail + trailer)
                        if editedConfiguration == .bobtailWithTrailer {
                            Picker("Trailer Type", selection: $editedTrailerType) {
                                ForEach(TrailerType.allCases) { type in
                                    HStack {
                                        Image(systemName: type.icon)
                                        Text(type.rawValue)
                                    }
                                    .tag(type)
                                }
                            }
                            .onChange(of: editedTrailerType) { _, _ in
                                hasChanges = true
                            }
                        }

                        // MPG Setting
                        Toggle("Custom MPG", isOn: $useCustomMPG)
                            .onChange(of: useCustomMPG) { _, _ in
                                hasChanges = true
                            }

                        if useCustomMPG {
                            HStack {
                                Text("Base MPG")
                                Spacer()
                                TextField("7.0", value: $editedMPG, format: .number)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 60)
                                    .multilineTextAlignment(.trailing)
                                    .onChange(of: editedMPG) { _, _ in
                                        hasChanges = true
                                    }
                            }
                            Text("Override calculated MPG with your own value")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            HStack {
                                Text("Base MPG")
                                Spacer()
                                Text(String(format: "%.1f", calculatedMPG(profile: profile)))
                                    .foregroundColor(hasChanges ? .blue : .secondary)
                            }
                            Text("Auto-calculated based on truck and trailer type")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Empty Weight")
                            Spacer()
                            Text("\(Int(calculatedWeight(profile: profile)).formatted()) lbs")
                                .foregroundColor(hasChanges ? .blue : .secondary)
                        }

                        // Apply Changes Button
                        if hasChanges {
                            Button(action: applyChanges) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Apply Changes")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .foregroundColor(.white)
                            .listRowBackground(Color.blue)
                        }

                        // Reset Profile
                        Button("Reset Profile") {
                            DriverProfile.resetOnboarding()
                            dismiss()
                            onResetProfile?()
                        }
                        .foregroundColor(.red)
                    }

                    // Recalculate Section
                    if hasChanges && viewModel.currentScenario != nil {
                        Section {
                            Text("Changes will affect the current route calculation. Tap 'Apply Changes' to update.")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
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
            .onAppear {
                // Initialize with current profile values
                if let profile = viewModel.driverProfile {
                    editedConfiguration = profile.configuration
                    editedTrailerType = profile.trailerType ?? .dryvan
                    useCustomMPG = profile.useCustomMPG
                    editedMPG = profile.customMPGValue ?? profile.baseMPG
                }
            }
            .adaptiveFormLayout()
        }
        .navigationViewStyle(.stack)
    }

    // Calculate MPG based on edited values
    private func calculatedMPG(profile: DriverProfile) -> Double {
        let truckBaseMPG: Double
        if profile.useCustomTruck, let custom = profile.customTruck {
            truckBaseMPG = custom.baseMPG
        } else if let specId = profile.selectedTruckSpecId, let spec = TruckDatabase.spec(id: specId) {
            truckBaseMPG = spec.baseMPG
        } else {
            truckBaseMPG = 7.0
        }

        if editedConfiguration == .bobtailOnly {
            return truckBaseMPG + 2.0
        }

        switch editedTrailerType {
        case .dryvan: return truckBaseMPG
        case .reefer: return truckBaseMPG - 1.0
        case .flatbed: return truckBaseMPG + 0.4
        case .tanker: return truckBaseMPG + 0.2
        }
    }

    // Calculate weight based on edited values
    private func calculatedWeight(profile: DriverProfile) -> Double {
        let truckWeight: Double
        if profile.useCustomTruck, let custom = profile.customTruck {
            truckWeight = custom.emptyWeight
        } else if let specId = profile.selectedTruckSpecId, let spec = TruckDatabase.spec(id: specId) {
            truckWeight = spec.emptyWeight
        } else {
            switch profile.truckType {
            case .dayCab: truckWeight = 16000
            case .sleeperCab: truckWeight = 20000
            case .caboover: truckWeight = 15000
            }
        }

        guard editedConfiguration == .bobtailWithTrailer else {
            return truckWeight
        }

        let trailerWeight: Double
        switch editedTrailerType {
        case .dryvan: trailerWeight = 14000
        case .reefer: trailerWeight = 16000
        case .flatbed: trailerWeight = 12000
        case .tanker: trailerWeight = 15000
        }

        return truckWeight + trailerWeight
    }

    // Apply changes to profile and recalculate
    private func applyChanges() {
        guard var profile = viewModel.driverProfile else { return }

        // Update profile with new values
        profile.configuration = editedConfiguration
        profile.trailerType = editedConfiguration == .bobtailWithTrailer ? editedTrailerType : nil

        // Update custom MPG settings
        profile.useCustomMPG = useCustomMPG
        profile.customMPGValue = useCustomMPG ? editedMPG : nil

        // Save updated profile
        profile.save()
        viewModel.driverProfile = profile

        // Recalculate current scenario if exists
        if viewModel.currentScenario != nil {
            Task {
                await viewModel.calculateScenario()
            }
        }

        hasChanges = false

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Dismiss settings and go back to calculator
        dismiss()
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
