use serde::{Deserialize, Serialize};
use unicode_normalization::UnicodeNormalization;
use unicode_segmentation::UnicodeSegmentation;

pub use crate::dictionary::BasicKey;
use crate::dictionary::{
    BatchimReplacementTranslation, ConditionalTranslation, EditTranslation, Translation,
};

pub const MAX_CONTEXT_GRAPHEMES: usize = 256;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum ContextConfidence {
    Authoritative,
    Tracked,
    Unknown,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum SelectionState {
    None,
    NonEmpty,
    Unknown,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TextContext {
    /// Text immediately preceding the caret, or the start of the selection.
    pub preceding_text: String,
    pub confidence: ContextConfidence,
    pub selection: SelectionState,
    /// True when more text exists before `preceding_text`.
    pub was_truncated: bool,
}

impl TextContext {
    pub fn unavailable() -> Self {
        Self {
            preceding_text: String::new(),
            confidence: ContextConfidence::Unknown,
            selection: SelectionState::Unknown,
            was_truncated: false,
        }
    }

    fn is_usable(&self) -> bool {
        self.confidence != ContextConfidence::Unknown && self.selection != SelectionState::Unknown
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum OutputAction {
    Text(String),
    Key(BasicKey),
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct EditPlan {
    pub delete_selection: bool,
    pub delete_before: usize,
    pub output: OutputAction,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum ResolveStatus {
    Matched,
    Unmapped,
    ContextUnavailable,
    ContextLimitExceeded,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct TranslationResolution {
    pub status: ResolveStatus,
    pub plan: Option<EditPlan>,
}

pub(crate) fn resolve_translation(
    translation: Option<&Translation>,
    context: Option<&TextContext>,
) -> TranslationResolution {
    let Some(translation) = translation else {
        return TranslationResolution {
            status: ResolveStatus::Unmapped,
            plan: None,
        };
    };

    match translation {
        Translation::Text(text) => TranslationResolution {
            status: ResolveStatus::Matched,
            plan: Some(text_plan(text.clone())),
        },
        Translation::Key(key) => TranslationResolution {
            status: ResolveStatus::Matched,
            plan: Some(EditPlan {
                delete_selection: false,
                delete_before: 0,
                output: OutputAction::Key(key.key),
            }),
        },
        Translation::Edit(edit) => resolve_edit(edit, context),
        Translation::BatchimReplacement(replacement) => {
            resolve_batchim_replacement(replacement, context)
        }
        Translation::Conditional(conditional) => resolve_conditional(conditional, context),
    }
}

fn resolve_edit(edit: &EditTranslation, context: Option<&TextContext>) -> TranslationResolution {
    if !edit.delete_before {
        return matched_text(edit.text.clone());
    }
    let Some(context) = context.filter(|context| context.is_usable()) else {
        return matched_text(edit.text.clone());
    };
    match inspect_context(context) {
        ContextInspection::Usable { whitespace, .. } => TranslationResolution {
            status: ResolveStatus::Matched,
            plan: Some(EditPlan {
                delete_selection: context.selection == SelectionState::NonEmpty,
                delete_before: whitespace,
                output: OutputAction::Text(edit.text.clone()),
            }),
        },
        ContextInspection::LimitExceeded => matched_text(edit.text.clone()),
    }
}

fn resolve_batchim_replacement(
    replacement: &BatchimReplacementTranslation,
    context: Option<&TextContext>,
) -> TranslationResolution {
    let fallback = || {
        matched_text(format!(
            "{}{}",
            replacement.replace_batchim.character(),
            replacement.text
        ))
    };
    let Some(context) = context.filter(|context| context.is_usable()) else {
        return fallback();
    };
    let ContextInspection::Usable {
        whitespace, target, ..
    } = inspect_context(context)
    else {
        return fallback();
    };
    if whitespace > 0 && !replacement.delete_before {
        return fallback();
    }
    let Some(replaced) = target.and_then(|character| {
        replace_hangul_batchim(character, replacement.replace_batchim.index())
    }) else {
        return fallback();
    };

    TranslationResolution {
        status: ResolveStatus::Matched,
        plan: Some(EditPlan {
            delete_selection: context.selection == SelectionState::NonEmpty,
            delete_before: whitespace + 1,
            output: OutputAction::Text(format!("{replaced}{}", replacement.text)),
        }),
    }
}

fn resolve_conditional(
    conditional: &ConditionalTranslation,
    context: Option<&TextContext>,
) -> TranslationResolution {
    let Some(context) = context.filter(|context| context.is_usable()) else {
        return matched_text(conditional.no_batchim.text.clone());
    };
    let ContextInspection::Usable {
        whitespace,
        has_batchim,
        ..
    } = inspect_context(context)
    else {
        return matched_text(conditional.no_batchim.text.clone());
    };
    let branch = if has_batchim {
        &conditional.batchim
    } else {
        &conditional.no_batchim
    };
    let delete_before = if branch.delete_before { whitespace } else { 0 };
    TranslationResolution {
        status: ResolveStatus::Matched,
        plan: Some(EditPlan {
            delete_selection: context.selection == SelectionState::NonEmpty,
            delete_before,
            output: OutputAction::Text(branch.text.clone()),
        }),
    }
}

fn matched_text(text: String) -> TranslationResolution {
    TranslationResolution {
        status: ResolveStatus::Matched,
        plan: Some(text_plan(text)),
    }
}

fn text_plan(text: String) -> EditPlan {
    EditPlan {
        delete_selection: false,
        delete_before: 0,
        output: OutputAction::Text(text),
    }
}

enum ContextInspection {
    Usable {
        whitespace: usize,
        target: Option<char>,
        has_batchim: bool,
    },
    LimitExceeded,
}

fn inspect_context(context: &TextContext) -> ContextInspection {
    let graphemes: Vec<&str> = context
        .preceding_text
        .graphemes(true)
        .rev()
        .take(MAX_CONTEXT_GRAPHEMES + 1)
        .collect();
    if graphemes.len() > MAX_CONTEXT_GRAPHEMES {
        return ContextInspection::LimitExceeded;
    }

    let whitespace = graphemes
        .iter()
        .take_while(|grapheme| matches!(**grapheme, " " | "\t"))
        .count();
    if whitespace == graphemes.len() {
        if context.was_truncated {
            return ContextInspection::LimitExceeded;
        }
        return ContextInspection::Usable {
            whitespace,
            target: None,
            has_batchim: false,
        };
    }

    let target = graphemes[whitespace].nfc().collect::<String>();
    let target = target.chars().last();
    let has_batchim = target.map(hangul_syllable_has_batchim).unwrap_or(false);
    ContextInspection::Usable {
        whitespace,
        target,
        has_batchim,
    }
}

fn hangul_syllable_has_batchim(character: char) -> bool {
    let value = character as u32;
    (0xAC00..=0xD7A3).contains(&value) && (value - 0xAC00) % 28 != 0
}

fn replace_hangul_batchim(character: char, batchim_index: u8) -> Option<char> {
    let value = character as u32;
    if !(0xAC00..=0xD7A3).contains(&value) || !(1..=27).contains(&batchim_index) {
        return None;
    }
    let syllable_without_batchim = value - (value - 0xAC00) % 28;
    char::from_u32(syllable_without_batchim + u32::from(batchim_index))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::dictionary::{Condition, ConditionalTranslation, EditTranslation};

    fn context(text: &str) -> TextContext {
        TextContext {
            preceding_text: text.into(),
            confidence: ContextConfidence::Authoritative,
            selection: SelectionState::None,
            was_truncated: false,
        }
    }

    fn particle() -> Translation {
        Translation::Conditional(ConditionalTranslation {
            condition: Condition::PreviousHangulBatchim,
            batchim: EditTranslation {
                text: "은".into(),
                delete_before: true,
            },
            no_batchim: EditTranslation {
                text: "는".into(),
                delete_before: true,
            },
        })
    }

    fn replacement(batchim: &str, text: &str, delete_before: bool) -> Translation {
        serde_json::from_value(serde_json::json!({
            "replaceBatchim": batchim,
            "text": text,
            "deleteBefore": delete_before
        }))
        .unwrap()
    }

    fn text_from(resolution: TranslationResolution) -> String {
        match resolution.plan.unwrap().output {
            OutputAction::Text(text) => text,
            OutputAction::Key(_) => panic!("expected text"),
        }
    }

    #[test]
    fn selects_batchim_and_no_batchim_particles() {
        assert_eq!(
            text_from(resolve_translation(
                Some(&particle()),
                Some(&context("사람"))
            )),
            "은"
        );
        assert_eq!(
            text_from(resolve_translation(
                Some(&particle()),
                Some(&context("학교"))
            )),
            "는"
        );
    }

    #[test]
    fn handles_nfd_hangul() {
        let decomposed = "각".nfd().collect::<String>();
        assert_eq!(
            text_from(resolve_translation(
                Some(&particle()),
                Some(&context(&decomposed))
            )),
            "은"
        );
    }

    #[test]
    fn skips_and_deletes_horizontal_whitespace_only() {
        let resolution = resolve_translation(Some(&particle()), Some(&context("사람 \t  ")));
        assert_eq!(resolution.plan.unwrap().delete_before, 4);

        assert_eq!(
            text_from(resolve_translation(
                Some(&particle()),
                Some(&context("사람\n"))
            )),
            "는"
        );
    }

    #[test]
    fn treats_non_hangul_and_document_start_as_no_batchim() {
        assert_eq!(
            text_from(resolve_translation(Some(&particle()), Some(&context("A")))),
            "는"
        );
        assert_eq!(
            text_from(resolve_translation(Some(&particle()), Some(&context("")))),
            "는"
        );
    }

    #[test]
    fn deletes_selection_before_editing() {
        let mut selected = context("사람 ");
        selected.selection = SelectionState::NonEmpty;
        let resolution = resolve_translation(Some(&particle()), Some(&selected));
        let plan = resolution.plan.unwrap();
        assert!(plan.delete_selection);
        assert_eq!(plan.delete_before, 1);
    }

    #[test]
    fn adds_or_replaces_previous_hangul_batchim() {
        let add = resolve_translation(
            Some(&replacement("ㅂ", "니다", false)),
            Some(&context("가")),
        );
        let add_plan = add.plan.unwrap();
        assert_eq!(add_plan.delete_before, 1);
        assert_eq!(add_plan.output, OutputAction::Text("갑니다".into()));

        let replace = resolve_translation(
            Some(&replacement("ㄹ", " 수 ", false)),
            Some(&context("간")),
        );
        let replace_plan = replace.plan.unwrap();
        assert_eq!(replace_plan.delete_before, 1);
        assert_eq!(replace_plan.output, OutputAction::Text("갈 수 ".into()));
    }

    #[test]
    fn batchim_replacement_can_delete_whitespace_and_selection() {
        let mut selected = context("가 \t");
        selected.selection = SelectionState::NonEmpty;
        let resolution =
            resolve_translation(Some(&replacement("ㄹ", " 수 ", true)), Some(&selected));
        let plan = resolution.plan.unwrap();
        assert!(plan.delete_selection);
        assert_eq!(plan.delete_before, 3);
        assert_eq!(plan.output, OutputAction::Text("갈 수 ".into()));
    }

    #[test]
    fn batchim_replacement_falls_back_to_literal_text_when_it_cannot_edit() {
        assert_eq!(
            text_from(resolve_translation(
                Some(&replacement("ㅂ", "니다", false)),
                Some(&context("가 ")),
            )),
            "ㅂ니다"
        );
        assert_eq!(
            text_from(resolve_translation(
                Some(&replacement("ㅂ", "니다", true)),
                Some(&context("A")),
            )),
            "ㅂ니다"
        );
    }

    #[test]
    fn contextual_translations_use_defaults_for_unknown_and_overlong_context() {
        let unknown = TextContext::unavailable();
        assert_eq!(
            text_from(resolve_translation(Some(&particle()), Some(&unknown))),
            "는"
        );
        assert_eq!(
            text_from(resolve_translation(
                Some(&replacement("ㅂ", "니다", false)),
                None,
            )),
            "ㅂ니다"
        );

        let too_long = context(&" ".repeat(MAX_CONTEXT_GRAPHEMES));
        let truncated = TextContext {
            was_truncated: true,
            ..too_long
        };
        assert_eq!(
            text_from(resolve_translation(Some(&particle()), Some(&truncated))),
            "는"
        );
        assert_eq!(
            text_from(resolve_translation(
                Some(&Translation::Edit(EditTranslation {
                    text: "입니다".into(),
                    delete_before: true,
                })),
                Some(&unknown),
            )),
            "입니다"
        );
    }
}
