import SwiftUI

// MARK: - iOS 26 Liquid Glass Design System

/// Centralized design tokens for Kale iOS 26 Liquid Glass design
enum Theme {
    
    // MARK: - Corner Radius Tokens
    /// iOS 26 Liquid Glass uses fluid, rounded surfaces
    enum CornerRadius {
        /// Extra small - for inline elements like chips
        static let xs: CGFloat = 6
        /// Small - for small buttons, tags
        static let sm: CGFloat = 10
        /// Medium - for cards, inputs (primary)
        static let md: CGFloat = 14
        /// Large - for modal sheets, large cards
        static let lg: CGFloat = 20
        /// Extra large - for hero elements
        static let xl: CGFloat = 28
        /// Full - for pills, circular elements
        static let full: CGFloat = 9999
    }
    
    // MARK: - Font Tokens
    /// Ensures minimum 11pt for accessibility compliance
    enum Typography {
        /// Extra small label (11pt minimum)
        static let xs: Font = .system(size: 11, weight: .regular)
        /// Small label (11pt minimum)
        static let sm: Font = .system(size: 13, weight: .regular)
        /// Body text (15pt)
        static let body: Font = .system(size: 15, weight: .regular)
        /// Body medium (15pt)
        static let bodyMedium: Font = .system(size: 15, weight: .medium)
        /// Subheadline (13pt)
        static let subheadline: Font = .system(size: 13, weight: .medium)
        /// Headline (17pt)
        static let headline: Font = .system(size: 17, weight: .semibold)
        /// Title (22pt)
        static let title: Font = .system(size: 22, weight: .bold)
        /// Large title (28pt)
        static let largeTitle: Font = .system(size: 28, weight: .bold)
    }
    
    // MARK: - Spacing Tokens
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
    }
    
    // MARK: - Shadow Tokens
    enum Shadow {
        static let light = (color: Color.black.opacity(0.05), radius: CGFloat(6), x: CGFloat(0), y: CGFloat(2))
        static let medium = (color: Color.black.opacity(0.08), radius: CGFloat(10), x: CGFloat(0), y: CGFloat(4))
        static let heavy = (color: Color.black.opacity(0.12), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
    }
    
    // MARK: - Animation Tokens
    enum Animation {
        static let quick = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.7)
        static let standard = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.6)
        static let bouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.5)
    }
}

// MARK: - Haptic Feedback Manager

enum HapticManager {
    /// Light impact - for subtle UI feedback
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Medium impact - for button taps
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Heavy impact - for significant actions
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Soft impact - for iOS 26 Liquid Glass aesthetic
    static func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
    
    /// Rigid impact - for decisive actions
    static func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }
    
    /// Selection changed - for picker/tab changes
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    /// Success notification
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Warning notification
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Error notification
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}

// MARK: - Button Style Modifiers

struct KaleButtonStyle: ButtonStyle {
    let role: Role
    
    enum Role {
        case primary
        case secondary
        case destructive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(backgroundColor)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
    
    private var backgroundColor: Color {
        switch role {
        case .primary: return .accentGreen
        case .secondary: return .surfaceLight
        case .destructive: return .red
        }
    }
}

// MARK: - Liquid Glass Card Modifier

struct LiquidGlassCard: ViewModifier {
    let isHighlighted: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(isHighlighted ? Color.accentGreen : Color.surfaceLight)
                    .shadow(color: Color.black.opacity(isHighlighted ? 0.05 : 0.08), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .stroke(isHighlighted ? Color.accentGreen.opacity(0.3) : Color.inactiveEmpty.opacity(0.5), lineWidth: 1)
            )
    }
}

extension View {
    func liquidGlassCard(isHighlighted: Bool = false) -> some View {
        modifier(LiquidGlassCard(isHighlighted: isHighlighted))
    }
}

// MARK: - View Extension for Accessibility Helpers

extension View {
    /// Adds descriptive accessibility label and hint
    func kaleAccessibility(label: String, hint: String? = nil, traits: AccessibilityTraits = []) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
}
