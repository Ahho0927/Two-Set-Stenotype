import AppKit
import CoreGraphics
import Foundation

final class EventTapController: @unchecked Sendable {
    typealias RecordHandler = @Sendable (StrokeRecord) -> Void

    private let core: CoreBridge
    private let contextProvider: ContextProvider
    private let emitter: TextEmitter
    private let resolutionQueue = DispatchQueue(label: "app.tss.stroke-resolution")
    private let onRecord: RecordHandler
    private let onToggleShortcut: @Sendable () -> Void
    private let stateLock = NSLock()
    private var strokeCaptureEnabled = false
    private var shortcutMonitoringEnabled = true
    private var toggleShortcut = ToggleShortcut.default
    private var suppressedShortcutKey: HIDKey?
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var modifierTransitions = ModifierTransitionTracker()
    private(set) var isRunning = false

    init(
        core: CoreBridge,
        contextProvider: ContextProvider,
        emitter: TextEmitter,
        onRecord: @escaping RecordHandler,
        onToggleShortcut: @escaping @Sendable () -> Void
    ) {
        self.core = core
        self.contextProvider = contextProvider
        self.emitter = emitter
        self.onRecord = onRecord
        self.onToggleShortcut = onToggleShortcut
    }

    deinit {
        stop()
    }

    func start() -> Bool {
        guard !isRunning else { return true }
        let types: [CGEventType] = [
            .keyDown, .keyUp, .flagsChanged,
            .leftMouseDown, .rightMouseDown, .otherMouseDown,
        ]
        let mask = types.reduce(CGEventMask(0)) { partial, type in
            partial | (CGEventMask(1) << type.rawValue)
        }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.tap = tap
        runLoopSource = source
        isRunning = true
        return true
    }

    func stop() {
        guard isRunning else { return }
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        runLoopSource = nil
        tap = nil
        isRunning = false
        stateLock.lock()
        strokeCaptureEnabled = false
        suppressedShortcutKey = nil
        stateLock.unlock()
        modifierTransitions.reset()
        core.resetInput()
        contextProvider.invalidate()
    }

    func setStrokeCaptureEnabled(_ enabled: Bool) {
        stateLock.lock()
        strokeCaptureEnabled = enabled
        stateLock.unlock()
        core.resetInput()
        contextProvider.invalidate()
    }

    func setToggleShortcut(_ shortcut: ToggleShortcut) {
        stateLock.lock()
        toggleShortcut = shortcut
        suppressedShortcutKey = nil
        stateLock.unlock()
    }

    func setShortcutMonitoringEnabled(_ enabled: Bool) {
        stateLock.lock()
        shortcutMonitoringEnabled = enabled
        if !enabled { suppressedShortcutKey = nil }
        stateLock.unlock()
    }

    fileprivate func handle(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            modifierTransitions.reset()
            core.resetInput()
            contextProvider.invalidate()
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            record(
                stroke: "",
                result: L10n.string("event.tap_recovered"),
                successful: false
            )
            return Unmanaged.passUnretained(event)
        }
        if event.getIntegerValueField(.eventSourceUserData) == TextEmitter.syntheticMarker {
            return Unmanaged.passUnretained(event)
        }
        if type == .leftMouseDown || type == .rightMouseDown || type == .otherMouseDown {
            core.interrupt()
            contextProvider.invalidate()
            return Unmanaged.passUnretained(event)
        }
        guard type == .keyDown || type == .keyUp || type == .flagsChanged else {
            return Unmanaged.passUnretained(event)
        }

        let macKeyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        guard let hidKey = KeyCodeMapper.hidKey(for: macKeyCode) else {
            if type == .keyDown {
                core.interrupt()
                contextProvider.invalidate()
            }
            return Unmanaged.passUnretained(event)
        }
        let isDown: Bool
        if type == .flagsChanged {
            isDown = modifierTransitions.transition(
                key: hidKey,
                groupIsActive: modifierGroupIsActive(for: hidKey, flags: event.flags)
            )
        } else {
            isDown = type == .keyDown
        }
        let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
        if handleToggleShortcut(
            type: type,
            key: hidKey,
            flags: event.flags,
            isRepeat: isRepeat
        ) {
            return nil
        }
        guard isStrokeCaptureEnabled else {
            return Unmanaged.passUnretained(event)
        }
        let decision = core.process(key: hidKey, isDown: isDown, isRepeat: isRepeat)

        switch decision.completion {
        case .none:
            break
        case let .completed(stroke):
            resolutionQueue.async { [weak self] in self?.resolve(stroke) }
        case let .cancelled(reason):
            contextProvider.invalidate()
            record(
                stroke: "",
                result: L10n.format("event.cancelled", String(describing: reason)),
                successful: false
            )
        case let .invalid(message):
            record(
                stroke: "",
                result: L10n.format("event.input_error", message),
                successful: false
            )
        }

        if !decision.suppress, isDown, !hidKey.isModifier {
            switch hidKey {
            case .tab:
                contextProvider.recordPassedTab()
            case .backspace:
                contextProvider.recordPassedBackspace()
            default:
                contextProvider.invalidate()
            }
        }
        return decision.suppress ? nil : Unmanaged.passUnretained(event)
    }

    private var isStrokeCaptureEnabled: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return strokeCaptureEnabled
    }

    private func handleToggleShortcut(
        type: CGEventType,
        key: HIDKey,
        flags: CGEventFlags,
        isRepeat: Bool
    ) -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }

        if type == .keyUp, suppressedShortcutKey == key {
            suppressedShortcutKey = nil
            return true
        }
        guard shortcutMonitoringEnabled, type == .keyDown, !isRepeat else { return false }
        guard key == toggleShortcut.key,
              shortcutModifiers(from: flags) == toggleShortcut.modifiers
        else { return false }

        suppressedShortcutKey = key
        core.resetInput()
        contextProvider.invalidate()
        onToggleShortcut()
        return true
    }

    private func shortcutModifiers(from flags: CGEventFlags) -> ShortcutModifiers {
        var modifiers: ShortcutModifiers = []
        if flags.contains(.maskSecondaryFn) { modifiers.insert(.function) }
        if flags.contains(.maskControl) { modifiers.insert(.control) }
        if flags.contains(.maskAlternate) { modifiers.insert(.option) }
        if flags.contains(.maskShift) { modifiers.insert(.shift) }
        if flags.contains(.maskCommand) { modifiers.insert(.command) }
        return modifiers
    }

    private func modifierGroupIsActive(for key: HIDKey, flags: CGEventFlags) -> Bool {
        switch key {
        case .leftShift, .rightShift:
            flags.contains(.maskShift)
        case .leftControl, .rightControl:
            flags.contains(.maskControl)
        case .leftAlt, .rightAlt:
            flags.contains(.maskAlternate)
        case .leftMeta, .rightMeta:
            flags.contains(.maskCommand)
        case .capsLock:
            flags.contains(.maskAlphaShift)
        default:
            false
        }
    }

    private func resolve(_ stroke: CompletedStrokeInfo) {
        let context = stroke.needsContext ? contextProvider.context() : nil
        let resolution = core.resolve(stroke, context: context)
        guard resolution.status == .matched, let plan = resolution.plan else {
            record(
                stroke: resolution.stroke,
                result: failureDescription(resolution.status),
                successful: false
            )
            return
        }
        emitter.emit(plan)
        contextProvider.record(plan: plan, context: context)
        let outputDescription: String
        switch plan.output {
        case let .text(text): outputDescription = text
        case let .key(key): outputDescription = "<\(key)>"
        }
        record(stroke: resolution.stroke, result: outputDescription, successful: true)
    }

    private func failureDescription(_ status: ResolutionStatus) -> String {
        switch status {
        case .matched: L10n.string("event.no_output")
        case .unmapped: L10n.string("event.unmapped")
        case .contextUnavailable: ""
        case .contextLimitExceeded: L10n.string("event.context_limit")
        case .expired: L10n.string("event.expired")
        }
    }

    private func record(stroke: String, result: String, successful: Bool) {
        onRecord(StrokeRecord(
            date: Date(),
            stroke: stroke,
            result: result,
            successful: successful
        ))
    }
}

private let eventTapCallback: CGEventTapCallBack = { proxy, type, event, userInfo in
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let controller = Unmanaged<EventTapController>.fromOpaque(userInfo).takeUnretainedValue()
    return controller.handle(proxy: proxy, type: type, event: event)
}
