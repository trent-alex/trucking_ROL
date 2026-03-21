import SwiftUI

struct ProfileSetupView: View {
    @Binding var isPresented: Bool
    var onComplete: (DriverProfile) -> Void

    @State private var truckType: TruckType = .sleeperCab
    @State private var truckYear: Int = 2020
    @State private var configuration: TruckConfiguration = .bobtailWithTrailer
    @State private var trailerType: TrailerType = .dryvan

    private let currentYear = Calendar.current.component(.year, from: Date())

    var body: some View {
        NavigationView {
            Form {
                // Welcome Section
                Section {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "truck.box.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

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

                // Truck Info Section
                Section("Your Truck") {
                    Picker("Truck Type", selection: $truckType) {
                        ForEach(TruckType.allCases) { type in
                            VStack(alignment: .leading) {
                                Text(type.rawValue)
                                Text(type.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(type)
                        }
                    }

                    Picker("Model Year", selection: $truckYear) {
                        ForEach((1990...currentYear).reversed(), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
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
                    .foregroundColor(.white)
                    .listRowBackground(Color.blue)
                }
            }
            .navigationTitle("Profile Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func buildProfile() -> DriverProfile {
        DriverProfile(
            truckType: truckType,
            truckYear: truckYear,
            configuration: configuration,
            trailerType: configuration == .bobtailWithTrailer ? trailerType : nil
        )
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
