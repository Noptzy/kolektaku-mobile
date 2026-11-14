use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct NextAiring {
    pub episode: u32,
    pub airing_at_secs: u64,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn survives_a_json_round_trip() {
        let airing = NextAiring {
            episode: 5,
            airing_at_secs: 1_700_000_000,
        };
        let json = serde_json::to_string(&airing).unwrap();
        assert_eq!(serde_json::from_str::<NextAiring>(&json).unwrap(), airing);
    }
}
