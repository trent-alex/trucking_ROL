import SwiftUI

// MARK: - App Theme Colors
// Based on modern crypto wallet UI with lime/chartreuse accent

struct AppTheme {
    // Primary accent - lime/chartreuse
    static let accent = Color(hex: "D4E857")
    static let accentDark = Color(hex: "B8CC3D")

    // Backgrounds - use system colors for dark mode support
    static let backgroundPrimary = Color(.systemGroupedBackground)
    static let backgroundSecondary = Color(.secondarySystemGroupedBackground)
    static let backgroundCard = Color(.systemBackground)

    // Dark elements
    static let darkCard = Color(hex: "1A1A1A")
    static let darkText = Color(hex: "1A1A1A")

    // Text colors - use system colors for dark mode support
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textOnDark = Color.white
    static let textOnAccent = Color(hex: "1A1A1A")

    // Semantic colors
    static let profit = Color(hex: "4CAF50")      // Green for profit
    static let loss = Color(hex: "F44336")         // Red for loss
    static let warning = Color(hex: "FF9800")      // Orange for warnings

    // Button styles
    static let buttonPrimary = accent
    static let buttonSecondary = darkCard

    // Border/Divider - use system colors for dark mode support
    static let border = Color(.separator)
    static let divider = Color(.separator)
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Custom Button Styles

struct AccentButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .foregroundColor(AppTheme.textOnAccent)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? AppTheme.accent : AppTheme.border)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct DarkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .foregroundColor(AppTheme.textOnDark)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.darkCard)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.medium)
            .foregroundColor(AppTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.border, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Card Modifier

struct ThemedCard: ViewModifier {
    var isDark: Bool = false

    func body(content: Content) -> some View {
        content
            .padding()
            .background(isDark ? AppTheme.darkCard : AppTheme.backgroundCard)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func themedCard(isDark: Bool = false) -> some View {
        modifier(ThemedCard(isDark: isDark))
    }
}

// MARK: - Tag/Badge Style

struct AccentTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(AppTheme.textOnAccent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppTheme.accent)
            .cornerRadius(20)
    }
}

struct DarkTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(AppTheme.textOnDark)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppTheme.darkCard)
            .cornerRadius(20)
    }
}
