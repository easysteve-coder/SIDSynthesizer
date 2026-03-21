import SwiftUI

/// Global BPM beat grid — placed once behind all tracks in MainView.
/// Draws vertical beat lines (every 4 steps) at naturalStepWidth intervals,
/// starting from the step area (right of header column).
struct BPMGridView: View {
    @EnvironmentObject var engine: SequencerEngine

    /// x of the 1px separator between header and step area (null line here).
    private var separatorX: CGFloat {
        12 + VintageTheme.trackHeaderWidth + 1
    }

    /// x of the first step's left edge (separator + 8px horizontal padding).
    private var stepAreaX: CGFloat {
        separatorX + 8
    }

    private var naturalStepWidth: CGFloat {
        CGFloat(engine.stepDisplaySize) + VintageTheme.stepSpacing
    }

    var body: some View {
        Canvas { ctx, size in
            let sw = naturalStepWidth
            let lineColor = Color(red: 0.55, green: 0.42, blue: 0.20).opacity(0.45)
            let style = StrokeStyle(lineWidth: 1.0)

            // ── Null-Linie — flush mit Spurheader-Separator ───────────────
            var zeroPath = Path()
            zeroPath.move(to:    CGPoint(x: separatorX, y: 0))
            zeroPath.addLine(to: CGPoint(x: separatorX, y: size.height))
            ctx.stroke(zeroPath, with: .color(lineColor), style: style)

            // ── Beat-Linien alle 4 Schritte, alle gleich breit ────────────
            var i = 4
            while true {
                let x = stepAreaX + sw * CGFloat(i) - VintageTheme.stepSpacing / 2
                guard x < size.width else { break }

                var path = Path()
                path.move(to:    CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                ctx.stroke(path, with: .color(lineColor), style: style)
                i += 4
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
}
