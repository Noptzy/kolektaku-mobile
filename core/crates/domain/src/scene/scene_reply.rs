use serde::{Deserialize, Serialize};

use super::SceneMatch;

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SceneReply {
    pub matches: Vec<SceneMatch>,
    pub quota_left: Option<u32>,
}

impl SceneReply {
    pub fn quota_from(total: Option<u64>, used: Option<u64>) -> Option<u32> {
        let left = total?.saturating_sub(used?);
        Some(u32::try_from(left).unwrap_or(u32::MAX))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn quota_left_is_total_minus_used() {
        assert_eq!(SceneReply::quota_from(Some(100), Some(7)), Some(93));
    }

    #[test]
    fn quota_never_goes_negative() {
        assert_eq!(SceneReply::quota_from(Some(100), Some(130)), Some(0));
    }

    #[test]
    fn unknown_numbers_give_no_quota() {
        assert_eq!(SceneReply::quota_from(None, Some(1)), None);
        assert_eq!(SceneReply::quota_from(Some(100), None), None);
    }
}
