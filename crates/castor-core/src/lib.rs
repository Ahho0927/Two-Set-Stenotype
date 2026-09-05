#![forbid(unsafe_code)]

mod context;
mod dictionary;
mod engine;
mod key;
mod stroke;

pub use context::{
    BasicKey, ContextConfidence, EditPlan, OutputAction, ResolveStatus, SelectionState, TextContext,
};
pub use dictionary::{DictionaryError, DictionarySnapshot, DictionarySource, Translation};
pub use engine::{CompletedStroke, Engine, KeyDecision, ResolveResult};
pub use key::{LogicalKey, PhysicalKey};
pub use stroke::{
    CancelReason, EventDisposition, KeyEvent, KeyState, StrokeCompletion, StrokeMachine,
    StrokeParseError, default_captured_keys, normalize_stroke, parse_stroke,
};
