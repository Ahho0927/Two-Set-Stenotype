import AppKit
import ApplicationServices
import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var accessibilityTrusted = AXIsProcessTrusted()
    @Published var dictionaries: [DictionaryRecord] = []
    @Published private(set) var dictionaryEntryCount = 0
    @Published private(set) var dictionaryStatus = L10n.string("dictionary.none")
    @Published private(set) var selectedCaptureTokens: Set<String>
    @Published private(set) var recentStrokes: [StrokeRecord] = []
    @Published private(set) var toggleShortcut = ToggleShortcut.default
    @Published private(set) var showsDockIcon = false
    @Published private(set) var showsMenuBarIcon = true

    private let core = CoreBridge()
    private let contextProvider = ContextProvider()
    private let emitter = TextEmitter()
    private lazy var eventTap = EventTapController(
        core: core,
        contextProvider: contextProvider,
        emitter: emitter,
        onRecord: { [weak self] record in
            Task { @MainActor in self?.append(record) }
        },
        onToggleShortcut: { [weak self] in
            Task { @MainActor in self?.toggleEnabledFromShortcut() }
        }
    )
    private lazy var statusItemController = StatusItemController(
        onToggle: { [weak self] in self?.toggleEnabledFromShortcut() },
        onOpenSettings: { [weak self] in self?.showSettingsWindow() }
    )
    private var pollTimer: Timer?
    private var workspaceObserver: NSObjectProtocol?
    private var openSettingsAction: (() -> Void)?

    private static let dictionariesKey = "TSS.dictionaryRecords.v1"
    private static let captureTokensKey = "TSS.captureTokens.v2"
    private static let legacyCaptureTokensKey = "TSS.captureTokens.v1"
    private static let toggleShortcutKey = "TSS.toggleShortcut.v1"
    private static let showsDockIconKey = "TSS.showsDockIcon.v1"
    private static let showsMenuBarIconKey = "TSS.showsMenuBarIcon.v1"
    private static let bundledDictionaryNames = ["main", "main_hangul"]

    init() {
        if let stored = UserDefaults.standard.array(forKey: Self.captureTokensKey) as? [String] {
            selectedCaptureTokens = Set(stored)
        } else if let stored = UserDefaults.standard.array(
            forKey: Self.legacyCaptureTokensKey
        ) as? [String] {
            selectedCaptureTokens = Set(stored).union([",", "."])
            UserDefaults.standard.set(
                Array(selectedCaptureTokens).sorted(),
                forKey: Self.captureTokensKey
            )
        } else {
            selectedCaptureTokens = CaptureKeyOption.defaultTokens
        }
        if let data = UserDefaults.standard.data(forKey: Self.toggleShortcutKey),
           let shortcut = try? JSONDecoder().decode(ToggleShortcut.self, from: data) {
            toggleShortcut = shortcut
        }
        if UserDefaults.standard.object(forKey: Self.showsDockIconKey) != nil {
            showsDockIcon = UserDefaults.standard.bool(forKey: Self.showsDockIconKey)
        }
        if UserDefaults.standard.object(forKey: Self.showsMenuBarIconKey) != nil {
            showsMenuBarIcon = UserDefaults.standard.bool(forKey: Self.showsMenuBarIconKey)
        }
        loadPersistedDictionaries()
        applyCapturedKeys()
        reloadDictionaries()
        startPolling()
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.contextProvider.invalidate()
        }
        Task { @MainActor [weak self] in
            self?.startApplicationServices()
        }
    }

    func setEnabled(_ enabled: Bool) {
        guard enabled != isEnabled else { return }
        if enabled {
            accessibilityTrusted = AXIsProcessTrusted()
            guard accessibilityTrusted else {
                requestAccessibilityPermission()
                return
            }
            guard eventTap.start() else {
                dictionaryStatus = L10n.string("event.tap_failed")
                return
            }
            eventTap.setStrokeCaptureEnabled(true)
            isEnabled = true
        } else {
            eventTap.setStrokeCaptureEnabled(false)
            isEnabled = false
        }
        refreshStatusItem()
    }

    func toggleEnabledFromShortcut() {
        setEnabled(!isEnabled)
    }

    func requestAccessibilityPermission() {
        // The imported global constant is not annotated for Swift 6 concurrency.
        let options = ["AXTrustedCheckOptionPrompt": true]
        accessibilityTrusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        if accessibilityTrusted { startEventTapIfPossible() }
    }

    func refreshAccessibilityStatus(requestIfNeeded: Bool = true) {
        accessibilityTrusted = AXIsProcessTrusted()
        if accessibilityTrusted {
            startEventTapIfPossible()
        } else if requestIfNeeded {
            requestAccessibilityPermission()
        }
    }

    func setShowsDockIcon(_ visible: Bool) {
        guard visible != showsDockIcon else { return }
        if !visible, !showsMenuBarIcon {
            showsMenuBarIcon = true
            UserDefaults.standard.set(true, forKey: Self.showsMenuBarIconKey)
            statusItemController.setVisible(true)
        }
        showsDockIcon = visible
        UserDefaults.standard.set(visible, forKey: Self.showsDockIconKey)
        applyDockVisibility()
    }

    func setShowsMenuBarIcon(_ visible: Bool) {
        // MenuBarExtra may write its current insertion state back through this
        // binding while rebuilding the application menu. Publishing the same
        // value here invalidates that menu again and creates an update loop.
        guard visible != showsMenuBarIcon else { return }
        if !visible, !showsDockIcon {
            showsDockIcon = true
            UserDefaults.standard.set(true, forKey: Self.showsDockIconKey)
            applyDockVisibility()
        }
        showsMenuBarIcon = visible
        UserDefaults.standard.set(visible, forKey: Self.showsMenuBarIconKey)
        statusItemController.setVisible(visible)
        refreshStatusItem()
    }

    func showSettingsWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first(where: {
            $0.identifier?.rawValue == "settings"
                || $0.title == L10n.string("settings.window_title")
        }) {
            window.makeKeyAndOrderFront(nil)
            return
        }
        if let openSettingsAction {
            openSettingsAction()
            Task { @MainActor in
                await Task.yield()
                NSApplication.shared.activate(ignoringOtherApps: true)
                NSApplication.shared.windows
                    .first(where: { $0.isVisible && $0.canBecomeKey })?
                    .makeKeyAndOrderFront(nil)
            }
            return
        }
        _ = NSApplication.shared.sendAction(
            Selector(("showSettingsWindow:")),
            to: nil,
            from: nil
        )
    }

    func setOpenSettingsAction(_ action: @escaping () -> Void) {
        openSettingsAction = action
    }

    func setToggleShortcut(_ shortcut: ToggleShortcut) {
        toggleShortcut = shortcut
        if let data = try? JSONEncoder().encode(shortcut) {
            UserDefaults.standard.set(data, forKey: Self.toggleShortcutKey)
        }
        eventTap.setToggleShortcut(shortcut)
    }

    func setShortcutRecording(_ recording: Bool) {
        eventTap.setShortcutMonitoringEnabled(!recording)
    }

    func addDictionary() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.message = L10n.string("dictionary.open_panel")
        guard panel.runModal() == .OK else { return }

        let existingPaths = Set(dictionaries.map(\.path))
        for url in panel.urls where !existingPaths.contains(url.path) {
            let bookmark = try? url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            dictionaries.append(DictionaryRecord(
                id: UUID(),
                name: url.lastPathComponent,
                path: url.path,
                bookmark: bookmark,
                enabled: true,
                error: nil,
                modificationDate: modificationDate(for: url)
            ))
        }
        persistDictionaries()
        reloadDictionaries()
    }

    func removeDictionary(id: UUID) {
        dictionaries.removeAll { $0.id == id }
        persistDictionaries()
        reloadDictionaries()
    }

    func setDictionaryEnabled(id: UUID, enabled: Bool) {
        guard let index = dictionaries.firstIndex(where: { $0.id == id }) else { return }
        dictionaries[index].enabled = enabled
        persistDictionaries()
        reloadDictionaries()
    }

    func reloadDictionaries() {
        var payload: [(id: UUID, name: String, json: String)] = []
        var readFailed = false
        for index in dictionaries.indices {
            dictionaries[index].error = nil
            guard dictionaries[index].enabled else { continue }
            let url = resolveURL(for: dictionaries[index])
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            do {
                let json = try String(contentsOf: url, encoding: .utf8)
                payload.append((dictionaries[index].id, dictionaries[index].name, json))
                dictionaries[index].modificationDate = modificationDate(for: url)
            } catch {
                readFailed = true
                dictionaries[index].error = error.localizedDescription
            }
        }

        guard !readFailed else {
            dictionaryStatus = L10n.string("dictionary.read_failed")
            refreshStatusItem()
            persistDictionaries()
            return
        }
        do {
            dictionaryEntryCount = try core.replaceDictionaries(payload)
            dictionaryStatus = L10n.format(
                "dictionary.loaded",
                payload.count,
                dictionaryEntryCount
            )
        } catch {
            dictionaryStatus = L10n.string("dictionary.invalid")
            applyDictionaryError(error)
        }
        refreshStatusItem()
        persistDictionaries()
    }

    func isCaptureTokenEnabled(_ token: String) -> Bool {
        selectedCaptureTokens.contains(token)
    }

    func setCaptureToken(_ token: String, enabled: Bool) {
        if enabled {
            selectedCaptureTokens.insert(token)
        } else {
            selectedCaptureTokens.remove(token)
        }
        UserDefaults.standard.set(Array(selectedCaptureTokens).sorted(), forKey: Self.captureTokensKey)
        applyCapturedKeys()
    }

    func clearRecentStrokes() {
        recentStrokes.removeAll()
    }

    private func append(_ record: StrokeRecord) {
        recentStrokes.insert(record, at: 0)
        if recentStrokes.count > 100 {
            recentStrokes.removeLast(recentStrokes.count - 100)
        }
    }

    private func applyCapturedKeys() {
        let keys = CaptureKeyOption.all
            .filter { selectedCaptureTokens.contains($0.token) }
            .reduce(into: Set<HIDKey>()) { result, option in
                result.formUnion(option.usages)
            }
        do {
            try core.setCapturedKeys(keys)
        } catch {
            dictionaryStatus = error.localizedDescription
        }
    }

    private func loadPersistedDictionaries() {
        if let data = UserDefaults.standard.data(forKey: Self.dictionariesKey),
           let decoded = try? JSONDecoder().decode([DictionaryRecord].self, from: data) {
            dictionaries = decoded
            return
        }

        guard UserDefaults.standard.object(forKey: Self.dictionariesKey) == nil else { return }
        dictionaries = Self.bundledDictionaryNames.compactMap { resourceName in
            guard let url = Bundle.main.url(
                forResource: resourceName,
                withExtension: "json",
                subdirectory: "Dictionaries"
            ) else { return nil }
            return DictionaryRecord(
                id: UUID(),
                name: url.lastPathComponent,
                path: url.path,
                bookmark: nil,
                enabled: true,
                error: nil,
                modificationDate: modificationDate(for: url),
                bundledResourceName: resourceName
            )
        }
        persistDictionaries()
    }

    private func persistDictionaries() {
        guard let data = try? JSONEncoder().encode(dictionaries) else { return }
        UserDefaults.standard.set(data, forKey: Self.dictionariesKey)
    }

    private func resolveURL(for record: DictionaryRecord) -> URL {
        if let resourceName = record.bundledResourceName,
           let url = Bundle.main.url(
               forResource: resourceName,
               withExtension: "json",
               subdirectory: "Dictionaries"
           ) {
            return url
        }
        if let bookmark = record.bookmark {
            var stale = false
            if let url = try? URL(
                resolvingBookmarkData: bookmark,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            ) {
                return url
            }
        }
        return URL(fileURLWithPath: record.path)
    }

    private func modificationDate(for url: URL) -> Date? {
        try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.pollDictionaries() }
        }
    }

    private func pollDictionaries() {
        refreshAccessibilityStatus(requestIfNeeded: false)
        var changed = false
        for index in dictionaries.indices where dictionaries[index].enabled {
            let date = modificationDate(for: resolveURL(for: dictionaries[index]))
            if date != dictionaries[index].modificationDate {
                dictionaries[index].modificationDate = date
                changed = true
            }
        }
        if changed { reloadDictionaries() }
    }

    private func applyDictionaryError(_ error: Error) {
        guard let bridgeError = error as? BridgeError,
              let data = bridgeError.message.data(using: .utf8),
              let detail = try? JSONDecoder().decode(CoreDictionaryError.self, from: data)
        else { return }
        if let sourceID = detail.sourceId.flatMap(UUID.init(uuidString:)),
           let index = dictionaries.firstIndex(where: { $0.id == sourceID }) {
            dictionaries[index].error = detail.message
        }
    }

    private func startApplicationServices() {
        applyDockVisibility()
        statusItemController.setVisible(showsMenuBarIcon)
        refreshStatusItem()
        eventTap.setToggleShortcut(toggleShortcut)
        accessibilityTrusted = AXIsProcessTrusted()
        if accessibilityTrusted {
            startEventTapIfPossible()
        } else {
            requestAccessibilityPermission()
        }
    }

    private func startEventTapIfPossible() {
        guard !eventTap.isRunning else { return }
        if !eventTap.start() {
            dictionaryStatus = L10n.string("event.tap_failed")
        }
    }

    private func applyDockVisibility() {
        _ = NSApplication.shared.setActivationPolicy(showsDockIcon ? .regular : .accessory)
    }

    private func refreshStatusItem() {
        statusItemController.update(
            isEnabled: isEnabled,
            dictionaryStatus: dictionaryStatus
        )
    }
}

private struct CoreDictionaryError: Decodable {
    let sourceId: String?
    let chord: String?
    let message: String
}
