import SwiftUI

// MARK: - KnobView

struct KnobView: View {
    let label: String
    @Binding var value: Double
    var range:       ClosedRange<Double> = 0...127
    var size:        CGFloat             = VintageTheme.knobSize
    var accentColor: Color               = VintageTheme.amber

    @State private var dragging:      Bool    = false
    @State private var dragStartY:    CGFloat = 0
    @State private var dragStartVal:  Double  = 0

    private var normalized:    Double { (value - range.lowerBound) / (range.upperBound - range.lowerBound) }
    private var indicatorDeg:  Double { -135 + normalized * 270 }

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                // Range arc (dim background track)
                KnobArc(fromDeg: -135, toDeg: 135)
                    .stroke(VintageTheme.amberDim,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: size + 10, height: size + 10)

                // Value arc (bright fill)
                KnobArc(fromDeg: -135, toDeg: -135 + normalized * 270)
                    .stroke(accentColor,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: size + 10, height: size + 10)

                // Knob body
                Circle()
                    .fill(RadialGradient(
                        colors: [
                            VintageTheme.knobHighlight,
                            VintageTheme.knobBody,
                            Color.black.opacity(0.88)
                        ],
                        center: UnitPoint(x: 0.32, y: 0.28),
                        startRadius: 1,
                        endRadius: size * 0.56))
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.65), radius: 4, x: 2, y: 3)

                // Indicator line
                Capsule()
                    .fill(dragging ? VintageTheme.amberGlow : accentColor)
                    .frame(width: 2.5, height: size * 0.28)
                    .offset(y: -(size * 0.25))
                    .rotationEffect(.degrees(indicatorDeg))
                    .shadow(color: accentColor.opacity(dragging ? 1.0 : 0.45), radius: 4)
            }
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        if !dragging {
                            dragging     = true
                            dragStartY   = g.startLocation.y
                            dragStartVal = value
                        }
                        let delta = (dragStartY - g.location.y) / 140.0
                        value = (dragStartVal + delta * (range.upperBound - range.lowerBound))
                            .clamped(to: range)
                    }
                    .onEnded { _ in dragging = false }
            )
            .onTapGesture(count: 2) {
                // Double-click resets to center
                value = (range.lowerBound + range.upperBound) / 2
            }

            Text(label)
                .font(VintageTheme.monoSmall)
                .foregroundColor(VintageTheme.textSecondary)

            Text("\(Int(value))")
                .font(VintageTheme.monoSmall)
                .foregroundColor(VintageTheme.textAmber)
                .monospacedDigit()
        }
    }
}

// MARK: - Arc shape
// 0° = 12 o'clock, positive = clockwise (screen coords)

private struct KnobArc: Shape {
    var fromDeg: Double
    var toDeg:   Double

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2 - 1
        // SwiftUI: 0° = 3 o'clock, clockwise on screen = clockwise: false (flipped y)
        // Subtract 90° so our 0° = 12 o'clock
        p.addArc(center: c, radius: r,
                 startAngle: .degrees(fromDeg - 90),
                 endAngle:   .degrees(toDeg   - 90),
                 clockwise:  false)
        return p
    }
}

// MARK: - Helpers

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}
