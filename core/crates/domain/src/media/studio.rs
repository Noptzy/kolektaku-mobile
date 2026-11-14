use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct StudioRef {
    pub id: Option<u64>,
    pub name: String,
}

impl StudioRef {
    pub fn named(name: impl Into<String>) -> Self {
        Self {
            id: None,
            name: name.into(),
        }
    }

    pub fn identified(id: u64, name: impl Into<String>) -> Self {
        Self {
            id: Some(id),
            name: name.into(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_studio_may_or_may_not_know_its_catalog_id() {
        assert_eq!(StudioRef::named("Bones").id, None);
        assert_eq!(StudioRef::identified(4, "Bones").id, Some(4));
    }

    #[test]
    fn it_survives_json() {
        let studio = StudioRef::identified(43, "ufotable");
        let json = serde_json::to_string(&studio).unwrap();
        assert_eq!(serde_json::from_str::<StudioRef>(&json).unwrap(), studio);
    }
}
