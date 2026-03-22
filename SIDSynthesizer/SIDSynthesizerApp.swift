// SIDSynthesizerApp.swift

import SwiftUI

@main
struct SIDSynthesizerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 820, minHeight: 560)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 920, height: 640)
    }
}
