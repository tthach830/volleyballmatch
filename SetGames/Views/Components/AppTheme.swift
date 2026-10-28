import SwiftUI

public struct AppTheme {
    // Screen & Surface Backgrounds (Crisp, modern, airy Apple Light Theme)
    public static let screenBackground = Color(red: 0.965, green: 0.970, blue: 0.978) // Crisp light canvas
    public static let cardBackground = Color.white // Pure white card
    public static let cardBackgroundSecondary = Color(red: 0.955, green: 0.965, blue: 0.978)
    public static let inputBackground = Color(red: 0.940, green: 0.950, blue: 0.965)
    public static let capsuleBackground = Color(red: 0.920, green: 0.930, blue: 0.945)
    
    // Borders & Dividers
    public static let cardBorder = Color.black.opacity(0.08)
    public static let borderSubtle = Color.black.opacity(0.05)
    public static let cardShadow = Color.black.opacity(0.04)
    
    // Text Hierarchy (High-contrast, elegant typography)
    public static let textPrimary = Color(red: 0.06, green: 0.09, blue: 0.16) // Rich deep slate black
    public static let textSecondary = Color(red: 0.40, green: 0.45, blue: 0.55) // Slate gray
    public static let textTertiary = Color(red: 0.60, green: 0.65, blue: 0.72) // Subtle muted
    
    // Accent Colors
    public static let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.0) // #FF6A00 Beach Orange
    public static let brandOrangeDark = Color(red: 0.92, green: 0.35, blue: 0.05)
    public static let accentTeal = Color(red: 0.17, green: 0.43, blue: 0.48)
    public static let accentCyan = Color(red: 0.02, green: 0.52, blue: 0.78)
}
