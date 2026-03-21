import SwiftUI
import AppKit

// Handles "Unsaved changes?" when the window closes.
final class AppDelegate: NSObject, NSApplicationDelegate {
    var engine: SequencerEngine?

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let engine, engine.hasUnsavedChanges else { return .terminateNow }
        let alert = NSAlert()
        alert.messageText     = "Ungespeicherte Änderungen"
        alert.informativeText = "Soll das aktuelle Preset vor dem Beenden gespeichert werden?"
        alert.addButton(withTitle: "Speichern")
        alert.addButton(withTitle: "Verwerfen")
        alert.addButton(withTitle: "Abbrechen")
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            engine.savePreset()
            return engine.hasUnsavedChanges ? .terminateCancel : .terminateNow
        case .alertSecondButtonReturn:
            return .terminateNow
        default:
            return .terminateCancel
        }
    }
}

// AppStorage doesn't bind directly inside .commands — use a small View wrapper.
private struct TooltipToggleItem: View {
    @AppStorage("showTooltips") private var showTooltips: Bool = true
    var body: some View {
        Toggle("Tooltips anzeigen", isOn: $showTooltips)
            .keyboardShortcut("T", modifiers: [.command, .option])
    }
}

@main
struct VintageSequencerApp: App {
    @StateObject private var engine = SequencerEngine()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup("Vintage Step Sequencer") {
            MainView()
                .environmentObject(engine)
                .preferredColorScheme(.dark)
                .onAppear { appDelegate.engine = engine }
        }
        .defaultSize(width: 1200, height: 700)
        .commands {
            // Remove "New Window" from File menu — single-window app
            CommandGroup(replacing: .newItem) {}

            CommandMenu("Ansicht") {
                TooltipToggleItem()
            }

            // File menu: Open / Save Preset
            CommandGroup(replacing: .saveItem) {
                Button("Save Preset…") { engine.savePreset() }
                    .keyboardShortcut("s", modifiers: .command)
                Button("Open Preset…") { engine.loadPreset() }
                    .keyboardShortcut("o", modifiers: .command)
            }

            CommandMenu("Sequencer") {
                Button(engine.isPlaying ? "Stop" : "Play") {
                    engine.isPlaying ? engine.stop() : engine.play()
                }
                .keyboardShortcut(.space, modifiers: [])

                Divider()

                ForEach(0..<4) { i in
                    Button("Pattern \(["A","B","C","D"][i])") {
                        engine.switchPattern(i)
                    }
                    .keyboardShortcut(KeyEquivalent(Character(String(i + 1))),
                                      modifiers: .command)
                }

                Divider()

                ForEach(0..<min(engine.numTracks, engine.currentPattern.tracks.count), id: \.self) { i in
                    Button("\(engine.currentPattern.tracks[i].isMuted ? "Unmute" : "Mute") Track \(i + 1)") {
                        engine.currentPattern.tracks[i].isMuted.toggle()
                    }
                    .keyboardShortcut(KeyEquivalent(Character(String(i + 1))),
                                      modifiers: .option)
                }

                Divider()

                Button("Copy Pattern") { engine.copyCurrentPattern() }
                    .keyboardShortcut("c", modifiers: [.command, .option])

                Button("Paste Pattern") { engine.pasteToCurrentPattern() }
                    .keyboardShortcut("v", modifiers: [.command, .option])
                    .disabled(engine.clipboard == nil)
            }
        }
    }
}
