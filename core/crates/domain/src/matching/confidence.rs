use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, PartialOrd, Serialize, Deserialize)]
#[serde(transparent)]
pub struct Confidence(f32);

impl Confidence {
    pub const AUTO_THRESHOLD: f32 = 0.85;
    pub const LIST_CAP: f32 = 0.84;

    pub fn new(value: f32) -> Self {
        if value.is_nan() {
            return Self(0.0);
        }
        Self(value.clamp(0.0, 1.0))
    }

    pub fn get(self) -> f32 {
        self.0
    }

    pub fn is_automatic(self) -> bool {
        self.0 >= Self::AUTO_THRESHOLD
    }

    pub fn capped_for_list(self) -> Self {
        Self(self.0.min(Self::LIST_CAP))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn values_are_clamped_to_the_unit_range() {
        assert_eq!(Confidence::new(1.7).get(), 1.0);
        assert_eq!(Confidence::new(-0.2).get(), 0.0);
        assert_eq!(Confidence::new(f32::NAN).get(), 0.0);
    }

    #[test]
    fn automatic_starts_at_the_threshold() {
        assert!(Confidence::new(0.85).is_automatic());
        assert!(!Confidence::new(0.84).is_automatic());
    }

    #[test]
    fn list_cap_keeps_a_link_below_the_automatic_threshold() {
        let capped = Confidence::new(1.0).capped_for_list();
        assert_eq!(capped.get(), Confidence::LIST_CAP);
        assert!(!capped.is_automatic());
        assert_eq!(Confidence::new(0.5).capped_for_list().get(), 0.5);
    }
}
