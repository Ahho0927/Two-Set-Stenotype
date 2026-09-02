import AppKit
import SwiftUI

enum SceneIdentifier {
    static let settings = "settings"
    static let paperTape = "paper-tape"
}

@main
struct TSSApplication: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        // Keep the window scene first so launching the app presents a visible
        // interface instead of starting only the menu-bar scene.
        Window(L10n.string("settings.window_title"), id: SceneIdentifier.settings) {
            SettingsWindowRoot(model: model)
        }
        .defaultSize(width: 920, height: 560)
        .windowResizability(.contentMinSize)

        WindowGroup(L10n.string("paper_tape"), id: SceneIdentifier.paperTape) {
            PaperTapeWindow(model: model)
        }
        .defaultSize(width: 760, height: 460)
        .windowResizability(.contentMinSize)
    }
}

private struct SettingsWindowRoot: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        SettingsView(model: model)
            .onAppear {
                model.setOpenSettingsAction {
                    openWindow(id: SceneIdentifier.settings)
                }
                focusSettingsWindow()
            }
    }
}

private func focusSettingsWindow() {
    Task { @MainActor in
        // Let SwiftUI create/order the NSWindow before selecting it.
        await Task.yield()
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.windows
            .first(where: { $0.isVisible && $0.canBecomeKey })?
            .makeKeyAndOrderFront(nil)
    }
}
