use std::collections::HashSet;

use domain::media::{MediaKind, MediaRef};

use super::document::LibraryDocument;

fn is_wanted(
    kind: MediaKind,
    from: MediaKind,
    media: &MediaRef,
    wanted: &HashSet<&MediaRef>,
) -> bool {
    kind == from && wanted.contains(media)
}

impl LibraryDocument {
    pub fn movable(&self, from: MediaKind, media: &[MediaRef]) -> usize {
        let wanted: HashSet<&MediaRef> = media.iter().collect();
        let favorites = self
            .favorites
            .iter()
            .filter(|item| is_wanted(item.entry.kind, from, &item.entry.media, &wanted))
            .count();
        let history = self
            .history
            .iter()
            .filter(|item| is_wanted(item.entry.kind, from, &item.entry.media, &wanted))
            .count();
        let orders = self
            .unit_orders
            .iter()
            .filter(|item| is_wanted(item.kind, from, &item.media, &wanted))
            .count();
        favorites + history + orders
    }

    pub fn move_entries(&mut self, from: MediaKind, to: MediaKind, media: &[MediaRef]) -> usize {
        let wanted: HashSet<&MediaRef> = media.iter().collect();
        let mut moved = 0;
        for item in &mut self.favorites {
            if is_wanted(item.entry.kind, from, &item.entry.media, &wanted) {
                item.entry.kind = to;
                moved += 1;
            }
        }
        for item in &mut self.history {
            if is_wanted(item.entry.kind, from, &item.entry.media, &wanted) {
                item.entry.kind = to;
                moved += 1;
            }
        }
        for item in &mut self.unit_orders {
            if is_wanted(item.kind, from, &item.media, &wanted) {
                item.kind = to;
                moved += 1;
            }
        }
        moved
    }
}
