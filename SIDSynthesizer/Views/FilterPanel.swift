// FilterPanel.swift
// SID filter controls: cutoff, resonance, LP/BP/HP mode, voice routing.

import SwiftUI

struct FilterPanel: View {
    @ObservedObject var filter: SIDFilter

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            C64SectionHeader(text: "FILTER")

            // ── Cutoff ────────────────────────────────────────────────
            VStack(spacing: 2) {
                HStack {
                    Text("CUTOFF").font(.c64Label).foregroundColor(.c64Dim)
                    Spacer()
                    Text("\(filter.cutoff)")
                        .font(.c64Value).foregroundColor(.c64Cyan)
                    Text(String(format: "%.0f Hz", filter.cutoffFrequency))
                        .font(.c64Small).foregroundColor(.c64Light)
                }
                Slider(value: Binding(get: { Double(filter.cutoff) },
                                     set: { filter.cutoff = Int($0) }),
                       in: 0 ... 2047)
                    .tint(.c64Cyan)
            }

            // ── Resonance ─────────────────────────────────────────────
            VStack(spacing: 2) {
                HStack {
                    Text("RESON").font(.c64Label).foregroundColor(.c64Dim)
                    Spacer()
                    Text("\(filter.resonance)")
                        .font(.c64Value).foregroundColor(.c64Blue)
                }
                Slider(value: Binding(get: { Double(filter.resonance) },
                                     set: { filter.resonance = Int($0.rounded()) }),
                       in: 0 ... 15, step: 1)
                    .tint(.c64Blue)
            }

            Divider().background(Color.c64Border)

            // ── Filter mode ───────────────────────────────────────────
            Text("MODE").font(.c64Label).foregroundColor(.c64Dim)
            HStack(spacing: 4) {
                C64ToggleButton(label: "LP", isOn: $filter.lpOn, width: 38)
                C64ToggleButton(label: "BP", isOn: $filter.bpOn, width: 38)
                C64ToggleButton(label: "HP", isOn: $filter.hpOn, width: 38)
            }

            Divider().background(Color.c64Border)

            // ── Voice routing ─────────────────────────────────────────
            Text("ROUTE").font(.c64Label).foregroundColor(.c64Dim)
            HStack(spacing: 4) {
                ForEach(0 ..< 3, id: \.self) { i in
                    C64ToggleButton(
                        label: "V\(i+1)",
                        isOn: Binding(
                            get: { filter.routeVoice.indices.contains(i) ? filter.routeVoice[i] : false },
                            set: { if filter.routeVoice.indices.contains(i) { filter.routeVoice[i] = $0 } }
                        ),
                        width: 36
                    )
                }
            }

            Divider().background(Color.c64Border)

            // ── Master volume ─────────────────────────────────────────
            VStack(spacing: 2) {
                HStack {
                    Text("VOLUME").font(.c64Label).foregroundColor(.c64Dim)
                    Spacer()
                    Text("\(filter.masterVolume)")
                        .font(.c64Value).foregroundColor(.c64Green)
                }
                Slider(value: Binding(get: { Double(filter.masterVolume) },
                                     set: { filter.masterVolume = Int($0.rounded()) }),
                       in: 0 ... 15, step: 1)
                    .tint(.c64Green)
            }
        }
        .padding(10)
        .background(Color.c64Panel)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.c64Border, lineWidth: 1)
        )
        .cornerRadius(6)
    }
}
