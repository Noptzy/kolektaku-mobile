use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum SkipKind {
    Intro,
    Outro,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct SkipRange {
    pub kind: SkipKind,
    pub start_ms: u64,
    pub end_ms: u64,
}

impl SkipRange {
    pub fn from_seconds(kind: SkipKind, start: f64, end: f64) -> Option<Self> {
        let valid = start.is_finite() && end.is_finite() && start >= 0.0 && end > start;
        valid.then(|| Self {
            kind,
            start_ms: (start * 1000.0).round() as u64,
            end_ms: (end * 1000.0).round() as u64,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn seconds_become_milliseconds() {
        let range = SkipRange::from_seconds(SkipKind::Intro, 72.0, 158.4).unwrap();
        assert_eq!((range.start_ms, range.end_ms), (72_000, 158_400));
        assert_eq!(range.kind, SkipKind::Intro);
    }

    #[test]
    fn an_empty_backwards_negative_or_broken_range_is_refused() {
        assert_eq!(SkipRange::from_seconds(SkipKind::Outro, 10.0, 10.0), None);
        assert_eq!(SkipRange::from_seconds(SkipKind::Outro, 20.0, 10.0), None);
        assert_eq!(SkipRange::from_seconds(SkipKind::Outro, -1.0, 10.0), None);
        assert_eq!(
            SkipRange::from_seconds(SkipKind::Outro, f64::NAN, 10.0),
            None
        );
        assert_eq!(
            SkipRange::from_seconds(SkipKind::Outro, 0.0, f64::INFINITY),
            None
        );
    }

    #[test]
    fn a_range_may_start_at_zero() {
        assert!(SkipRange::from_seconds(SkipKind::Intro, 0.0, 5.0).is_some());
    }
}
