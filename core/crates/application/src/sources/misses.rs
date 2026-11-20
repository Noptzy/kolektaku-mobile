use std::collections::HashMap;
use std::sync::Mutex;

use domain::media::MediaRef;
use domain::source::SourceId;

pub const FORGET_MISS_AFTER_SECS: u64 = 12 * 60 * 60;

#[derive(Default)]
pub struct SearchMisses {
    seen: Mutex<HashMap<(MediaRef, SourceId), u64>>,
}

impl SearchMisses {
    pub fn record(&self, media: &MediaRef, source: &SourceId, now_secs: u64) {
        self.seen
            .lock()
            .unwrap()
            .insert((media.clone(), source.clone()), now_secs);
    }

    pub fn is_recent(&self, media: &MediaRef, source: &SourceId, now_secs: u64) -> bool {
        self.seen
            .lock()
            .unwrap()
            .get(&(media.clone(), source.clone()))
            .is_some_and(|at| now_secs.saturating_sub(*at) < FORGET_MISS_AFTER_SECS)
    }
}

#[cfg(test)]
mod tests {
    use domain::media::MediaId;

    use super::*;

    fn media(id: u64) -> MediaRef {
        MediaRef::catalog(MediaId::new(id).unwrap())
    }

    #[test]
    fn a_miss_is_remembered_for_that_title_and_site_only() {
        let misses = SearchMisses::default();
        let site = SourceId::new("a");
        misses.record(&media(1), &site, 100);
        assert!(misses.is_recent(&media(1), &site, 100));
        assert!(!misses.is_recent(&media(2), &site, 100));
        assert!(!misses.is_recent(&media(1), &SourceId::new("b"), 100));
    }

    #[test]
    fn a_miss_is_forgotten_after_half_a_day() {
        let misses = SearchMisses::default();
        let site = SourceId::new("a");
        misses.record(&media(1), &site, 100);
        assert!(misses.is_recent(&media(1), &site, 100 + FORGET_MISS_AFTER_SECS - 1));
        assert!(!misses.is_recent(&media(1), &site, 100 + FORGET_MISS_AFTER_SECS));
    }
}
