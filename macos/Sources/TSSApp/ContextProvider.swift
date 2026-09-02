import AppKit
import ApplicationServices
import Foundation

struct TextTracker: Sendable {
    private(set) var text = ""
    private(set) var valid = false
    private(set) var processIdentifier: pid_t?
    private(set) var wasTruncated = false

    mutating func invalidate() {
        text = ""
        valid = false
        processIdentifier = nil
        wasTruncated = false
    }

    mutating func seed(_ context: CursorContext, processIdentifier: pid_t) {
        guard context.confidence != .unknown, context.selection != .unknown else {
            invalidate()
            return
        }
        text = context.precedingText
        valid = true
        self.processIdentifier = processIdentifier
        wasTruncated = context.wasTruncated
        trim()
    }

    func context(for processIdentifier: pid_t) -> CursorContext? {
        guard valid, self.processIdentifier == processIdentifier else { return nil }
        return CursorContext(
            precedingText: text,
            confidence: .tracked,
            selection: .none,
            wasTruncated: wasTruncated
        )
    }

    mutating func apply(
        _ plan: EngineEditPlan,
        basedOn context: CursorContext?,
        processIdentifier: pid_t
    ) {
        if let context, context.confidence != .unknown, context.selection != .unknown {
            seed(context, processIdentifier: processIdentifier)
        }
        if !valid || self.processIdentifier != processIdentifier {
            guard canStartTracking(from: plan) else { return }
            text = ""
            valid = true
            self.processIdentifier = processIdentifier
            // The text before the first observed TSS output is unknown. Keeping this
            // flag set lets the core reject a lookup that would have to cross it.
            wasTruncated = true
        }

        if plan.deleteBefore > 0 {
            for _ in 0..<plan.deleteBefore where !text.isEmpty {
                text.removeLast()
            }
        }
        switch plan.output {
        case let .text(output):
            text.append(output)
            trim()
        case .key:
            invalidate()
        }
    }

    mutating func applyPassedTab(processIdentifier: pid_t) {
        guard valid, self.processIdentifier == processIdentifier else { return }
        text.append("\t")
        trim()
    }

    mutating func applyPassedBackspace(processIdentifier: pid_t) {
        guard valid, self.processIdentifier == processIdentifier else { return }
        if !text.isEmpty {
            text.removeLast()
        }
    }

    private func canStartTracking(from plan: EngineEditPlan) -> Bool {
        guard !plan.deleteSelection, plan.deleteBefore == 0 else { return false }
        guard case let .text(output) = plan.output else { return false }
        return !output.isEmpty
    }

    private mutating func trim() {
        let limit = 256
        guard text.count > limit else { return }
        text = String(text.suffix(limit))
        wasTruncated = true
    }
}

final class ContextProvider: @unchecked Sendable {
    private let lock = NSLock()
    private var tracker = TextTracker()

    func context() -> CursorContext {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else {
            return .unavailable
        }
        lock.lock()
        let tracked = tracker.context(for: pid)
        lock.unlock()
        if let tracked { return tracked }

        guard let authoritative = readAccessibilityContext() else {
            return .unavailable
        }
        lock.lock()
        tracker.seed(authoritative, processIdentifier: pid)
        lock.unlock()
        return authoritative
    }

    func record(plan: EngineEditPlan, context: CursorContext?) {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else {
            invalidate()
            return
        }
        lock.lock()
        tracker.apply(plan, basedOn: context, processIdentifier: pid)
        lock.unlock()
    }

    func recordPassedTab() {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else {
            invalidate()
            return
        }
        lock.lock()
        tracker.applyPassedTab(processIdentifier: pid)
        lock.unlock()
    }

    func recordPassedBackspace() {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else {
            invalidate()
            return
        }
        lock.lock()
        tracker.applyPassedBackspace(processIdentifier: pid)
        lock.unlock()
    }

    func invalidate() {
        lock.lock()
        tracker.invalidate()
        lock.unlock()
    }

    private func readAccessibilityContext() -> CursorContext? {
        let system = AXUIElementCreateSystemWide()
        var focusedReference: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            system,
            kAXFocusedUIElementAttribute as CFString,
            &focusedReference
        ) == .success,
        let focusedReference
        else { return nil }

        let focused = unsafeDowncast(focusedReference, to: AXUIElement.self)
        var selectionReference: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            focused,
            kAXSelectedTextRangeAttribute as CFString,
            &selectionReference
        ) == .success,
        let selectionReference
        else { return nil }

        let selectionValue = unsafeDowncast(selectionReference, to: AXValue.self)
        guard AXValueGetType(selectionValue) == .cfRange else { return nil }
        var selectionRange = CFRange()
        guard AXValueGetValue(selectionValue, .cfRange, &selectionRange), selectionRange.location >= 0 else {
            return nil
        }

        let fetchLength = min(selectionRange.location, 1024)
        let fetchStart = selectionRange.location - fetchLength
        var fetchRange = CFRange(location: fetchStart, length: fetchLength)
        guard let fetchRangeValue = AXValueCreate(.cfRange, &fetchRange) else { return nil }

        var textReference: CFTypeRef?
        var text: String?
        if AXUIElementCopyParameterizedAttributeValue(
            focused,
            kAXStringForRangeParameterizedAttribute as CFString,
            fetchRangeValue,
            &textReference
        ) == .success {
            text = string(from: textReference)
        }

        if text == nil {
            var valueReference: CFTypeRef?
            if AXUIElementCopyAttributeValue(
                focused,
                kAXValueAttribute as CFString,
                &valueReference
            ) == .success,
            let fullText = string(from: valueReference) {
                let nsText = fullText as NSString
                guard selectionRange.location <= nsText.length else { return nil }
                text = nsText.substring(with: NSRange(location: fetchStart, length: fetchLength))
            }
        }

        guard let text else { return nil }
        let wasCharacterTruncated = text.count > 256
        let suffix = String(text.suffix(256))
        return CursorContext(
            precedingText: suffix,
            confidence: .authoritative,
            selection: selectionRange.length > 0 ? .nonEmpty : .none,
            wasTruncated: fetchStart > 0 || wasCharacterTruncated
        )
    }

    private func string(from reference: CFTypeRef?) -> String? {
        guard let reference else { return nil }
        if let value = reference as? String { return value }
        if let attributed = reference as? NSAttributedString { return attributed.string }
        return nil
    }
}
