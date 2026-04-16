import SwiftUI
import StoreKit

/// Paywall view for lifetime purchase
struct PaywallView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.dismiss) private var dismiss

    @State private var showSuccessState = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Features list
                        featuresSection

                        // Product cards
                        if storeManager.isLoading {
                            loadingView
                        } else if showSuccessState || storeManager.isLifetimeUnlocked {
                            successView
                        } else {
                            productSection
                        }

                        // Error message
                        if let error = storeManager.errorMessage {
                            errorView(error)
                        }

                        // Restore purchases
                        restoreButton

                        // Legal text
                        legalText
                    }
                    .padding()
                }
            }
            .navigationTitle("Unlock Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onChange(of: storeManager.isLifetimeUnlocked) { _, unlocked in
                if unlocked {
                    showSuccessState = true
                    // Auto-dismiss after success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("ROL Pro")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Unlock all features with a one-time purchase")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FeatureRow(icon: "map.fill", title: "Unlimited Route Calculations")
            FeatureRow(icon: "fuelpump.fill", title: "Real-Time Fuel Prices")
            FeatureRow(icon: "dollarsign.circle.fill", title: "Detailed Cost Breakdowns")
            FeatureRow(icon: "clock.arrow.circlepath", title: "Load History & Analytics")
            FeatureRow(icon: "icloud.fill", title: "Sync Across Devices")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Product Section

    private var productSection: some View {
        VStack(spacing: 16) {
            if let lifetime = storeManager.lifetimeProduct {
                ProductCard(
                    product: lifetime,
                    badge: "LIFETIME",
                    badgeColor: .blue,
                    onPurchase: {
                        Task {
                            await storeManager.purchase(lifetime)
                        }
                    },
                    isLoading: storeManager.purchaseInProgress
                )
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading products...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(40)
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Pro Unlocked!")
                .font(.title2)
                .fontWeight(.bold)

            Text("Enjoy all premium features")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(40)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Restore Button

    private var restoreButton: some View {
        Button {
            Task {
                await storeManager.syncWithAppStore()
            }
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .disabled(storeManager.isLoading)
    }

    // MARK: - Legal Text

    private var legalText: some View {
        Text("Payment will be charged to your Apple ID account at confirmation of purchase. This is a one-time purchase that unlocks premium features permanently.")
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)

            Text(title)
                .font(.subheadline)

            Spacer()

            Image(systemName: "checkmark")
                .font(.caption)
                .foregroundColor(.green)
        }
    }
}

// MARK: - Product Card

private struct ProductCard: View {
    let product: Product
    let badge: String
    let badgeColor: Color
    let onPurchase: () -> Void
    let isLoading: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Badge
            Text(badge)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(badgeColor)
                .cornerRadius(12)

            // Price
            Text(product.displayPrice)
                .font(.system(size: 36, weight: .bold))

            // Description
            Text(product.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Purchase button
            Button {
                onPurchase()
            } label: {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Purchase")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(badgeColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isLoading)
        }
        .padding(24)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(badgeColor.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
        .environment(StoreManager())
}
