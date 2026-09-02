#![allow(unsafe_code)]

use std::collections::HashSet;
use std::ptr;
use std::slice;
use std::sync::Mutex;

use serde::Deserialize;
use tss_core::{
    ContextConfidence, DictionarySnapshot, DictionarySource, Engine, EventDisposition, KeyEvent,
    KeyState, OutputAction, PhysicalKey, ResolveStatus, SelectionState, TextContext,
};

pub struct TssEngine {
    inner: Mutex<Engine>,
}

#[repr(C)]
pub struct TssBuffer {
    pub ptr: *mut u8,
    pub len: usize,
}

impl TssBuffer {
    fn empty() -> Self {
        Self {
            ptr: ptr::null_mut(),
            len: 0,
        }
    }

    fn from_bytes(bytes: Vec<u8>) -> Self {
        if bytes.is_empty() {
            return Self::empty();
        }
        let mut boxed = bytes.into_boxed_slice();
        let result = Self {
            ptr: boxed.as_mut_ptr(),
            len: boxed.len(),
        };
        std::mem::forget(boxed);
        result
    }

    fn from_string(value: impl Into<String>) -> Self {
        Self::from_bytes(value.into().into_bytes())
    }
}

#[repr(C)]
pub struct TssKeyEvent {
    pub key_code: u16,
    /// 0 = down, 1 = up.
    pub state: u8,
    pub is_repeat: u8,
}

#[repr(C)]
pub struct TssKeyDecision {
    /// 0 = pass, 1 = suppress.
    pub disposition: u8,
    /// 0 = none, 1 = completed, 2 = cancelled, 3 = invalid event.
    pub completion: u8,
    pub needs_context: u8,
    pub reserved: u8,
    pub pending_id: u64,
    /// Completed chord or cancellation/error detail.
    pub detail: TssBuffer,
}

impl TssKeyDecision {
    fn pass_error(message: impl Into<String>) -> Self {
        Self {
            disposition: 0,
            completion: 3,
            needs_context: 0,
            reserved: 0,
            pending_id: 0,
            detail: TssBuffer::from_string(message),
        }
    }
}

#[repr(C)]
pub struct TssTextContext {
    pub text_ptr: *const u8,
    pub text_len: usize,
    /// 0 = authoritative, 1 = tracked, 2 = unknown.
    pub confidence: u8,
    /// 0 = none, 1 = non-empty, 2 = unknown.
    pub selection: u8,
    pub was_truncated: u8,
    pub reserved: u8,
}

#[repr(C)]
pub struct TssResolveResult {
    /// 0 = matched, 1 = unmapped, 2 = context unavailable, 3 = context limit, 4 = expired.
    pub status: u8,
    pub delete_selection: u8,
    /// 0 = none, 1 = text, 2 = key.
    pub output_kind: u8,
    /// 0 = none, 1 = enter, 2 = tab, 3 = backspace, 4 = escape.
    pub basic_key: u8,
    pub delete_before: u32,
    pub text: TssBuffer,
    pub stroke: TssBuffer,
}

#[repr(C)]
pub struct TssOperationResult {
    pub ok: u8,
    pub reserved: [u8; 3],
    pub count: u32,
    /// A JSON-encoded structured error on failure.
    pub detail: TssBuffer,
}

impl TssOperationResult {
    fn success(count: usize) -> Self {
        Self {
            ok: 1,
            reserved: [0; 3],
            count: count.min(u32::MAX as usize) as u32,
            detail: TssBuffer::empty(),
        }
    }

    fn error_json(value: serde_json::Value) -> Self {
        Self {
            ok: 0,
            reserved: [0; 3],
            count: 0,
            detail: TssBuffer::from_string(value.to_string()),
        }
    }

    fn error_message(message: impl Into<String>) -> Self {
        Self::error_json(serde_json::json!({ "message": message.into() }))
    }
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct SourceEnvelope {
    id: String,
    name: String,
    json: String,
}

#[unsafe(no_mangle)]
pub extern "C" fn tss_engine_new() -> *mut TssEngine {
    Box::into_raw(Box::new(TssEngine {
        inner: Mutex::new(Engine::default()),
    }))
}

#[unsafe(no_mangle)]
/// # Safety
/// `engine` must be null or a live pointer returned by `tss_engine_new`, and it must be freed once.
pub unsafe extern "C" fn tss_engine_free(engine: *mut TssEngine) {
    if !engine.is_null() {
        // SAFETY: The caller promises this pointer came from tss_engine_new and is freed once.
        unsafe { drop(Box::from_raw(engine)) };
    }
}

#[unsafe(no_mangle)]
/// # Safety
/// `buffer` must be empty or an owned buffer returned by this library, and it must be freed once.
pub unsafe extern "C" fn tss_buffer_free(buffer: TssBuffer) {
    if !buffer.ptr.is_null() && buffer.len > 0 {
        let slice_ptr = ptr::slice_from_raw_parts_mut(buffer.ptr, buffer.len);
        // SAFETY: TssBuffer allocations are boxed slices created by TssBuffer::from_bytes.
        unsafe { drop(Box::from_raw(slice_ptr)) };
    }
}

#[unsafe(no_mangle)]
/// # Safety
/// `engine` must be a live pointer returned by `tss_engine_new`.
pub unsafe extern "C" fn tss_engine_process_key(
    engine: *mut TssEngine,
    event: TssKeyEvent,
) -> TssKeyDecision {
    let Some(engine) = (unsafe { engine.as_ref() }) else {
        return TssKeyDecision::pass_error("engine is null");
    };
    let Some(key) = PhysicalKey::from_hid_usage(event.key_code) else {
        return TssKeyDecision::pass_error(format!("unsupported HID key: {}", event.key_code));
    };
    let state = match event.state {
        0 => KeyState::Down,
        1 => KeyState::Up,
        other => return TssKeyDecision::pass_error(format!("invalid key state: {other}")),
    };
    let mut inner = engine
        .inner
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner());
    let result = inner.process_key(KeyEvent {
        key,
        state,
        is_repeat: event.is_repeat != 0,
    });
    let disposition = u8::from(result.disposition == EventDisposition::Suppress);
    if let Some(completed) = result.completed {
        return TssKeyDecision {
            disposition,
            completion: 1,
            needs_context: u8::from(completed.needs_context),
            reserved: 0,
            pending_id: completed.id,
            detail: TssBuffer::from_string(completed.stroke),
        };
    }
    if let Some(reason) = result.cancelled {
        return TssKeyDecision {
            disposition,
            completion: 2,
            needs_context: 0,
            reserved: 0,
            pending_id: 0,
            detail: TssBuffer::from_string(reason.message()),
        };
    }
    TssKeyDecision {
        disposition,
        completion: 0,
        needs_context: 0,
        reserved: 0,
        pending_id: 0,
        detail: TssBuffer::empty(),
    }
}

#[unsafe(no_mangle)]
/// # Safety
/// `engine` must be live. When non-null, `context` and its text buffer must remain readable
/// for the duration of the call.
pub unsafe extern "C" fn tss_engine_resolve(
    engine: *mut TssEngine,
    pending_id: u64,
    context: *const TssTextContext,
) -> TssResolveResult {
    let Some(engine) = (unsafe { engine.as_ref() }) else {
        return expired_resolve_result();
    };
    let owned_context = unsafe { context.as_ref() }.and_then(read_context);
    let mut inner = engine
        .inner
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner());
    let result = inner.resolve_pending(pending_id, owned_context.as_ref());

    let status = match (result.status, result.stroke.is_none()) {
        (_, true) => 4,
        (ResolveStatus::Matched, false) => 0,
        (ResolveStatus::Unmapped, false) => 1,
        (ResolveStatus::ContextUnavailable, false) => 2,
        (ResolveStatus::ContextLimitExceeded, false) => 3,
    };
    let stroke = result
        .stroke
        .map(TssBuffer::from_string)
        .unwrap_or_else(TssBuffer::empty);
    let Some(plan) = result.plan else {
        return TssResolveResult {
            status,
            delete_selection: 0,
            output_kind: 0,
            basic_key: 0,
            delete_before: 0,
            text: TssBuffer::empty(),
            stroke,
        };
    };
    let (output_kind, basic_key, text) = match plan.output {
        OutputAction::Text(text) => (1, 0, TssBuffer::from_string(text)),
        OutputAction::Key(key) => {
            let value = match key {
                tss_core::BasicKey::Enter => 1,
                tss_core::BasicKey::Tab => 2,
                tss_core::BasicKey::Backspace => 3,
                tss_core::BasicKey::Escape => 4,
            };
            (2, value, TssBuffer::empty())
        }
    };
    TssResolveResult {
        status,
        delete_selection: u8::from(plan.delete_selection),
        output_kind,
        basic_key,
        delete_before: plan.delete_before.min(u32::MAX as usize) as u32,
        text,
        stroke,
    }
}

#[unsafe(no_mangle)]
/// # Safety
/// `engine` must be live and `json_ptr` must address `json_len` readable bytes.
pub unsafe extern "C" fn tss_engine_replace_dictionaries(
    engine: *mut TssEngine,
    json_ptr: *const u8,
    json_len: usize,
) -> TssOperationResult {
    let Some(engine) = (unsafe { engine.as_ref() }) else {
        return TssOperationResult::error_message("engine is null");
    };
    let Some(bytes) = (unsafe { input_bytes(json_ptr, json_len) }) else {
        return TssOperationResult::error_message("dictionary input is null");
    };
    let envelopes: Vec<SourceEnvelope> = match serde_json::from_slice(bytes) {
        Ok(value) => value,
        Err(error) => {
            return TssOperationResult::error_message(format!(
                "invalid dictionary source envelope: {error}"
            ));
        }
    };
    let sources: Vec<_> = envelopes
        .into_iter()
        .map(|source| DictionarySource {
            id: source.id,
            name: source.name,
            json: source.json,
        })
        .collect();
    let snapshot = match DictionarySnapshot::build(&sources) {
        Ok(snapshot) => snapshot,
        Err(error) => {
            let detail = serde_json::to_value(error)
                .unwrap_or_else(|_| serde_json::json!({"message":"dictionary error"}));
            return TssOperationResult::error_json(detail);
        }
    };
    let count = snapshot.len();
    let mut inner = engine
        .inner
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner());
    inner.install_dictionary(snapshot);
    TssOperationResult::success(count)
}

#[unsafe(no_mangle)]
/// # Safety
/// `engine` must be live and `keys_ptr` must address `keys_len` readable `u16` values.
pub unsafe extern "C" fn tss_engine_set_captured_keys(
    engine: *mut TssEngine,
    keys_ptr: *const u16,
    keys_len: usize,
) -> TssOperationResult {
    let Some(engine) = (unsafe { engine.as_ref() }) else {
        return TssOperationResult::error_message("engine is null");
    };
    if keys_ptr.is_null() && keys_len > 0 {
        return TssOperationResult::error_message("captured key input is null");
    }
    let usages = if keys_len == 0 {
        &[][..]
    } else {
        // SAFETY: The caller supplies keys_len readable u16 values.
        unsafe { slice::from_raw_parts(keys_ptr, keys_len) }
    };
    let mut keys = HashSet::new();
    for usage in usages {
        let Some(key) = PhysicalKey::from_hid_usage(*usage) else {
            return TssOperationResult::error_message(format!(
                "unsupported captured HID key: {usage}"
            ));
        };
        keys.insert(key);
    }
    let count = keys.len();
    let mut inner = engine
        .inner
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner());
    inner.set_captured_keys(keys);
    TssOperationResult::success(count)
}

#[unsafe(no_mangle)]
/// # Safety
/// `engine` must be null or a live pointer returned by `tss_engine_new`.
pub unsafe extern "C" fn tss_engine_reset_input(engine: *mut TssEngine) {
    if let Some(engine) = unsafe { engine.as_ref() } {
        engine
            .inner
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner())
            .reset_input();
    }
}

#[unsafe(no_mangle)]
/// # Safety
/// `engine` must be null or a live pointer returned by `tss_engine_new`.
pub unsafe extern "C" fn tss_engine_interrupt(engine: *mut TssEngine) -> u8 {
    let Some(engine) = (unsafe { engine.as_ref() }) else {
        return 0;
    };
    u8::from(
        engine
            .inner
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner())
            .interrupt()
            .is_some(),
    )
}

fn read_context(context: &TssTextContext) -> Option<TextContext> {
    let confidence = match context.confidence {
        0 => ContextConfidence::Authoritative,
        1 => ContextConfidence::Tracked,
        _ => ContextConfidence::Unknown,
    };
    let selection = match context.selection {
        0 => SelectionState::None,
        1 => SelectionState::NonEmpty,
        _ => SelectionState::Unknown,
    };
    let bytes = unsafe { input_bytes(context.text_ptr, context.text_len) }?;
    Some(TextContext {
        preceding_text: String::from_utf8_lossy(bytes).into_owned(),
        confidence,
        selection,
        was_truncated: context.was_truncated != 0,
    })
}

unsafe fn input_bytes<'a>(pointer: *const u8, length: usize) -> Option<&'a [u8]> {
    if length == 0 {
        return Some(&[]);
    }
    if pointer.is_null() {
        return None;
    }
    // SAFETY: The caller promises the pointer is readable for length bytes during the call.
    Some(unsafe { slice::from_raw_parts(pointer, length) })
}

fn expired_resolve_result() -> TssResolveResult {
    TssResolveResult {
        status: 4,
        delete_selection: 0,
        output_kind: 0,
        basic_key: 0,
        delete_before: 0,
        text: TssBuffer::empty(),
        stroke: TssBuffer::empty(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ffi_round_trip_for_space_translation() {
        let engine = tss_engine_new();
        let sources = br#"[{"id":"main","name":"main.json","json":"{\"_\":\" \"}"}]"#;
        let loaded =
            unsafe { tss_engine_replace_dictionaries(engine, sources.as_ptr(), sources.len()) };
        assert_eq!(loaded.ok, 1);
        unsafe { tss_buffer_free(loaded.detail) };

        let down = unsafe {
            tss_engine_process_key(
                engine,
                TssKeyEvent {
                    key_code: PhysicalKey::Space as u16,
                    state: 0,
                    is_repeat: 0,
                },
            )
        };
        assert_eq!(down.disposition, 1);
        unsafe { tss_buffer_free(down.detail) };
        let up = unsafe {
            tss_engine_process_key(
                engine,
                TssKeyEvent {
                    key_code: PhysicalKey::Space as u16,
                    state: 1,
                    is_repeat: 0,
                },
            )
        };
        assert_eq!(up.completion, 1);
        unsafe { tss_buffer_free(up.detail) };

        let resolved = unsafe { tss_engine_resolve(engine, up.pending_id, ptr::null()) };
        assert_eq!(resolved.status, 0);
        assert_eq!(resolved.output_kind, 1);
        let text = unsafe { slice::from_raw_parts(resolved.text.ptr, resolved.text.len) };
        assert_eq!(text, b" ");
        unsafe {
            tss_buffer_free(resolved.text);
            tss_buffer_free(resolved.stroke);
            tss_engine_free(engine);
        }
    }
}
