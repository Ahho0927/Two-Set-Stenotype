import AppKit

@MainActor
final class StatusItemController: NSObject {
    private var statusItem: NSStatusItem?
    private var isEnabled = false
    private var dictionaryStatus = ""
    private let onToggle: () -> Void
    private let onOpenSettings: () -> Void

    init(
        onToggle: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void
    ) {
        self.onToggle = onToggle
        self.onOpenSettings = onOpenSettings
    }

    func setVisible(_ visible: Bool) {
        if visible {
            installIfNeeded()
        } else if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }

    func update(isEnabled: Bool, dictionaryStatus: String) {
        self.isEnabled = isEnabled
        self.dictionaryStatus = dictionaryStatus
        updateButtonImage()
    }

    private func installIfNeeded() {
        guard statusItem == nil else {
            updateButtonImage()
            return
        }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = L10n.string("menu.tooltip")
        }
        statusItem = item
        updateButtonImage()
    }

    private func updateButtonImage() {
        let symbolName = isEnabled ? "keyboard.fill" : "keyboard"
        let description = L10n.string(
            isEnabled ? "menu.enabled_description" : "menu.disabled_description"
        )
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: description)
        image?.isTemplate = true
        statusItem?.button?.image = image
        statusItem?.button?.setAccessibilityLabel(description)
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        if NSApplication.shared.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else {
            onToggle()
        }
    }

    private func showContextMenu() {
        guard let statusItem else { return }
        let menu = NSMenu()
        let toggleTitle = L10n.string(isEnabled ? "steno.turn_off" : "steno.turn_on")
        let toggleItem = NSMenuItem(
            title: toggleTitle,
            action: #selector(toggleFromMenu(_:)),
            keyEquivalent: ""
        )
        toggleItem.target = self
        toggleItem.state = isEnabled ? .on : .off
        menu.addItem(toggleItem)

        let status = NSMenuItem(title: dictionaryStatus, action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(.separator())

        let settings = NSMenuItem(
            title: L10n.string("menu.settings"),
            action: #selector(openSettings(_:)),
            keyEquivalent: ","
        )
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())

        let quit = NSMenuItem(
            title: L10n.string("menu.quit"),
            action: #selector(quitApplication(_:)),
            keyEquivalent: "q"
        )
        quit.target = self
        menu.addItem(quit)

        // Attach the menu only for this click. Keeping it assigned would make
        // AppKit open it for left clicks too, bypassing the toggle action.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func toggleFromMenu(_ sender: Any?) {
        onToggle()
    }

    @objc private func openSettings(_ sender: Any?) {
        onOpenSettings()
    }

    @objc private func quitApplication(_ sender: Any?) {
        NSApplication.shared.terminate(nil)
    }
}
