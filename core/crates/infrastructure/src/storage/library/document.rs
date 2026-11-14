use std::collections::BTreeMap;

use domain::library::{Favorite, Progress, UnitOrder};
use domain::media::{MediaKind, MediaRef};
use serde::de::DeserializeOwned;
use serde::{Deserialize, Deserializer, Serialize};
use serde_json::Value;

pub const FORMAT_VERSION: u32 = 1;

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct UnitOrderEntry {
    pub kind: MediaKind,
    pub media: MediaRef,
    pub order: UnitOrder,
}

#[derive(Debug, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct LibraryDocument {
    pub version: u32,
    #[serde(deserialize_with = "lenient_list")]
    pub favorites: Vec<Favorite>,
    #[serde(deserialize_with = "lenient_list")]
    pub history: Vec<Progress>,
    #[serde(deserialize_with = "lenient_list")]
    pub unit_orders: Vec<UnitOrderEntry>,
    #[serde(deserialize_with = "lenient_map")]
    pub searches: BTreeMap<String, Vec<String>>,
    #[serde(deserialize_with = "lenient_map")]
    pub preferences: BTreeMap<String, String>,
}

fn lenient_list<'de, D, T>(deserializer: D) -> Result<Vec<T>, D::Error>
where
    D: Deserializer<'de>,
    T: DeserializeOwned,
{
    let value = Value::deserialize(deserializer)?;
    let entries = match value {
        Value::Array(entries) => entries,
        _ => Vec::new(),
    };
    Ok(entries
        .into_iter()
        .filter_map(|entry| serde_json::from_value(entry).ok())
        .collect())
}

fn lenient_map<'de, D, T>(deserializer: D) -> Result<BTreeMap<String, T>, D::Error>
where
    D: Deserializer<'de>,
    T: DeserializeOwned,
{
    let value = Value::deserialize(deserializer)?;
    let entries = match value {
        Value::Object(entries) => entries,
        _ => serde_json::Map::new(),
    };
    Ok(entries
        .into_iter()
        .filter_map(|(key, entry)| Some((key, serde_json::from_value(entry).ok()?)))
        .collect())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn missing_sections_default_to_empty() {
        let document: LibraryDocument = serde_json::from_str("{}").unwrap();
        assert!(document.favorites.is_empty() && document.history.is_empty());
        assert!(document.searches.is_empty() && document.preferences.is_empty());
    }

    #[test]
    fn a_bad_entry_is_skipped_without_hurting_its_neighbours() {
        let text = r#"{"history":[{"nonsense":true}],"preferences":{"a":"1","b":2},"searches":{"anime":["x"],"manga":5}}"#;
        let document: LibraryDocument = serde_json::from_str(text).unwrap();
        assert!(document.history.is_empty());
        assert_eq!(document.preferences.len(), 1);
        assert_eq!(document.searches.len(), 1);
    }

    #[test]
    fn sections_of_the_wrong_shape_become_empty() {
        let document: LibraryDocument =
            serde_json::from_str(r#"{"favorites":5,"preferences":[1]}"#).unwrap();
        assert!(document.favorites.is_empty() && document.preferences.is_empty());
    }
}
