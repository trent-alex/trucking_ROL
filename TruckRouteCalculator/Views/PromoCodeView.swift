import SwiftUI

/// Promo code entry view for influencer and founder codes
struct PromoCodeView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.dismiss) private var dismiss

    @Binding var showFounderProduct: Bool
    var onInfluencerUnlock: () -> Void

    @State private var code = ""
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var successMessage = ""

    @FocusState private var isCodeFieldFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "ticket.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.top, 40)

                // Title
                VStack(spacing: 8) {
                    Text("Enter Your Code")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Redeem your influencer or founder code")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Code input
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Enter code", text: $code)
                        .textFieldStyle(.plain)
                        .font(.system(.title3, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .focused($isCodeFieldFocused)
                        .onChange(of: code) { _, _ in
                            // Clear error when user types
                            errorMessage = nil
                        }

                    // Error message
                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal)
                .animation(.easeInOut(duration: 0.2), value: errorMessage)

                // Redeem button
                Button {
                    redeemCode()
                } label: {
                    Text("Redeem")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(code.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(code.isEmpty)
                .padding(.horizontal)

                Spacer()

                // Help text
                Text("Codes are case-insensitive")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
            .navigationTitle("Redeem Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isCodeFieldFocused = true
            }
            .alert("Success!", isPresented: $showSuccess) {
                Button("Continue") {
                    dismiss()
                }
            } message: {
                Text(successMessage)
            }
        }
    }

    // MARK: - Code Redemption

    private func redeemCode() {
        let result = PromoCodes.validate(code)

        switch result {
        case .influencer:
            handleInfluencerCode()

        case .founder:
            handleFounderCode()

        case .invalid:
            withAnimation {
                errorMessage = "Code not recognized"
            }
            // Haptic feedback for error
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }

    /// Handle influencer code - grants free lifetime access
    private func handleInfluencerCode() {
        // Unlock via StoreManager (writes to Keychain)
        storeManager.unlockViaInfluencerCode()

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Show success and dismiss
        successMessage = "Influencer access granted! Enjoy all premium features."
        showSuccess = true

        // Notify parent view
        onInfluencerUnlock()
    }

    /// Handle founder code - reveals discounted product
    private func handleFounderCode() {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Set flag to show founder product in PaywallView
        showFounderProduct = true

        // Show brief success then dismiss to reveal product
        successMessage = "Founder discount unlocked! Complete your purchase at the special price."
        showSuccess = true
    }
}

// MARK: - Preview

#Preview {
    PromoCodeView(
        showFounderProduct: .constant(false),
        onInfluencerUnlock: {}
    )
    .environment(StoreManager())
}
