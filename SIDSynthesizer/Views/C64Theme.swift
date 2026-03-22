// C64Theme.swift
// Visual constants and reusable modifiers for the authentic C64 look.

import SwiftUI

// MARK: - Colors

extension Color {
    // Classic Commodore 64 palette
    static let c64Dark     = Color(red: 0.05, green: 0.05, blue: 0.18)   // window bg
    static let c64Panel    = Color(red: 0.09, green: 0.09, blue: 0.26)   // panel bg
    static let c64Border   = Color(red: 0.22, green: 0.22, blue: 0.55)   // border
    static let c64Blue     = Color(red: 0.35, green: 0.35, blue: 0.85)   // button active
    static let c64Light    = Color(red: 0.65, green: 0.65, blue: 1.00)   // text / label
    static let c64Bright   = Color(red: 0.80, green: 0.80, blue: 1.00)   // highlighted text
    static let c64Cyan     = Color(red: 0.40, green: 0.90, blue: 1.00)   // accent / LED on
    static let c64Dim      = Color(red: 0.25, green: 0.25, blue: 0.50)   // inactive
    static let c64Green    = Color(red: 0.35, green: 0.85, blue: 0.45)   // gate LED
    static let c64Red      = Color(red: 1.00, green: 0.30, blue: 0.30)   // danger
}

// MARK: - Typography

extension Font {
    static let c64Title  = Font.system(size: 14, weight: .bold,  design: .monospaced)
    static let c64Label  = Font.system(size: 11, weight: .medium, design: .monospaced)
    static let c64Small  = Font.system(size: 10, weight: .regular, design: .monospaced)
    static let c64Value  = Font.system(size: 11, weight: .bold,  design: .monospaced)
}

// MARK: - Reusable components

/// C64-style toggle button
struct C64ToggleButton: View {
    let label: String
    @Binding var isOn: Bool
    var width: CGFloat = 50

    var body: some View {
        Button(label) { isOn.toggle() }
            .font(.c64Label)
            .frame(width: width, height: 24)
            .background(isOn ? Color.c64Blue : Color.c64Panel)
            .foregroundColor(isOn ? Color.c64Bright : Color.c64Dim)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isOn ? Color.c64Cyan : Color.c64Border, lineWidth: 1)
            )
            .cornerRadius(3)
    }
}

/// Vertical ADSR slider (0 … 15)
struct ADSRSlider: View {
    let label: String
    @Binding var value: Int
    var color: Color = .c64Cyan

    var body: some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.c64Small)
                .foregroundColor(.c64Light)
                .frame(width: 22)

            Slider(
                value: Binding(
                    get:  { Double(value) },
                    set:  { value = Int($0.rounded()) }
                ),
                in: 0 ... 15,
                step: 1
            )
            .rotationEffect(.degrees(-90))
            .frame(width: 80, height: 22)
            .tint(color)

            Text(label)
                .font(.c64Small)
                .foregroundColor(.c64Dim)
        }
        .frame(width: 24, height: 110)
    }
}

/// Small LED indicator
struct C64LED: View {
    var on: Bool
    var color: Color = .c64Green

    var body: some View {
        Circle()
            .fill(on ? color : Color.c64Dim.opacity(0.4))
            .frame(width: 8, height: 8)
            .shadow(color: on ? color : .clear, radius: 4)
    }
}

/// Section header label with C64 styling
struct C64SectionHeader: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.c64Title)
            .foregroundColor(.c64Bright)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.c64Border.opacity(0.5))
            .cornerRadius(3)
    }
}

/// Standard labeled knob (wraps a Slider styled as a horizontal strip)
struct C64Knob: View {
    let label: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 0 ... 1
    var format: String = "%.2f"

    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: format, value))
                .font(.c64Value)
                .foregroundColor(.c64Cyan)
                .frame(width: 52)
            Slider(value: $value, in: range)
                .tint(.c64Blue)
                .frame(width: 64)
            Text(label)
                .font(.c64Small)
                .foregroundColor(.c64Dim)
        }
    }
}
