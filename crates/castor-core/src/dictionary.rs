use std::collections::HashMap;
use std::fmt;

use serde::de::{self, MapAccess, Visitor};
use serde::{Deserialize, Deserializer, Serialize};

use crate::normalize_stroke;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum BasicKey {
    Enter,
    Tab,
    Backspace,
    Escape,
}

#[derive(Debug, Clone, PartialEq, Eq, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct KeyTranslation {
    pub key: BasicKey,
}

#[derive(Debug, Clone, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct EditTranslation {
    pub text: String,
    #[serde(default)]
    pub delete_before: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct HangulBatchim(u8);

impl HangulBatchim {
    pub fn index(self) -> u8 {
        self.0
    }

    pub fn character(self) -> char {
        "ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ"
            .chars()
            .nth(usize::from(self.0 - 1))
            .expect("validated Hangul batchim index")
    }
}

impl<'de> Deserialize<'de> for HangulBatchim {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        let value = String::deserialize(deserializer)?;
        let mut characters = value.chars();
        let Some(character) = characters.next() else {
            return Err(de::Error::custom("replaceBatchim must not be empty"));
        };
        if characters.next().is_some() {
            return Err(de::Error::custom(
                "replaceBatchim must be one Hangul batchim character",
            ));
        }
        let index = "ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ"
            .chars()
            .position(|candidate| candidate == character)
            .map(|position| position as u8 + 1)
            .ok_or_else(|| {
                de::Error::custom(format!(
                    "replaceBatchim must be a valid Hangul batchim, got {value:?}"
                ))
            })?;
        Ok(Self(index))
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct BatchimReplacementTranslation {
    pub replace_batchim: HangulBatchim,
    pub text: String,
    #[serde(default)]
    pub delete_before: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum Condition {
    PreviousHangulBatchim,
}

#[derive(Debug, Clone, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ConditionalTranslation {
    pub condition: Condition,
    pub batchim: EditTranslation,
    pub no_batchim: EditTranslation,
}

#[derive(Debug, Clone, PartialEq, Eq, Deserialize)]
#[serde(untagged)]
pub enum Translation {
    Text(String),
    Key(KeyTranslation),
    BatchimReplacement(BatchimReplacementTranslation),
    Edit(EditTranslation),
    Conditional(ConditionalTranslation),
}

impl Translation {
    pub fn needs_context(&self) -> bool {
        match self {
            Self::Text(_) | Self::Key(_) => false,
            Self::Edit(edit) => edit.delete_before,
            Self::BatchimReplacement(_) | Self::Conditional(_) => true,
        }
    }
}

#[derive(Debug, Clone)]
pub struct DictionarySource {
    pub id: String,
    pub name: String,
    pub json: String,
}

#[derive(Debug, Clone)]
pub struct DictionaryEntry {
    pub translation: Translation,
    pub source_id: String,
    pub source_name: String,
    pub original_stroke: String,
}

#[derive(Debug, Clone, Default)]
pub struct DictionarySnapshot {
    entries: HashMap<String, DictionaryEntry>,
}

impl DictionarySnapshot {
    pub fn build(sources: &[DictionarySource]) -> Result<Self, DictionaryError> {
        let mut entries: HashMap<String, DictionaryEntry> = HashMap::new();
        for source in sources {
            let raw: RawDictionary =
                serde_json::from_str(&source.json).map_err(|error| DictionaryError {
                    source_id: Some(source.id.clone()),
                    chord: None,
                    message: format!("{}: invalid JSON: {error}", source.name),
                })?;

            for (original_stroke, translation) in raw.0 {
                let normalized =
                    normalize_stroke(&original_stroke).map_err(|error| DictionaryError {
                        source_id: Some(source.id.clone()),
                        chord: Some(original_stroke.clone()),
                        message: format!("{}: {error}", source.name),
                    })?;
                if let Some(existing) = entries.get(&normalized) {
                    return Err(DictionaryError {
                        source_id: Some(source.id.clone()),
                        chord: Some(normalized.clone()),
                        message: format!(
                            "chord {normalized:?} conflicts between {} ({:?}) and {} ({:?})",
                            existing.source_name,
                            existing.original_stroke,
                            source.name,
                            original_stroke
                        ),
                    });
                }
                entries.insert(
                    normalized,
                    DictionaryEntry {
                        translation,
                        source_id: source.id.clone(),
                        source_name: source.name.clone(),
                        original_stroke,
                    },
                );
            }
        }
        Ok(Self { entries })
    }

    pub fn get(&self, stroke: &str) -> Option<&DictionaryEntry> {
        self.entries.get(stroke)
    }

    pub fn len(&self) -> usize {
        self.entries.len()
    }

    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DictionaryError {
    pub source_id: Option<String>,
    pub chord: Option<String>,
    pub message: String,
}

impl fmt::Display for DictionaryError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(&self.message)
    }
}

impl std::error::Error for DictionaryError {}

struct RawDictionary(Vec<(String, Translation)>);

impl<'de> Deserialize<'de> for RawDictionary {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct RawDictionaryVisitor;

        impl<'de> Visitor<'de> for RawDictionaryVisitor {
            type Value = RawDictionary;

            fn expecting(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
                formatter.write_str("a JSON object mapping strokes to translations")
            }

            fn visit_map<A>(self, mut map: A) -> Result<Self::Value, A::Error>
            where
                A: MapAccess<'de>,
            {
                let mut entries = Vec::new();
                while let Some(entry) = map.next_entry::<String, Translation>()? {
                    entries.push(entry);
                }
                if entries.is_empty() {
                    return Err(de::Error::custom(
                        "dictionary must contain at least one entry",
                    ));
                }
                Ok(RawDictionary(entries))
            }
        }

        deserializer.deserialize_map(RawDictionaryVisitor)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn source(id: &str, json: &str) -> DictionarySource {
        DictionarySource {
            id: id.into(),
            name: format!("{id}.json"),
            json: json.into(),
        }
    }

    #[test]
    fn parses_every_translation_shape() {
        let snapshot = DictionarySnapshot::build(&[source(
            "main",
            r#"{
                "_": " ",
                "DF": {"key":"enter"},
                "AB": {"text":"입니다","deleteBefore":true},
                "CD": {
                    "condition":"previousHangulBatchim",
                    "batchim":{"text":"은","deleteBefore":true},
                    "noBatchim":{"text":"는","deleteBefore":true}
                },
                "EF": {
                    "replaceBatchim":"ㅂ",
                    "text":"니다",
                    "deleteBefore":true
                }
            }"#,
        )])
        .unwrap();
        assert_eq!(snapshot.len(), 5);
        assert!(matches!(
            snapshot.get("_").unwrap().translation,
            Translation::Text(_)
        ));
        assert!(matches!(
            snapshot.get("DF").unwrap().translation,
            Translation::Key(_)
        ));
        assert!(matches!(
            snapshot.get("AB").unwrap().translation,
            Translation::Edit(_)
        ));
        assert!(matches!(
            snapshot.get("DC").unwrap().translation,
            Translation::Conditional(_)
        ));
        assert!(matches!(
            snapshot.get("EF").unwrap().translation,
            Translation::BatchimReplacement(_)
        ));
    }

    #[test]
    fn rejects_old_context_syntax_and_invalid_batchim() {
        assert!(
            DictionarySnapshot::build(&[source(
                "old-delete",
                r#"{"R":{"text":"은","deleteBefore":"horizontalWhitespace"}}"#,
            )])
            .is_err()
        );
        assert!(DictionarySnapshot::build(&[source(
            "old-condition",
            r#"{"R":{"condition":"previousHangulFinal","final":{"text":"은"},"noFinal":{"text":"는"}}}"#,
        )])
        .is_err());
        assert!(
            DictionarySnapshot::build(&[source(
                "invalid-batchim",
                r#"{"R":{"replaceBatchim":"ㅏ","text":"니다"}}"#,
            )])
            .is_err()
        );
    }

    #[test]
    fn rejects_normalized_collision_in_one_file() {
        let error =
            DictionarySnapshot::build(&[source("main", r#"{"RK":"가","KR":"나"}"#)]).unwrap_err();
        assert_eq!(error.chord.as_deref(), Some("RK"));
    }

    #[test]
    fn rejects_collision_across_files() {
        let error = DictionarySnapshot::build(&[
            source("a", r#"{"RK":"가"}"#),
            source("b", r#"{"KR":"나"}"#),
        ])
        .unwrap_err();
        assert_eq!(error.source_id.as_deref(), Some("b"));
    }

    #[test]
    fn rejects_exact_duplicate_json_keys() {
        let error =
            DictionarySnapshot::build(&[source("main", r#"{"RK":"가","RK":"나"}"#)]).unwrap_err();
        assert_eq!(error.chord.as_deref(), Some("RK"));
    }

    #[test]
    fn bundled_default_dictionary_is_valid() {
        let snapshot = DictionarySnapshot::build(&[DictionarySource {
            id: "default".into(),
            name: "default.json".into(),
            json: include_str!("../../../examples/main.json").into(),
        }])
        .unwrap();

        assert!(!snapshot.is_empty());
    }

    #[test]
    fn bundled_hangul_dictionary_is_valid_after_normalization() {
        let snapshot = DictionarySnapshot::build(&[DictionarySource {
            id: "default-hangul".into(),
            name: "default_hangul.json".into(),
            json: include_str!("../../../examples/main_hangul.json").into(),
        }])
        .unwrap();

        // 11,172 modern Hangul syllables, each with the base, trailing space,
        // period, comma, period+space, and comma+space variants.
        assert_eq!(snapshot.len(), 67_032);
        assert!(matches!(
            &snapshot.get("RK;").unwrap().translation,
            Translation::Text(text) if text == "각"
        ));
    }
}
