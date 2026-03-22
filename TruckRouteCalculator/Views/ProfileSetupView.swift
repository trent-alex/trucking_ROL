import SwiftUI

struct ProfileSetupView: View {
    @Binding var isPresented: Bool
    var onComplete: (DriverProfile) -> Void

    // Selection mode
    @State private var useCustomTruck = false

    // Predefined truck selection
    @State private var selectedMake: TruckMake = .freightliner
    @State private var selectedSpec: TruckSpec?
    @State private var truckYear: Int = 2020

    // Custom truck entry
    @State private var customMakeName: String = ""
    @State private var customModelName: String = ""
    @State private var customType: TruckType = .sleeperCab
    @State private var customBaseMPG: Double = 7.0
    @State private var customEmptyWeight: Double = 20000

    // Configuration
    @State private var configuration: TruckConfiguration = .bobtailWithTrailer
    @State private var trailerType: TrailerType = .dryvan

    private let currentYear = Calendar.current.component(.year, from: Date())

    var availableModels: [TruckSpec] {
        TruckDatabase.models(for: selectedMake, year: truckYear)
    }

    var body: some View {
        NavigationView {
            Form {
                // Welcome Section
                Section {
                    VStack(alignment: .center, spacing: 12) {
                        Image("ProfileIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        Text("Welcome to ROL")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Set up your truck profile for accurate cost calculations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }

                // Truck Selection Mode
                Section {
                    Picker("Truck Source", selection: $useCustomTruck) {
                        Text("Select from List").tag(false)
                        Text("Enter Custom").tag(true)
                    }
                    .pickerStyle(.segmented)
                }

                if useCustomTruck {
                    customTruckSection
                } else {
                    predefinedTruckSection
                }

                // Configuration Section
                Section("Configuration") {
                    Picker("Setup", selection: $configuration) {
                        ForEach(TruckConfiguration.allCases) { config in
                            Text(config.rawValue).tag(config)
                        }
                    }
                    .pickerStyle(.segmented)

                    if configuration == .bobtailWithTrailer {
                        Picker("Trailer Type", selection: $trailerType) {
                            ForEach(TrailerType.allCases) { type in
                                Label {
                                    VStack(alignment: .leading) {
                                        Text(type.rawValue)
                                        Text(type.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: type.icon)
                                }
                                .tag(type)
                            }
                        }
                    }
                }

                // Preview Section
                Section("Your Settings") {
                    let profile = buildProfile()

                    HStack {
                        Text("Truck")
                        Spacer()
                        Text(profile.truckDisplayName)
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Base MPG")
                        Spacer()
                        Text(String(format: "%.1f", profile.baseMPG))
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Empty Weight")
                        Spacer()
                        Text("\(Int(profile.estimatedEmptyWeight).formatted()) lbs")
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                }

                // Continue Button
                Section {
                    Button(action: completeSetup) {
                        HStack {
                            Spacer()
                            Text("Get Started")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right.circle.fill")
                            Spacer()
                        }
                    }
                    .disabled(!isValidInput)
                    .foregroundColor(.white)
                    .listRowBackground(isValidInput ? Color.blue : Color.gray)
                }
            }
            .navigationTitle("Profile Setup")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Select first available spec
                if let firstSpec = availableModels.first {
                    selectedSpec = firstSpec
                }
            }
            .onChange(of: selectedMake) { _, _ in
                // Reset selection when make changes
                selectedSpec = availableModels.first
            }
            .onChange(of: truckYear) { _, _ in
                // Reset selection when year changes
                if let current = selectedSpec, !current.isValidForYear(truckYear) {
                    selectedSpec = availableModels.first
                }
            }
        }
    }

    // MARK: - Predefined Truck Section

    private var predefinedTruckSection: some View {
        Section("Your Truck") {
            Picker("Model Year", selection: $truckYear) {
                ForEach((1990...currentYear).reversed(), id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }

            Picker("Make", selection: $selectedMake) {
                ForEach(TruckMake.allCases.filter { $0 != .custom }) { make in
                    Text(make.rawValue).tag(make)
                }
            }

            if !availableModels.isEmpty {
                Picker("Model", selection: $selectedSpec) {
                    ForEach(availableModels) { spec in
                        VStack(alignment: .leading) {
                            Text(spec.model)
                            Text("\(spec.yearRange) • \(String(format: "%.1f", spec.baseMPG)) MPG")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .tag(spec as TruckSpec?)
                    }
                }
            } else {
                Text("No models available for \(truckYear)")
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Custom Truck Section

    private var customTruckSection: some View {
        Section("Your Truck (Custom)") {
            TextField("Make (e.g., Freightliner)", text: $customMakeName)
                .autocorrectionDisabled()

            TextField("Model (e.g., Cascadia)", text: $customModelName)
                .autocorrectionDisabled()

            Picker("Model Year", selection: $truckYear) {
                ForEach((1990...currentYear).reversed(), id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }

            Picker("Truck Type", selection: $customType) {
                ForEach(TruckType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }

            HStack {
                Text("Base MPG")
                Spacer()
                TextField("MPG", value: $customBaseMPG, format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                    .multilineTextAlignment(.trailing)
            }

            HStack {
                Text("Empty Weight (lbs)")
                Spacer()
                TextField("Weight", value: $customEmptyWeight, format: .number)
                    .keyboardType(.numberPad)
                    .frame(width: 80)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    // MARK: - Validation

    private var isValidInput: Bool {
        if useCustomTruck {
            return !customMakeName.isEmpty && !customModelName.isEmpty && customBaseMPG > 0 && customEmptyWeight > 0
        } else {
            return selectedSpec != nil
        }
    }

    // MARK: - Build Profile

    private func buildProfile() -> DriverProfile {
        if useCustomTruck {
            let custom = CustomTruck(
                makeName: customMakeName.isEmpty ? "Custom" : customMakeName,
                modelName: customModelName.isEmpty ? "Truck" : customModelName,
                type: customType,
                baseMPG: customBaseMPG,
                emptyWeight: customEmptyWeight
            )
            return DriverProfile.fromCustom(
                custom,
                year: truckYear,
                configuration: configuration,
                trailerType: configuration == .bobtailWithTrailer ? trailerType : nil
            )
        } else if let spec = selectedSpec {
            return DriverProfile.fromSpec(
                spec,
                year: truckYear,
                configuration: configuration,
                trailerType: configuration == .bobtailWithTrailer ? trailerType : nil
            )
        } else {
            return DriverProfile.default
        }
    }

    private func completeSetup() {
        let profile = buildProfile()
        profile.save()
        onComplete(profile)
        isPresented = false
    }
}

#Preview {
    ProfileSetupView(isPresented: .constant(true)) { profile in
        print("Profile saved: \(profile)")
    }
}
