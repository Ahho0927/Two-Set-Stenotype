import Foundation

enum HIDKey: UInt16, CaseIterable, Codable, Hashable, Sendable {
    case a = 0x04, b, c, d, e, f, g, h, i, j, k, l, m
    case n, o, p, q, r, s, t, u, v, w, x, y, z
    case digit1 = 0x1E, digit2, digit3, digit4, digit5
    case digit6, digit7, digit8, digit9, digit0
    case enter = 0x28
    case escape = 0x29
    case backspace = 0x2A
    case tab = 0x2B
    case space = 0x2C
    case minus = 0x2D
    case equal = 0x2E
    case leftBracket = 0x2F
    case rightBracket = 0x30
    case backslash = 0x31
    case semicolon = 0x33
    case quote = 0x34
    case grave = 0x35
    case comma = 0x36
    case period = 0x37
    case slash = 0x38
    case capsLock = 0x39
    case rightArrow = 0x4F
    case leftArrow = 0x50
    case downArrow = 0x51
    case upArrow = 0x52
    case leftControl = 0xE0
    case leftShift = 0xE1
    case leftAlt = 0xE2
    case leftMeta = 0xE3
    case rightControl = 0xE4
    case rightShift = 0xE5
    case rightAlt = 0xE6
    case rightMeta = 0xE7

    var isModifier: Bool {
        rawValue >= HIDKey.leftControl.rawValue
    }
}

/// `flagsChanged` is neither a key-down nor key-up event. Querying
/// `CGEventSource.keyState` from inside an event-tap callback can still return
/// the state from before the transition, so track each physical modifier from
/// the key code carried by the event. The aggregate group flag lets us recover
/// when the tap starts or restarts while a modifier is already held.
struct ModifierTransitionTracker {
    private var pressed: Set<HIDKey> = []

    mutating func transition(key: HIDKey, groupIsActive: Bool) -> Bool {
        let peers = modifierPeers(for: key)
        guard groupIsActive else {
            pressed.subtract(peers)
            return false
        }

        if pressed.remove(key) != nil {
            return false
        }
        pressed.insert(key)
        return true
    }

    mutating func reset() {
        pressed.removeAll()
    }

    private func modifierPeers(for key: HIDKey) -> Set<HIDKey> {
        switch key {
        case .leftShift, .rightShift: [.leftShift, .rightShift]
        case .leftControl, .rightControl: [.leftControl, .rightControl]
        case .leftAlt, .rightAlt: [.leftAlt, .rightAlt]
        case .leftMeta, .rightMeta: [.leftMeta, .rightMeta]
        case .capsLock: [.capsLock]
        default: [key]
        }
    }
}

struct CaptureKeyOption: Identifiable, Hashable, Sendable {
    let token: String
    let label: String
    let usages: Set<HIDKey>

    var id: String { token }

    static let grave = key("`", .grave)
    static let backslash = key("\\", .backslash)

    static let numberRow: [CaptureKeyOption] = [
        key("1", .digit1), key("2", .digit2), key("3", .digit3), key("4", .digit4),
        key("5", .digit5), key("6", .digit6), key("7", .digit7), key("8", .digit8),
        key("9", .digit9), key("0", .digit0), key("-", .minus), key("=", .equal),
    ]

    static let topRow: [CaptureKeyOption] = [
        key("Q", .q), key("W", .w), key("E", .e), key("R", .r), key("T", .t),
        key("Y", .y), key("U", .u), key("I", .i), key("O", .o), key("P", .p),
        key("[", .leftBracket), key("]", .rightBracket),
    ]

    static let homeRow: [CaptureKeyOption] = [
        key("A", .a), key("S", .s), key("D", .d), key("F", .f), key("G", .g),
        key("H", .h), key("J", .j), key("K", .k), key("L", .l),
        key(";", .semicolon), key("'", .quote),
    ]

    static let bottomRow: [CaptureKeyOption] = [
        CaptureKeyOption(token: "^", label: "Shift", usages: [.leftShift, .rightShift]),
        key("Z", .z), key("X", .x), key("C", .c), key("V", .v), key("B", .b),
        key("N", .n), key("M", .m), key(",", .comma), key(".", .period), key("/", .slash),
    ]

    static let spaceBar = CaptureKeyOption(token: "_", label: "Space", usages: [.space])
    static let keyboardRows = [numberRow, topRow, homeRow, bottomRow]
    static let all = [grave] + keyboardRows.flatMap { $0 } + [backslash, spaceBar]

    // Keep the original capture set enabled. Newly displayed optional keys
    // (grave and backslash) start off until the user explicitly selects them.
    static let defaultTokens = Set((keyboardRows.flatMap { $0 } + [spaceBar]).map(\.token))

    private static func key(_ token: String, _ usage: HIDKey) -> CaptureKeyOption {
        CaptureKeyOption(token: token, label: token, usages: [usage])
    }
}

struct ShortcutModifiers: OptionSet, Codable, Hashable, Sendable {
    let rawValue: UInt8

    static let function = Self(rawValue: 1 << 0)
    static let control = Self(rawValue: 1 << 1)
    static let option = Self(rawValue: 1 << 2)
    static let shift = Self(rawValue: 1 << 3)
    static let command = Self(rawValue: 1 << 4)
}

struct ToggleShortcut: Codable, Equatable, Sendable {
    let key: HIDKey
    let modifiers: ShortcutModifiers

    static let `default` = ToggleShortcut(key: .t, modifiers: .function)

    var keycapLabels: [String] {
        var parts: [String] = []
        if modifiers.contains(.function) { parts.append("fn") }
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        parts.append(key.shortcutLabel)
        return parts
    }

    var displayName: String {
        keycapLabels.joined(separator: " + ")
    }
}

private extension HIDKey {
    var shortcutLabel: String {
        if (HIDKey.a.rawValue...HIDKey.z.rawValue).contains(rawValue),
           let scalar = UnicodeScalar(Int(Character("A").asciiValue!) + Int(rawValue - HIDKey.a.rawValue)) {
            return String(Character(scalar))
        }
        return switch self {
        case .digit1: "1"
        case .digit2: "2"
        case .digit3: "3"
        case .digit4: "4"
        case .digit5: "5"
        case .digit6: "6"
        case .digit7: "7"
        case .digit8: "8"
        case .digit9: "9"
        case .digit0: "0"
        case .enter: "Return"
        case .escape: "Escape"
        case .backspace: "Delete"
        case .tab: "Tab"
        case .space: "Space"
        case .minus: "-"
        case .equal: "="
        case .leftBracket: "["
        case .rightBracket: "]"
        case .backslash: "\\"
        case .semicolon: ";"
        case .quote: "'"
        case .grave: "`"
        case .comma: ","
        case .period: "."
        case .slash: "/"
        case .capsLock: "Caps Lock"
        case .rightArrow: "→"
        case .leftArrow: "←"
        case .downArrow: "↓"
        case .upArrow: "↑"
        case .leftControl, .leftShift, .leftAlt, .leftMeta,
             .rightControl, .rightShift, .rightAlt, .rightMeta:
            "Modifier"
        default:
            "Key \(rawValue)"
        }
    }
}

enum BasicKeyAction: UInt8, Sendable {
    case enter = 1
    case tab = 2
    case backspace = 3
    case escape = 4
}

enum EngineOutput: Sendable, Equatable {
    case text(String)
    case key(BasicKeyAction)
}

struct EngineEditPlan: Sendable, Equatable {
    let deleteSelection: Bool
    let deleteBefore: Int
    let output: EngineOutput
}

enum ContextConfidence: UInt8, Sendable {
    case authoritative = 0
    case tracked = 1
    case unknown = 2
}

enum SelectionState: UInt8, Sendable {
    case none = 0
    case nonEmpty = 1
    case unknown = 2
}

struct CursorContext: Sendable, Equatable {
    let precedingText: String
    let confidence: ContextConfidence
    let selection: SelectionState
    let wasTruncated: Bool

    static let unavailable = CursorContext(
        precedingText: "",
        confidence: .unknown,
        selection: .unknown,
        wasTruncated: false
    )
}

enum ResolutionStatus: UInt8, Sendable {
    case matched = 0
    case unmapped = 1
    case contextUnavailable = 2
    case contextLimitExceeded = 3
    case expired = 4
}

struct StrokeResolution: Sendable {
    let status: ResolutionStatus
    let stroke: String
    let plan: EngineEditPlan?
}

struct CompletedStrokeInfo: Sendable {
    let id: UInt64
    let stroke: String
    let needsContext: Bool
}

enum EngineCompletion: Sendable {
    case none
    case completed(CompletedStrokeInfo)
    case cancelled(String)
    case invalid(String)
}

struct EngineKeyDecision: Sendable {
    let suppress: Bool
    let completion: EngineCompletion
}

struct DictionaryRecord: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var path: String
    var bookmark: Data?
    var enabled: Bool
    var error: String?
    var modificationDate: Date?
    var bundledResourceName: String? = nil
}

struct StrokeRecord: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let stroke: String
    let result: String
    let successful: Bool
}
