use serde::{Deserialize, Serialize};

use super::MediaId;
use crate::source::{ItemId, SourceId};

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum MediaRef {
    Catalog { id: MediaId },
    Source { source: SourceId, item: ItemId },
}

impl MediaRef {
    pub fn catalog(id: MediaId) -> Self {
        Self::Catalog { id }
    }

    pub fn source(source: SourceId, item: ItemId) -> Self {
        Self::Source { source, item }
    }

    pub fn catalog_id(&self) -> Option<MediaId> {
        match self {
            Self::Catalog { id } => Some(*id),
            Self::Source { .. } => None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn catalog_ref_exposes_its_id() {
        let id = MediaId::new(21519).unwrap();
        assert_eq!(MediaRef::catalog(id).catalog_id(), Some(id));
    }

    #[test]
    fn source_ref_has_no_catalog_id() {
        let reference =
            MediaRef::source(SourceId::new("kuramanime"), ItemId::new("5244/fx-senshi"));
        assert_eq!(reference.catalog_id(), None);
    }

    #[test]
    fn both_variants_survive_a_json_round_trip() {
        let refs = [
            MediaRef::catalog(MediaId::new(1).unwrap()),
            MediaRef::source(SourceId::new("komiku"), ItemId::new("one-piece")),
        ];
        for reference in refs {
            let json = serde_json::to_string(&reference).unwrap();
            assert_eq!(serde_json::from_str::<MediaRef>(&json).unwrap(), reference);
        }
    }

    #[test]
    fn json_is_tagged_by_type() {
        let json = serde_json::to_string(&MediaRef::catalog(MediaId::new(5).unwrap())).unwrap();
        assert_eq!(json, r#"{"type":"catalog","id":5}"#);
    }
}
