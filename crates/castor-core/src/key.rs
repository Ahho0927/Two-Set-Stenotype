use serde::{Deserialize, Serialize};

/// USB HID keyboard usages. Platform adapters translate native scan codes into these values.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord, Serialize, Deserialize)]
#[repr(u16)]
pub enum PhysicalKey {
    A = 0x04,
    B = 0x05,
    C = 0x06,
    D = 0x07,
    E = 0x08,
    F = 0x09,
    G = 0x0A,
    H = 0x0B,
    I = 0x0C,
    J = 0x0D,
    K = 0x0E,
    L = 0x0F,
    M = 0x10,
    N = 0x11,
    O = 0x12,
    P = 0x13,
    Q = 0x14,
    R = 0x15,
    S = 0x16,
    T = 0x17,
    U = 0x18,
    V = 0x19,
    W = 0x1A,
    X = 0x1B,
    Y = 0x1C,
    Z = 0x1D,
    Digit1 = 0x1E,
    Digit2 = 0x1F,
    Digit3 = 0x20,
    Digit4 = 0x21,
    Digit5 = 0x22,
    Digit6 = 0x23,
    Digit7 = 0x24,
    Digit8 = 0x25,
    Digit9 = 0x26,
    Digit0 = 0x27,
    Enter = 0x28,
    Escape = 0x29,
    Backspace = 0x2A,
    Tab = 0x2B,
    Space = 0x2C,
    Minus = 0x2D,
    Equal = 0x2E,
    LeftBracket = 0x2F,
    RightBracket = 0x30,
    Backslash = 0x31,
    Semicolon = 0x33,
    Quote = 0x34,
    Grave = 0x35,
    Comma = 0x36,
    Period = 0x37,
    Slash = 0x38,
    CapsLock = 0x39,
    RightArrow = 0x4F,
    LeftArrow = 0x50,
    DownArrow = 0x51,
    UpArrow = 0x52,
    LeftControl = 0xE0,
    LeftShift = 0xE1,
    LeftAlt = 0xE2,
    LeftMeta = 0xE3,
    RightControl = 0xE4,
    RightShift = 0xE5,
    RightAlt = 0xE6,
    RightMeta = 0xE7,
}

impl PhysicalKey {
    pub fn from_hid_usage(value: u16) -> Option<Self> {
        Some(match value {
            0x04 => Self::A,
            0x05 => Self::B,
            0x06 => Self::C,
            0x07 => Self::D,
            0x08 => Self::E,
            0x09 => Self::F,
            0x0A => Self::G,
            0x0B => Self::H,
            0x0C => Self::I,
            0x0D => Self::J,
            0x0E => Self::K,
            0x0F => Self::L,
            0x10 => Self::M,
            0x11 => Self::N,
            0x12 => Self::O,
            0x13 => Self::P,
            0x14 => Self::Q,
            0x15 => Self::R,
            0x16 => Self::S,
            0x17 => Self::T,
            0x18 => Self::U,
            0x19 => Self::V,
            0x1A => Self::W,
            0x1B => Self::X,
            0x1C => Self::Y,
            0x1D => Self::Z,
            0x1E => Self::Digit1,
            0x1F => Self::Digit2,
            0x20 => Self::Digit3,
            0x21 => Self::Digit4,
            0x22 => Self::Digit5,
            0x23 => Self::Digit6,
            0x24 => Self::Digit7,
            0x25 => Self::Digit8,
            0x26 => Self::Digit9,
            0x27 => Self::Digit0,
            0x28 => Self::Enter,
            0x29 => Self::Escape,
            0x2A => Self::Backspace,
            0x2B => Self::Tab,
            0x2C => Self::Space,
            0x2D => Self::Minus,
            0x2E => Self::Equal,
            0x2F => Self::LeftBracket,
            0x30 => Self::RightBracket,
            0x31 => Self::Backslash,
            0x33 => Self::Semicolon,
            0x34 => Self::Quote,
            0x35 => Self::Grave,
            0x36 => Self::Comma,
            0x37 => Self::Period,
            0x38 => Self::Slash,
            0x39 => Self::CapsLock,
            0x4F => Self::RightArrow,
            0x50 => Self::LeftArrow,
            0x51 => Self::DownArrow,
            0x52 => Self::UpArrow,
            0xE0 => Self::LeftControl,
            0xE1 => Self::LeftShift,
            0xE2 => Self::LeftAlt,
            0xE3 => Self::LeftMeta,
            0xE4 => Self::RightControl,
            0xE5 => Self::RightShift,
            0xE6 => Self::RightAlt,
            0xE7 => Self::RightMeta,
            _ => return None,
        })
    }

    pub fn is_shift(self) -> bool {
        matches!(self, Self::LeftShift | Self::RightShift)
    }

    pub fn is_bypass_modifier(self) -> bool {
        matches!(
            self,
            Self::LeftControl
                | Self::RightControl
                | Self::LeftAlt
                | Self::RightAlt
                | Self::LeftMeta
                | Self::RightMeta
        )
    }

    pub fn token(self) -> Option<char> {
        Some(match self {
            Self::A => 'A',
            Self::B => 'B',
            Self::C => 'C',
            Self::D => 'D',
            Self::E => 'E',
            Self::F => 'F',
            Self::G => 'G',
            Self::H => 'H',
            Self::I => 'I',
            Self::J => 'J',
            Self::K => 'K',
            Self::L => 'L',
            Self::M => 'M',
            Self::N => 'N',
            Self::O => 'O',
            Self::P => 'P',
            Self::Q => 'Q',
            Self::R => 'R',
            Self::S => 'S',
            Self::T => 'T',
            Self::U => 'U',
            Self::V => 'V',
            Self::W => 'W',
            Self::X => 'X',
            Self::Y => 'Y',
            Self::Z => 'Z',
            Self::Digit1 => '1',
            Self::Digit2 => '2',
            Self::Digit3 => '3',
            Self::Digit4 => '4',
            Self::Digit5 => '5',
            Self::Digit6 => '6',
            Self::Digit7 => '7',
            Self::Digit8 => '8',
            Self::Digit9 => '9',
            Self::Digit0 => '0',
            Self::Space => '_',
            Self::Minus => '-',
            Self::Equal => '=',
            Self::LeftBracket => '[',
            Self::RightBracket => ']',
            Self::Backslash => '\\',
            Self::Semicolon => ';',
            Self::Quote => '\'',
            Self::Grave => '`',
            Self::Comma => ',',
            Self::Period => '.',
            Self::Slash => '/',
            _ if self.is_shift() => '^',
            _ => return None,
        })
    }

    pub fn from_token(token: char) -> Option<Self> {
        Some(match token {
            'A' | 'a' => Self::A,
            'B' | 'b' => Self::B,
            'C' | 'c' => Self::C,
            'D' | 'd' => Self::D,
            'E' | 'e' => Self::E,
            'F' | 'f' => Self::F,
            'G' | 'g' => Self::G,
            'H' | 'h' => Self::H,
            'I' | 'i' => Self::I,
            'J' | 'j' => Self::J,
            'K' | 'k' => Self::K,
            'L' | 'l' => Self::L,
            'M' | 'm' => Self::M,
            'N' | 'n' => Self::N,
            'O' | 'o' => Self::O,
            'P' | 'p' => Self::P,
            'Q' | 'q' => Self::Q,
            'R' | 'r' => Self::R,
            'S' | 's' => Self::S,
            'T' | 't' => Self::T,
            'U' | 'u' => Self::U,
            'V' | 'v' => Self::V,
            'W' | 'w' => Self::W,
            'X' | 'x' => Self::X,
            'Y' | 'y' => Self::Y,
            'Z' | 'z' => Self::Z,
            '1' => Self::Digit1,
            '2' => Self::Digit2,
            '3' => Self::Digit3,
            '4' => Self::Digit4,
            '5' => Self::Digit5,
            '6' => Self::Digit6,
            '7' => Self::Digit7,
            '8' => Self::Digit8,
            '9' => Self::Digit9,
            '0' => Self::Digit0,
            '_' => Self::Space,
            '-' => Self::Minus,
            '=' => Self::Equal,
            '[' => Self::LeftBracket,
            ']' => Self::RightBracket,
            '\\' => Self::Backslash,
            ';' => Self::Semicolon,
            '\'' => Self::Quote,
            '`' => Self::Grave,
            ',' => Self::Comma,
            '.' => Self::Period,
            '/' => Self::Slash,
            '^' => Self::LeftShift,
            _ => return None,
        })
    }

    pub fn canonical_rank(self) -> Option<usize> {
        const ORDER: &str = "1234567890-=QWERTYUIOP[]\\ASDFGHJKL;'ZXCVBNM,./`_";
        if self.is_shift() {
            return Some(0);
        }
        self.token()
            .and_then(|token| ORDER.chars().position(|candidate| candidate == token))
            .map(|index| index + 1)
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum LogicalKey {
    Shift,
    Physical(PhysicalKey),
}

impl LogicalKey {
    pub fn from_physical(key: PhysicalKey) -> Option<Self> {
        if key.is_shift() {
            Some(Self::Shift)
        } else if key.token().is_some() {
            Some(Self::Physical(key))
        } else {
            None
        }
    }

    pub fn token(self) -> char {
        match self {
            Self::Shift => '^',
            Self::Physical(key) => key
                .token()
                .expect("logical physical keys always have a token"),
        }
    }

    pub fn rank(self) -> usize {
        match self {
            Self::Shift => 0,
            Self::Physical(key) => key.canonical_rank().unwrap_or(usize::MAX),
        }
    }
}
