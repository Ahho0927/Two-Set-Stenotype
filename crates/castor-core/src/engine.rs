use std::collections::{HashMap, HashSet, VecDeque};

use crate::context::resolve_translation;
use crate::{
    CancelReason, DictionarySnapshot, DictionarySource, EditPlan, EventDisposition, KeyEvent,
    PhysicalKey, ResolveStatus, StrokeCompletion, StrokeMachine, TextContext, Translation,
};

const MAX_PENDING_STROKES: usize = 1024;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CompletedStroke {
    pub id: u64,
    pub stroke: String,
    pub needs_context: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct KeyDecision {
    pub disposition: EventDisposition,
    pub completed: Option<CompletedStroke>,
    pub cancelled: Option<CancelReason>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ResolveResult {
    pub status: ResolveStatus,
    pub stroke: Option<String>,
    pub plan: Option<EditPlan>,
}

#[derive(Debug, Clone)]
struct PendingStroke {
    stroke: String,
    translation: Option<Translation>,
}

#[derive(Debug)]
pub struct Engine {
    machine: StrokeMachine,
    dictionary: DictionarySnapshot,
    pending: HashMap<u64, PendingStroke>,
    pending_order: VecDeque<u64>,
    next_pending_id: u64,
}

impl Default for Engine {
    fn default() -> Self {
        Self {
            machine: StrokeMachine::default(),
            dictionary: DictionarySnapshot::default(),
            pending: HashMap::new(),
            pending_order: VecDeque::new(),
            next_pending_id: 1,
        }
    }
}

impl Engine {
    pub fn install_dictionary(&mut self, snapshot: DictionarySnapshot) {
        self.dictionary = snapshot;
    }

    pub fn replace_dictionaries(
        &mut self,
        sources: &[DictionarySource],
    ) -> Result<usize, crate::DictionaryError> {
        let snapshot = DictionarySnapshot::build(sources)?;
        let count = snapshot.len();
        self.install_dictionary(snapshot);
        Ok(count)
    }

    pub fn set_captured_keys(&mut self, keys: HashSet<PhysicalKey>) {
        self.machine.set_captured_keys(keys);
    }

    pub fn reset_input(&mut self) {
        self.machine.reset();
        self.pending.clear();
        self.pending_order.clear();
    }

    pub fn interrupt(&mut self) -> Option<CancelReason> {
        self.machine.interrupt(CancelReason::Interrupted)
    }

    pub fn process_key(&mut self, event: KeyEvent) -> KeyDecision {
        let result = self.machine.handle(event);
        match result.completion {
            StrokeCompletion::None => KeyDecision {
                disposition: result.disposition,
                completed: None,
                cancelled: None,
            },
            StrokeCompletion::Cancelled(reason) => KeyDecision {
                disposition: result.disposition,
                completed: None,
                cancelled: Some(reason),
            },
            StrokeCompletion::Completed(stroke) => {
                let translation = self
                    .dictionary
                    .get(&stroke)
                    .map(|entry| entry.translation.clone());
                let needs_context = translation.as_ref().is_some_and(Translation::needs_context);
                let id = self.next_pending_id;
                self.next_pending_id = self.next_pending_id.wrapping_add(1).max(1);
                self.pending.insert(
                    id,
                    PendingStroke {
                        stroke: stroke.clone(),
                        translation,
                    },
                );
                self.pending_order.push_back(id);
                while self.pending_order.len() > MAX_PENDING_STROKES {
                    if let Some(expired) = self.pending_order.pop_front() {
                        self.pending.remove(&expired);
                    }
                }
                KeyDecision {
                    disposition: result.disposition,
                    completed: Some(CompletedStroke {
                        id,
                        stroke,
                        needs_context,
                    }),
                    cancelled: None,
                }
            }
        }
    }

    pub fn resolve_pending(&mut self, id: u64, context: Option<&TextContext>) -> ResolveResult {
        let Some(pending) = self.pending.remove(&id) else {
            return ResolveResult {
                status: ResolveStatus::Unmapped,
                stroke: None,
                plan: None,
            };
        };
        if let Some(index) = self
            .pending_order
            .iter()
            .position(|candidate| *candidate == id)
        {
            self.pending_order.remove(index);
        }
        let resolution = resolve_translation(pending.translation.as_ref(), context);
        ResolveResult {
            status: resolution.status,
            stroke: Some(pending.stroke),
            plan: resolution.plan,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{ContextConfidence, KeyState, OutputAction, SelectionState};

    fn key(key: PhysicalKey, state: KeyState) -> KeyEvent {
        KeyEvent {
            key,
            state,
            is_repeat: false,
        }
    }

    #[test]
    fn captures_dictionary_snapshot_at_stroke_completion() {
        let mut engine = Engine::default();
        engine
            .replace_dictionaries(&[DictionarySource {
                id: "one".into(),
                name: "one.json".into(),
                json: r#"{"R":"가"}"#.into(),
            }])
            .unwrap();
        engine.process_key(key(PhysicalKey::R, KeyState::Down));
        let completed = engine
            .process_key(key(PhysicalKey::R, KeyState::Up))
            .completed
            .unwrap();

        engine
            .replace_dictionaries(&[DictionarySource {
                id: "two".into(),
                name: "two.json".into(),
                json: r#"{"R":"나"}"#.into(),
            }])
            .unwrap();
        let result = engine.resolve_pending(completed.id, None);
        assert_eq!(result.plan.unwrap().output, OutputAction::Text("가".into()));
    }

    #[test]
    fn resolves_contextual_translation() {
        let mut engine = Engine::default();
        engine
            .replace_dictionaries(&[DictionarySource {
                id: "main".into(),
                name: "main.json".into(),
                json: r#"{"R":{"condition":"previousHangulBatchim","batchim":{"text":"은"},"noBatchim":{"text":"는"}}}"#.into(),
            }])
            .unwrap();
        engine.process_key(key(PhysicalKey::R, KeyState::Down));
        let completed = engine
            .process_key(key(PhysicalKey::R, KeyState::Up))
            .completed
            .unwrap();
        assert!(completed.needs_context);
        let context = TextContext {
            preceding_text: "집".into(),
            confidence: ContextConfidence::Tracked,
            selection: SelectionState::None,
            was_truncated: false,
        };
        let result = engine.resolve_pending(completed.id, Some(&context));
        assert_eq!(result.plan.unwrap().output, OutputAction::Text("은".into()));
    }
}
