import CoreGraphics
import Foundation

final class TextEmitter: @unchecked Sendable {
    static let syntheticMarker: Int64 = 0x5453_535F_4556_4E54

    func emit(_ plan: EngineEditPlan) {
        if plan.deleteSelection {
            postKey(keyCode: 51)
        }
        if plan.deleteBefore > 0 {
            for _ in 0..<plan.deleteBefore {
                postKey(keyCode: 51)
            }
        }
        switch plan.output {
        case let .text(text):
            postText(text)
        case let .key(key):
            postKey(keyCode: virtualKeyCode(for: key))
        }
    }

    private func postText(_ text: String) {
        guard !text.isEmpty else { return }
        let source = CGEventSource(stateID: .combinedSessionState)
        guard
            let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
            let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
        else { return }
        let utf16 = Array(text.utf16)
        utf16.withUnsafeBufferPointer { buffer in
            down.keyboardSetUnicodeString(
                stringLength: buffer.count,
                unicodeString: buffer.baseAddress
            )
            up.keyboardSetUnicodeString(
                stringLength: buffer.count,
                unicodeString: buffer.baseAddress
            )
        }
        markAndPost(down)
        markAndPost(up)
    }

    private func postKey(keyCode: CGKeyCode) {
        let source = CGEventSource(stateID: .combinedSessionState)
        guard
            let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
            let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        else { return }
        markAndPost(down)
        markAndPost(up)
    }

    private func markAndPost(_ event: CGEvent) {
        event.setIntegerValueField(.eventSourceUserData, value: Self.syntheticMarker)
        event.post(tap: .cgSessionEventTap)
    }

    private func virtualKeyCode(for key: BasicKeyAction) -> CGKeyCode {
        switch key {
        case .enter: 36
        case .tab: 48
        case .backspace: 51
        case .escape: 53
        }
    }
}

