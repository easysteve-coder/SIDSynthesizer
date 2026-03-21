import SwiftUI

// MARK: - Small vintage button (used throughout)

struct VintageSmallButtonStyle: ButtonStyle {
    var isActive: Bool
    var accent:   Color = VintageTheme.amber

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(VintageTheme.monoSmall)
            .foregroundColor(
                isActive
                    ? .black
                    : (configuration.isPressed ? accent : VintageTheme.textSecondary)
            )
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                isActive
                    ? accent
                    : (configuration.isPressed ? accent.opacity(0.25) : VintageTheme.stepInactive)
            )
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isActive ? accent : VintageTheme.stepBorder, lineWidth: 0.75)
            )
    }
}

// MARK: - Pattern selector button (A / B / C / D)

struct VintagePatternButtonStyle: ButtonStyle {
    var isActive: Bool
    var isQueued: Bool = false   // Pattern ist eingereiht — blinkt

    func makeBody(configuration: Configuration) -> some View {
        let queueColor = Color(red: 0.3, green: 0.8, blue: 1.0)
        configuration.label
            .font(VintageTheme.monoBold)
            .foregroundColor(isActive ? .black : (isQueued ? queueColor : VintageTheme.textSecondary))
            .frame(width: 28, height: 24)
            .background(
                isActive
                    ? VintageTheme.amber
                    : (configuration.isPressed ? VintageTheme.amber.opacity(0.2) : VintageTheme.stepInactive)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        isActive ? VintageTheme.amber : (isQueued ? queueColor : VintageTheme.stepBorder),
                        lineWidth: isQueued ? 1.5 : 1
                    )
            )
            .shadow(color: isActive ? VintageTheme.amber.opacity(0.55) : (isQueued ? queueColor.opacity(0.6) : .clear), radius: 5)
    }
}
