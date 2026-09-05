use std::collections::{BTreeSet, HashSet};
use std::fmt;

use crate::{LogicalKey, PhysicalKey};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StrokeParseError(pub String);

impl fmt::Display for StrokeParseError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(&self.0)
    }
}

impl std::error::Error for StrokeParseError {}

pub fn parse_stroke(input: &str) -> Result<Vec<LogicalKey>, StrokeParseError> {
    if input.is_empty() {
        return Err(StrokeParseError("stroke must not be empty".into()));
    }

    let mut keys = BTreeSet::new();
    for token in input.chars() {
        let physical = PhysicalKey::from_token(token)
            .ok_or_else(|| StrokeParseError(format!("unsupported stroke token: {token:?}")))?;
        let logical = LogicalKey::from_physical(physical)
            .ok_or_else(|| StrokeParseError(format!("unsupported stroke token: {token:?}")))?;
        // A chord is a set of physical keys. Dictionary generators may repeat a
        // token to describe two semantic Hangul roles (for example, initial and
        // final ㄱ as `RRK;`), but the realizable stroke still contains one R key.
        // Collapse those repetitions here; dictionary collision detection runs
        // after normalization and still rejects two entries that become equal.
        keys.insert(logical);
    }
    Ok(keys.into_iter().collect())
}

pub fn normalize_stroke(input: &str) -> Result<String, StrokeParseError> {
    let mut keys = parse_stroke(input)?;
    keys.sort_by_key(|key| key.rank());
    Ok(keys.into_iter().map(LogicalKey::token).collect())
}

pub fn default_captured_keys() -> HashSet<PhysicalKey> {
    let mut result = HashSet::new();
    for usage in 0x04..=0x27 {
        if let Some(key) = PhysicalKey::from_hid_usage(usage) {
            result.insert(key);
        }
    }
    result.extend([
        PhysicalKey::LeftShift,
        PhysicalKey::RightShift,
        PhysicalKey::Space,
        PhysicalKey::Minus,
        PhysicalKey::Equal,
        PhysicalKey::LeftBracket,
        PhysicalKey::RightBracket,
        PhysicalKey::Semicolon,
        PhysicalKey::Quote,
        PhysicalKey::Comma,
        PhysicalKey::Period,
        PhysicalKey::Slash,
    ]);
    result
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum KeyState {
    Down,
    Up,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct KeyEvent {
    pub key: PhysicalKey,
    pub state: KeyState,
    pub is_repeat: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EventDisposition {
    Pass,
    Suppress,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CancelReason {
    BypassModifierDuringStroke,
    NonCapturedKeyDuringStroke,
    Interrupted,
}

impl CancelReason {
    pub fn message(self) -> &'static str {
        match self {
            Self::BypassModifierDuringStroke => "bypass modifier pressed during stroke",
            Self::NonCapturedKeyDuringStroke => "non-captured key pressed during stroke",
            Self::Interrupted => "stroke interrupted",
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum StrokeCompletion {
    None,
    Completed(String),
    Cancelled(CancelReason),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StrokeEventResult {
    pub disposition: EventDisposition,
    pub completion: StrokeCompletion,
}

#[derive(Debug)]
pub struct StrokeMachine {
    captured: HashSet<PhysicalKey>,
    pressed_captured: HashSet<PhysicalKey>,
    passthrough_pressed: HashSet<PhysicalKey>,
    bypass_modifiers: HashSet<PhysicalKey>,
    accumulated: HashSet<LogicalKey>,
    cancelled: Option<CancelReason>,
}

impl Default for StrokeMachine {
    fn default() -> Self {
        Self::new(default_captured_keys())
    }
}

impl StrokeMachine {
    pub fn new(captured: HashSet<PhysicalKey>) -> Self {
        Self {
            captured,
            pressed_captured: HashSet::new(),
            passthrough_pressed: HashSet::new(),
            bypass_modifiers: HashSet::new(),
            accumulated: HashSet::new(),
            cancelled: None,
        }
    }

    pub fn set_captured_keys(&mut self, captured: HashSet<PhysicalKey>) {
        self.reset();
        self.captured = captured;
    }

    pub fn captured_keys(&self) -> &HashSet<PhysicalKey> {
        &self.captured
    }

    pub fn reset(&mut self) {
        self.pressed_captured.clear();
        self.passthrough_pressed.clear();
        self.bypass_modifiers.clear();
        self.accumulated.clear();
        self.cancelled = None;
    }

    pub fn interrupt(&mut self, reason: CancelReason) -> Option<CancelReason> {
        if self.pressed_captured.is_empty() {
            return None;
        }
        self.cancelled.get_or_insert(reason);
        self.cancelled
    }

    pub fn handle(&mut self, event: KeyEvent) -> StrokeEventResult {
        if event.key.is_bypass_modifier() {
            return self.handle_bypass_modifier(event);
        }
        if !self.captured.contains(&event.key) {
            if event.state == KeyState::Down && !self.pressed_captured.is_empty() {
                self.cancelled
                    .get_or_insert(CancelReason::NonCapturedKeyDuringStroke);
            }
            return StrokeEventResult {
                disposition: EventDisposition::Pass,
                completion: StrokeCompletion::None,
            };
        }

        match event.state {
            KeyState::Down => self.handle_captured_down(event),
            KeyState::Up => self.handle_captured_up(event),
        }
    }

    fn handle_bypass_modifier(&mut self, event: KeyEvent) -> StrokeEventResult {
        match event.state {
            KeyState::Down => {
                self.bypass_modifiers.insert(event.key);
                if !self.pressed_captured.is_empty() {
                    self.cancelled
                        .get_or_insert(CancelReason::BypassModifierDuringStroke);
                }
            }
            KeyState::Up => {
                self.bypass_modifiers.remove(&event.key);
            }
        }
        StrokeEventResult {
            disposition: EventDisposition::Pass,
            completion: StrokeCompletion::None,
        }
    }

    fn handle_captured_down(&mut self, event: KeyEvent) -> StrokeEventResult {
        if self.passthrough_pressed.contains(&event.key) {
            return StrokeEventResult {
                disposition: EventDisposition::Pass,
                completion: StrokeCompletion::None,
            };
        }
        if self.pressed_captured.contains(&event.key) {
            return StrokeEventResult {
                disposition: EventDisposition::Suppress,
                completion: StrokeCompletion::None,
            };
        }
        if !self.bypass_modifiers.is_empty() && self.pressed_captured.is_empty() {
            self.passthrough_pressed.insert(event.key);
            return StrokeEventResult {
                disposition: EventDisposition::Pass,
                completion: StrokeCompletion::None,
            };
        }

        self.pressed_captured.insert(event.key);
        if let Some(logical) = LogicalKey::from_physical(event.key) {
            self.accumulated.insert(logical);
        }
        StrokeEventResult {
            disposition: EventDisposition::Suppress,
            completion: StrokeCompletion::None,
        }
    }

    fn handle_captured_up(&mut self, event: KeyEvent) -> StrokeEventResult {
        if self.passthrough_pressed.remove(&event.key) {
            return StrokeEventResult {
                disposition: EventDisposition::Pass,
                completion: StrokeCompletion::None,
            };
        }
        if !self.pressed_captured.remove(&event.key) {
            return StrokeEventResult {
                disposition: EventDisposition::Pass,
                completion: StrokeCompletion::None,
            };
        }

        if !self.pressed_captured.is_empty() {
            return StrokeEventResult {
                disposition: EventDisposition::Suppress,
                completion: StrokeCompletion::None,
            };
        }

        let completion = if let Some(reason) = self.cancelled.take() {
            StrokeCompletion::Cancelled(reason)
        } else {
            let mut keys: Vec<_> = self.accumulated.drain().collect();
            keys.sort_by_key(|key| key.rank());
            StrokeCompletion::Completed(keys.into_iter().map(LogicalKey::token).collect())
        };
        self.accumulated.clear();
        StrokeEventResult {
            disposition: EventDisposition::Suppress,
            completion,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn event(key: PhysicalKey, state: KeyState) -> KeyEvent {
        KeyEvent {
            key,
            state,
            is_repeat: false,
        }
    }

    #[test]
    fn normalizes_special_tokens_and_order() {
        assert_eq!(normalize_stroke("KR").unwrap(), "RK");
        assert_eq!(normalize_stroke("_KR^").unwrap(), "^RK_");
        assert_eq!(normalize_stroke("-^").unwrap(), "^-");
        assert_eq!(normalize_stroke("'^").unwrap(), "^'");
        assert_eq!(normalize_stroke("/^").unwrap(), "^/");
        assert_eq!(normalize_stroke("=^").unwrap(), "^=");
    }

    #[test]
    fn captures_comma_and_period_by_default() {
        let captured = default_captured_keys();
        assert!(captured.contains(&PhysicalKey::Comma));
        assert!(captured.contains(&PhysicalKey::Period));
    }

    #[test]
    fn collapses_duplicate_keys_and_rejects_unknown_tokens() {
        assert_eq!(normalize_stroke("RR").unwrap(), "R");
        assert_eq!(normalize_stroke("RRK;").unwrap(), "RK;");
        assert!(normalize_stroke("R!").is_err());
    }

    #[test]
    fn completes_when_last_key_is_released() {
        let mut machine = StrokeMachine::default();
        assert_eq!(
            machine
                .handle(event(PhysicalKey::K, KeyState::Down))
                .disposition,
            EventDisposition::Suppress
        );
        machine.handle(event(PhysicalKey::R, KeyState::Down));
        machine.handle(event(PhysicalKey::K, KeyState::Up));
        let result = machine.handle(event(PhysicalKey::R, KeyState::Up));
        assert_eq!(result.completion, StrokeCompletion::Completed("RK".into()));
    }

    #[test]
    fn merges_both_shift_keys_without_finishing_early() {
        let mut machine = StrokeMachine::default();
        machine.handle(event(PhysicalKey::LeftShift, KeyState::Down));
        machine.handle(event(PhysicalKey::RightShift, KeyState::Down));
        machine.handle(event(PhysicalKey::R, KeyState::Down));
        machine.handle(event(PhysicalKey::LeftShift, KeyState::Up));
        machine.handle(event(PhysicalKey::R, KeyState::Up));
        let result = machine.handle(event(PhysicalKey::RightShift, KeyState::Up));
        assert_eq!(result.completion, StrokeCompletion::Completed("^R".into()));
    }

    #[test]
    fn bypasses_cmd_space() {
        let mut machine = StrokeMachine::default();
        assert_eq!(
            machine
                .handle(event(PhysicalKey::LeftMeta, KeyState::Down))
                .disposition,
            EventDisposition::Pass
        );
        assert_eq!(
            machine
                .handle(event(PhysicalKey::Space, KeyState::Down))
                .disposition,
            EventDisposition::Pass
        );
        machine.handle(event(PhysicalKey::LeftMeta, KeyState::Up));
        assert_eq!(
            machine
                .handle(event(PhysicalKey::Space, KeyState::Up))
                .disposition,
            EventDisposition::Pass
        );
    }

    #[test]
    fn cancels_when_modifier_arrives_mid_stroke() {
        let mut machine = StrokeMachine::default();
        machine.handle(event(PhysicalKey::R, KeyState::Down));
        machine.handle(event(PhysicalKey::LeftMeta, KeyState::Down));
        let result = machine.handle(event(PhysicalKey::R, KeyState::Up));
        assert_eq!(
            result.completion,
            StrokeCompletion::Cancelled(CancelReason::BypassModifierDuringStroke)
        );
    }
}
