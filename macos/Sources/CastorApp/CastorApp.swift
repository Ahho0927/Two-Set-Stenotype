import AppKit
import QuartzCore
import SwiftUI

@main
struct CastorApplication: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        Settings {
            SettingsBootstrapView(model: model)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {}
        }
    }
}

private struct SettingsBootstrapView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        EmptyView()
    }
}

@MainActor
final class SettingsWindowController: NSObject, NSToolbarDelegate {
    static let shared = SettingsWindowController()

    private let navigation = SettingsNavigationState()
    private let toolbarIdentifier = NSToolbar.Identifier("app.castor.settings.toolbar")
    private var windowController: NSWindowController?

    private override init() {
        super.init()
    }

    func show(model: AppModel) {
        if let window = windowController?.window {
            NSApplication.shared.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let hostingController = NSHostingController(
            rootView: SettingsView(model: model, navigation: navigation)
        )
        let window = NSWindow(contentViewController: hostingController)
        window.title = L10n.string("settings.window_title")
        window.identifier = NSUserInterfaceItemIdentifier("settings")
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.tabbingMode = .disallowed
        window.collectionBehavior.remove(.fullScreenPrimary)
        window.standardWindowButton(.zoomButton)?.isEnabled = false

        let toolbar = NSToolbar(identifier: toolbarIdentifier)
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        toolbar.sizeMode = .regular
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        toolbar.selectedItemIdentifier = navigation.selection.toolbarIdentifier
        window.toolbar = toolbar
        window.toolbarStyle = .preference
        window.setContentSize(navigation.selection.preferredContentSize)
        window.center()

        let controller = NSWindowController(window: window)
        windowController = controller
        NSApplication.shared.activate(ignoringOtherApps: true)
        controller.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        SettingsSection.allCases.map(\.toolbarIdentifier)
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        SettingsSection.allCases.map(\.toolbarIdentifier)
    }

    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        SettingsSection.allCases.map(\.toolbarIdentifier)
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        guard let section = SettingsSection(toolbarIdentifier: itemIdentifier) else { return nil }

        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.label = section.title
        item.paletteLabel = section.title
        item.toolTip = section.title
        item.image = NSImage(
            systemSymbolName: section.systemImage,
            accessibilityDescription: section.title
        )?.withSymbolConfiguration(
            NSImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        )
        item.target = self
        item.action = #selector(selectSection(_:))
        return item
    }

    @objc private func selectSection(_ sender: NSToolbarItem) {
        guard
            let section = SettingsSection(toolbarIdentifier: sender.itemIdentifier),
            let window = windowController?.window
        else { return }

        navigation.selection = section
        window.toolbar?.selectedItemIdentifier = section.toolbarIdentifier
        resize(window, for: section, animated: true)
    }

    private func resize(_ window: NSWindow, for section: SettingsSection, animated: Bool) {
        let oldFrame = window.frame
        let layoutSize = window.contentLayoutRect.size
        let chromeWidth = oldFrame.width - layoutSize.width
        let chromeHeight = oldFrame.height - layoutSize.height
        let targetSize = section.preferredContentSize
        let newSize = NSSize(
            width: targetSize.width + chromeWidth,
            height: targetSize.height + chromeHeight
        )

        var frame = NSRect(
            x: oldFrame.midX - newSize.width / 2,
            y: oldFrame.maxY - newSize.height,
            width: newSize.width,
            height: newSize.height
        )
        if let visibleFrame = (window.screen ?? NSScreen.main)?.visibleFrame {
            frame.origin.x = min(max(frame.origin.x, visibleFrame.minX), visibleFrame.maxX - frame.width)
            frame.origin.y = min(max(frame.origin.y, visibleFrame.minY), visibleFrame.maxY - frame.height)
        }

        guard animated else {
            window.setFrame(frame, display: true)
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(frame, display: true)
        }
    }
}
