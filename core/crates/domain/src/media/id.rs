use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(try_from = "u64", into = "u64")]
pub struct MediaId(u64);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Error)]
#[error("invalid media id: {0}")]
pub struct InvalidMediaId(pub u64);

impl MediaId {
    pub fn new(value: u64) -> Option<Self> {
        (value > 0).then_some(Self(value))
    }

    pub fn get(self) -> u64 {
        self.0
    }
}

impl TryFrom<u64> for MediaId {
    type Error = InvalidMediaId;

    fn try_from(value: u64) -> Result<Self, Self::Error> {
        Self::new(value).ok_or(InvalidMediaId(value))
    }
}

impl From<MediaId> for u64 {
    fn from(id: MediaId) -> Self {
        id.0
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn zero_is_rejected() {
        assert_eq!(MediaId::new(0), None);
        assert_eq!(MediaId::try_from(0), Err(InvalidMediaId(0)));
    }

    #[test]
    fn positive_value_round_trips() {
        let id = MediaId::new(21519).unwrap();
        assert_eq!(id.get(), 21519);
        assert_eq!(serde_json::to_string(&id).unwrap(), "21519");
        assert_eq!(serde_json::from_str::<MediaId>("21519").unwrap(), id);
    }

    #[test]
    fn json_zero_is_rejected_on_deserialize() {
        assert!(serde_json::from_str::<MediaId>("0").is_err());
    }
}
