import SwiftUI

enum VintageTheme {
    static let appVersion = "0.9"    // ← increment with each build session
    // Background / panels
    static let background     = Color(red: 0.08, green: 0.08, blue: 0.09)
    static let panel          = Color(red: 0.13, green: 0.13, blue: 0.145)
    static let panelDark      = Color(red: 0.10, green: 0.10, blue: 0.11)
    static let panelBorder    = Color(red: 0.28, green: 0.24, blue: 0.18)

    // Amber LED palette
    static let amber          = Color(red: 1.00, green: 0.55, blue: 0.00)
    static let amberBright    = Color(red: 1.00, green: 0.80, blue: 0.20)
    static let amberDim       = Color(red: 0.38, green: 0.20, blue: 0.00)
    static let amberGlow      = Color(red: 1.00, green: 0.88, blue: 0.35)

    // Step buttons
    static let stepActive     = Color(red: 0.90, green: 0.45, blue: 0.00)
    static let stepCurrent    = Color(red: 1.00, green: 0.80, blue: 0.15)
    static let stepInactive   = Color(red: 0.17, green: 0.17, blue: 0.18)
    static let stepBorder     = Color(red: 0.30, green: 0.27, blue: 0.20)

    // Knobs
    static let knobBody       = Color(red: 0.22, green: 0.22, blue: 0.24)
    static let knobHighlight  = Color(red: 0.42, green: 0.42, blue: 0.46)

    // Text
    static let textPrimary    = Color(red: 0.85, green: 0.80, blue: 0.68)
    static let textSecondary  = Color(red: 0.48, green: 0.44, blue: 0.36)
    static let textAmber      = Color(red: 1.00, green: 0.65, blue: 0.10)
    static let textDim        = Color(red: 0.28, green: 0.25, blue: 0.20)

    // Per-track accent colors
    static let trackColors: [Color] = [
        Color(red: 1.00, green: 0.55, blue: 0.00), // amber
        Color(red: 0.20, green: 0.70, blue: 1.00), // blue
        Color(red: 0.30, green: 0.85, blue: 0.45), // green
        Color(red: 0.90, green: 0.25, blue: 0.65), // magenta
        Color(red: 0.80, green: 0.80, blue: 0.20), // yellow
        Color(red: 0.60, green: 0.30, blue: 1.00), // purple
        Color(red: 1.00, green: 0.35, blue: 0.25), // red
        Color(red: 0.20, green: 0.90, blue: 0.80), // cyan
    ]

    // Fonts
    static let monoSmall  = Font.system(size:  9, weight: .regular,  design: .monospaced)
    static let monoMedium = Font.system(size: 11, weight: .regular,  design: .monospaced)
    static let monoBold   = Font.system(size: 11, weight: .semibold, design: .monospaced)
    static let monoLarge  = Font.system(size: 14, weight: .semibold, design: .monospaced)
    static let monoTitle  = Font.system(size: 17, weight: .bold,     design: .monospaced)

    // Layout
    static let stepSize:         CGFloat = 54
    static let stepSpacing:      CGFloat =  4
    static let knobSize:         CGFloat = 38
    static let knobSmall:        CGFloat = 30
    static let trackHeaderWidth: CGFloat = 224
    static let ccRowHeight:      CGFloat = 68
}
