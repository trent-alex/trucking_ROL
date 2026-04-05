import SwiftUI

/// ViewModifier that shows PaywallView as a sheet if user is not premium
/// Usage: `.lifetimeGated()`
struct PremiumGate: ViewModifier {
    @Environment(StoreManager.self) private var storeManager
    @State private var showingPaywall = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                if !storeManager.isLifetimeUnlocked {
                    showingPaywall = true
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
    }
}

/// ViewModifier that blocks content entirely until premium is unlocked
/// Shows paywall overlay instead of the content
/// Usage: `.lifetimeRequired()`
struct PremiumRequired: ViewModifier {
    @Environment(StoreManager.self) private var storeManager
    @State private var showingPaywall = false

    func body(content: Content) -> some View {
        Group {
            if storeManager.isLifetimeUnlocked {
                content
            } else {
                // Placeholder with lock icon
                VStack(spacing: 16) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)

                    Text("Pro Feature")
                        .font(.headline)

                    Text("Unlock to access this feature")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button("Unlock Pro") {
                        showingPaywall = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}

/// ViewModifier that shows a lock badge on non-premium content
/// Tapping shows paywall
/// Usage: `.lifetimeBadge()`
struct PremiumBadge: ViewModifier {
    @Environment(StoreManager.self) private var storeManager
    @State private var showingPaywall = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if !storeManager.isLifetimeUnlocked {
                    Button {
                        showingPaywall = true
                    } label: {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.orange)
                            .clipShape(Circle())
                    }
                    .padding(8)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Shows PaywallView as a sheet on appear if user is not premium
    /// Content remains visible behind the sheet
    func lifetimeGated() -> some View {
        modifier(PremiumGate())
    }

    /// Blocks content entirely until premium is unlocked
    /// Shows a placeholder with unlock button instead
    func lifetimeRequired() -> some View {
        modifier(PremiumRequired())
    }

    /// Shows a lock badge overlay on non-premium content
    /// Tapping the badge shows the paywall
    func lifetimeBadge() -> some View {
        modifier(PremiumBadge())
    }
}
