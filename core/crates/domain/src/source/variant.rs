use serde::{Deserialize, Serialize};

use super::ItemId;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct LinkVariant {
    pub item: ItemId,
    pub audio: String,
}

impl LinkVariant {
    pub fn new(item: ItemId, audio: impl Into<String>) -> Self {
        Self {
            item,
            audio: audio.into(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn keeps_the_item_and_the_audio_label() {
        let variant = LinkVariant::new(ItemId::new("2120/x-dub-id"), "Dub Indonesia");
        assert_eq!(variant.item, ItemId::new("2120/x-dub-id"));
        assert_eq!(variant.audio, "Dub Indonesia");
    }

    #[test]
    fn survives_a_json_round_trip() {
        let variant = LinkVariant::new(ItemId::new("a"), "Dub");
        let json = serde_json::to_string(&variant).unwrap();
        assert_eq!(serde_json::from_str::<LinkVariant>(&json).unwrap(), variant);
    }
}
