import SwiftUI

/// Knob-only CC row — lives INSIDE TrackRowView's shared horizontal ScrollView.
/// No ScrollView of its own, no label column.
/// Labels are rendered in TrackRowView's fixed left column to keep them in sync.
struct CCKnobRowView: View {
    @ObservedObject var track: Track
    let ccSlot:      Int
    var accentColor: Color
    @EnvironmentObject private var engine: SequencerEngine

    /// Same formula as TrackRowView — keeps knobs aligned with step buttons under stretch.
    private var stretchedStepWidth: CGFloat {
        let base    = CGFloat(engine.stepDisplaySize)
        let spacing = VintageTheme.stepSpacing
        return (base + spacing)
            * CGFloat(track.stepLengthNumerator)
            / CGFloat(track.stepLengthDenominator)
            - spacing
    }

    /// Height must match TrackRowView.ccRowHeight exactly so left labels align.
    static func rowHeight(stepDisplaySize: Double) -> CGFloat {
        // KnobView layout: arc (kSize+10) + spacing(3) + label(≈12) + spacing(3) + value(≈12)
        // = kSize + 40, plus .padding(.vertical, 5) = 10px → kSize + 50 needed.
        // Use kSize + 48 with a generous floor.
        let kSize = max(20.0, stepDisplaySize - 16.0)
        return max(VintageTheme.ccRowHeight, kSize + 52)
    }

    var body: some View {
        let sw    = stretchedStepWidth
        // Cap kSize so the arc (kSize + 10) never overflows stretchedStepWidth.
        // When stretch shrinks steps the knob scales down; when stretch grows them
        // the knob stays at its natural size based on stepDisplaySize.
        let baseK = CGFloat(engine.stepDisplaySize) - 16
        let kSize = max(12, min(baseK, sw - 10))
        let rowH  = Self.rowHeight(stepDisplaySize: engine.stepDisplaySize)

        HStack(spacing: VintageTheme.stepSpacing) {
            ForEach(0..<track.stepCount, id: \.self) { i in
                let binding = Binding<Double>(
                    get: {
                        Double(ccSlot == 1 ? track.steps[i].cc1Value
                                           : track.steps[i].cc2Value)
                    },
                    set: { v in
                        var updated = track.steps
                        if ccSlot == 1 { updated[i].cc1Value = Int(v) }
                        else           { updated[i].cc2Value = Int(v) }
                        track.steps = updated
                    }
                )
                KnobView(
                    label: "\(i + 1)",
                    value: binding,
                    range: 0...127,
                    size: kSize,
                    accentColor: accentColor
                )
                .frame(width: sw)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(height: rowH)
    }
}
