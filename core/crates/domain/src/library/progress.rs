use serde::{Deserialize, Serialize};

use crate::media::{MediaKind, MediaRef};

pub const COMPLETED_RATIO: f64 = 0.9;

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ProgressInput {
    pub media: MediaRef,
    pub kind: MediaKind,
    pub unit_number: f64,
    pub title: String,
    pub cover_url: Option<String>,
    pub position: f64,
    pub length: f64,
    pub updated_at_secs: u64,
}

impl ProgressInput {
    pub fn is_storable(&self) -> bool {
        self.position.is_finite() && self.position >= 0.0
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Progress {
    #[serde(flatten)]
    pub entry: ProgressInput,
    pub completed: bool,
}

impl Progress {
    pub fn from_input(entry: ProgressInput) -> Self {
        let completed = entry.length > 0.0 && entry.position / entry.length >= COMPLETED_RATIO;
        Self { entry, completed }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::media::MediaId;

    fn input(position: f64, length: f64) -> ProgressInput {
        ProgressInput {
            media: MediaRef::catalog(MediaId::new(1).unwrap()),
            kind: MediaKind::Anime,
            unit_number: 5.0,
            title: "Judul".into(),
            cover_url: None,
            position,
            length,
            updated_at_secs: 10,
        }
    }

    #[test]
    fn at_ninety_percent_the_unit_counts_as_finished() {
        assert!(Progress::from_input(input(90.0, 100.0)).completed);
        assert!(Progress::from_input(input(100.0, 100.0)).completed);
    }

    #[test]
    fn below_ninety_percent_it_is_not_finished() {
        assert!(!Progress::from_input(input(89.0, 100.0)).completed);
    }

    #[test]
    fn unknown_length_is_never_finished() {
        assert!(!Progress::from_input(input(500.0, 0.0)).completed);
    }

    #[test]
    fn negative_or_non_finite_positions_are_not_storable() {
        assert!(input(0.0, 10.0).is_storable());
        assert!(!input(-1.0, 10.0).is_storable());
        assert!(!input(f64::NAN, 10.0).is_storable());
        assert!(!input(f64::INFINITY, 10.0).is_storable());
    }

    #[test]
    fn json_is_flat_and_round_trips() {
        let progress = Progress::from_input(input(30.0, 100.0));
        let json = serde_json::to_string(&progress).unwrap();
        assert_eq!(serde_json::from_str::<Progress>(&json).unwrap(), progress);
    }
}
