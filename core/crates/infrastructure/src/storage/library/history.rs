use domain::library::{Progress, ProgressInput};
use domain::media::{MediaKind, MediaRef};

use super::document::LibraryDocument;

const SAME_UNIT_TOLERANCE: f64 = 1e-9;

fn same_unit(left: f64, right: f64) -> bool {
    (left - right).abs() < SAME_UNIT_TOLERANCE
}

fn is_entry(progress: &Progress, kind: MediaKind, media: &MediaRef, unit_number: f64) -> bool {
    progress.entry.kind == kind
        && progress.entry.media == *media
        && same_unit(progress.entry.unit_number, unit_number)
}

impl LibraryDocument {
    pub fn history_of(&self, kind: MediaKind) -> Vec<Progress> {
        let mut entries: Vec<Progress> = self
            .history
            .iter()
            .filter(|progress| progress.entry.kind == kind)
            .cloned()
            .collect();
        entries.sort_by_key(|progress| std::cmp::Reverse(progress.entry.updated_at_secs));
        entries
    }

    pub fn save_progress(&mut self, input: ProgressInput) {
        if !input.is_storable() {
            return;
        }
        let (kind, media, unit) = (input.kind, input.media.clone(), input.unit_number);
        self.history
            .retain(|progress| !is_entry(progress, kind, &media, unit));
        self.history.push(Progress::from_input(input));
    }

    pub fn progress_for(
        &self,
        kind: MediaKind,
        media: &MediaRef,
        unit_number: f64,
    ) -> Option<Progress> {
        self.history
            .iter()
            .find(|progress| is_entry(progress, kind, media, unit_number))
            .cloned()
    }

    pub fn last_progress(&self, kind: MediaKind, media: &MediaRef) -> Option<Progress> {
        self.history
            .iter()
            .filter(|progress| progress.entry.kind == kind && progress.entry.media == *media)
            .max_by_key(|progress| progress.entry.updated_at_secs)
            .cloned()
    }

    pub fn remove_progress(&mut self, kind: MediaKind, media: &MediaRef, unit_number: f64) {
        self.history
            .retain(|progress| !is_entry(progress, kind, media, unit_number));
    }

    pub fn clear_history(&mut self, kind: MediaKind) {
        self.history.retain(|progress| progress.entry.kind != kind);
    }
}

#[cfg(test)]
mod tests {
    use domain::media::MediaId;

    use super::*;

    fn media(id: u64) -> MediaRef {
        MediaRef::catalog(MediaId::new(id).unwrap())
    }

    fn input(id: u64, kind: MediaKind, unit: f64, position: f64, at: u64) -> ProgressInput {
        ProgressInput {
            media: media(id),
            kind,
            unit_number: unit,
            title: "Sousou no Frieren".into(),
            cover_url: None,
            position,
            length: 1440.0,
            updated_at_secs: at,
        }
    }

    #[test]
    fn one_entry_per_unit_newest_first_and_finished_units_are_marked() {
        let mut document = LibraryDocument::default();
        document.save_progress(input(1, MediaKind::Anime, 1.0, 1300.0, 10));
        document.save_progress(input(1, MediaKind::Anime, 2.0, 100.0, 11));
        document.save_progress(input(1, MediaKind::Anime, 2.0, 200.0, 12));
        let history = document.history_of(MediaKind::Anime);
        let shape: Vec<(f64, f64)> = history
            .iter()
            .map(|p| (p.entry.unit_number, p.entry.position))
            .collect();
        assert_eq!(shape, vec![(2.0, 200.0), (1.0, 1300.0)]);
        assert!(history[1].completed && !history[0].completed);
        assert_eq!(
            document
                .progress_for(MediaKind::Anime, &media(1), 2.0)
                .unwrap()
                .entry
                .position,
            200.0
        );
        assert_eq!(
            document
                .last_progress(MediaKind::Anime, &media(1))
                .unwrap()
                .entry
                .unit_number,
            2.0
        );
        assert!(
            document
                .progress_for(MediaKind::Anime, &media(1), 9.0)
                .is_none()
        );
    }

    #[test]
    fn ninety_percent_counts_as_finished_and_less_does_not() {
        let mut document = LibraryDocument::default();
        document.save_progress(input(1, MediaKind::Anime, 1.0, 1296.0, 1));
        document.save_progress(input(1, MediaKind::Anime, 2.0, 1295.0, 2));
        assert!(
            document
                .progress_for(MediaKind::Anime, &media(1), 1.0)
                .unwrap()
                .completed
        );
        assert!(
            !document
                .progress_for(MediaKind::Anime, &media(1), 2.0)
                .unwrap()
                .completed
        );
    }

    #[test]
    fn invalid_positions_are_not_stored() {
        let mut document = LibraryDocument::default();
        document.save_progress(input(1, MediaKind::Anime, 1.0, f64::NAN, 1));
        document.save_progress(input(1, MediaKind::Anime, 1.0, -5.0, 1));
        assert!(document.history.is_empty());
    }

    #[test]
    fn removing_and_clearing_work_per_kind() {
        let mut document = LibraryDocument::default();
        document.save_progress(input(1, MediaKind::Anime, 1.0, 10.0, 1));
        document.save_progress(input(1, MediaKind::Manga, 1.0, 10.0, 2));
        document.remove_progress(MediaKind::Anime, &media(1), 1.0);
        assert!(document.history_of(MediaKind::Anime).is_empty());
        assert_eq!(document.history_of(MediaKind::Manga).len(), 1);
        document.clear_history(MediaKind::Manga);
        assert!(document.history.is_empty());
    }

    #[test]
    fn fractional_units_are_distinct_entries() {
        let mut document = LibraryDocument::default();
        document.save_progress(input(1, MediaKind::Manga, 10.0, 1.0, 1));
        document.save_progress(input(1, MediaKind::Manga, 10.5, 1.0, 2));
        assert_eq!(document.history_of(MediaKind::Manga).len(), 2);
        assert!(
            document
                .progress_for(MediaKind::Manga, &media(1), 10.5)
                .is_some()
        );
    }
}
