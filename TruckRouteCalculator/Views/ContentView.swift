import SwiftUI
import SwiftData
import MapKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = RouteCalculatorViewModel()
    @State private var showingSettings = false
    @State private var showingHistory = false

    var body: some View {
        NavigationView {
            Group {
                if viewModel.showingResults,
                   let route = viewModel.route,
                   let polyline = route.routePolyline,
                   let originCoord = route.originCoordinate,
                   let destCoord = route.destinationCoordinate {
                    mapResultsView(polyline: polyline, originCoord: originCoord, destCoord: destCoord)
                } else {
                    inputFormView
                }
            }
            .navigationTitle("Route Cost Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.showingResults {
                        Button(action: viewModel.reset) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("New Route")
                            }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        if !viewModel.showingResults {
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
                SettingsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingHistory) {
                RouteHistoryView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Input Form

    private var inputFormView: some View {
        ScrollView {
            VStack(spacing: 20) {
                RouteInputView(viewModel: viewModel)
                LoadConfigView(viewModel: viewModel)

                // Calculate Button
                Button(action: viewModel.calculateRoute) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "dollarsign.arrow.circlepath")
                        }
                        Text(viewModel.isLoading ? "Calculating..." : "Calculate Route Cost")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canCalculate ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.canCalculate || viewModel.isLoading)

                // Error Message
                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Map Results

    private func mapResultsView(polyline: MKPolyline, originCoord: CLLocationCoordinate2D, destCoord: CLLocationCoordinate2D) -> some View {
        ZStack(alignment: .bottom) {
            RouteMapView(
                polyline: polyline,
                originCoordinate: originCoord,
                destinationCoordinate: destCoord
            )
            .edgesIgnoringSafeArea(.bottom)

            // Bottom cost pane
            bottomCostPane
        }
    }

    private var bottomCostPane: some View {
        VStack(spacing: 12) {
            // Drag indicator
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            ScrollView {
                VStack(spacing: 16) {
                    CostSummaryView(viewModel: viewModel)

                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(action: shareQuote) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                        }

                        Button(action: { viewModel.saveCurrentRoute(context: modelContext) }) {
                            HStack {
                                Image(systemName: viewModel.routeSaved ? "checkmark" : "square.and.arrow.down")
                                Text(viewModel.routeSaved ? "Saved" : "Save")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.routeSaved ? Color.green.opacity(0.15) : Color(.secondarySystemBackground))
                            .foregroundColor(viewModel.routeSaved ? .green : .primary)
                            .cornerRadius(10)
                        }
                        .disabled(viewModel.routeSaved)

                        Button(action: viewModel.reset) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("New Route")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .frame(maxHeight: 440)
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 10, y: -5)
        )
    }

    // MARK: - Share

    private func shareQuote() {
        guard let route = viewModel.route else { return }

        let breakdown = viewModel.costBreakdown
        let quote = """
        Truck Route Cost Quote
        ----------------------
        From: \(route.origin)
        To: \(route.destination)
        Distance: \(Int(route.distanceMiles)) miles

        Cost Breakdown:
        - Fuel: $\(String(format: "%.2f", breakdown.fuelCost))
        - Overnight (\(breakdown.numberOfNights) nights): $\(String(format: "%.2f", breakdown.overnightCost))

        TOTAL: $\(String(format: "%.2f", breakdown.totalCost))
        Cost per mile: $\(String(format: "%.2f", breakdown.costPerMile))

        Generated by Truck Route Calculator
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

#Preview {
    ContentView()
}
