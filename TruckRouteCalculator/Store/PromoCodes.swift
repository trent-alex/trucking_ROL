import Foundation

/// Promo code validation for influencer and founder access
/// TODO: Replace with backend API validation
enum PromoCodes {

    /// Result of validating a promo code
    enum ValidationResult: Equatable {
        case influencer       // Free lifetime access, no payment
        case founder          // Reveals discounted product for purchase
        case invalid          // Code not recognized
    }

    // MARK: - Influencer Codes (Free Access)

    /// Placeholder influencer codes - grants free lifetime access
    /// TODO: Replace with backend API validation
    static let influencerCodes: Set<String> = [
        "INF-7A3B9C2D-E5F1",
        "INF-8D4E6F1A-B2C3",
        "INF-9E5F7A2B-C3D4",
        "INF-0F6A8B3C-D4E5",
        "INF-1A7B9C4D-E5F6",
        "INF-2B8C0D5E-F6A7",
        "INF-3C9D1E6F-A7B8",
        "INF-4D0E2F7A-B8C9",
        "INF-5E1F3A8B-C9D0",
        "INF-6F2A4B9C-D0E1",
        "INF-7A3B5C0D-E1F2",
        "INF-8B4C6D1E-F2A3",
        "INF-9C5D7E2F-A3B4",
        "INF-0D6E8F3A-B4C5",
        "INF-1E7F9A4B-C5D6"
    ]

    // MARK: - Founder Codes (Discounted Purchase)

    /// Founder codes - reveals discounted lifetime product
    /// TODO: Replace with backend API validation
    static let founderCodes: Set<String> = [
        "FOUND20",
        "EARLY20",
        "PIVOT20",
        "LAUNCH20"
    ]

    // MARK: - Validation

    /// Validates a promo code and returns the appropriate result
    /// - Parameter code: The code entered by the user (case-insensitive)
    /// - Returns: ValidationResult indicating code type or invalid
    static func validate(_ code: String) -> ValidationResult {
        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if influencerCodes.contains(normalizedCode) {
            return .influencer
        }

        if founderCodes.contains(normalizedCode) {
            return .founder
        }

        return .invalid
    }
}
