import CoreGraphics

enum KeyCodeMapper {
    static func hidKey(for keyCode: CGKeyCode) -> HIDKey? {
        switch keyCode {
        case 0: .a
        case 1: .s
        case 2: .d
        case 3: .f
        case 4: .h
        case 5: .g
        case 6: .z
        case 7: .x
        case 8: .c
        case 9: .v
        case 11: .b
        case 12: .q
        case 13: .w
        case 14: .e
        case 15: .r
        case 16: .y
        case 17: .t
        case 18: .digit1
        case 19: .digit2
        case 20: .digit3
        case 21: .digit4
        case 22: .digit6
        case 23: .digit5
        case 24: .equal
        case 25: .digit9
        case 26: .digit7
        case 27: .minus
        case 28: .digit8
        case 29: .digit0
        case 30: .rightBracket
        case 31: .o
        case 32: .u
        case 33: .leftBracket
        case 34: .i
        case 35: .p
        case 36: .enter
        case 37: .l
        case 38: .j
        case 39: .quote
        case 40: .k
        case 41: .semicolon
        case 42: .backslash
        case 43: .comma
        case 44: .slash
        case 45: .n
        case 46: .m
        case 47: .period
        case 48: .tab
        case 49: .space
        case 50: .grave
        case 51: .backspace
        case 53: .escape
        case 54: .rightMeta
        case 55: .leftMeta
        case 56: .leftShift
        case 57: .capsLock
        case 58: .leftAlt
        case 59: .leftControl
        case 60: .rightShift
        case 61: .rightAlt
        case 62: .rightControl
        case 123: .leftArrow
        case 124: .rightArrow
        case 125: .downArrow
        case 126: .upArrow
        default: nil
        }
    }
}

