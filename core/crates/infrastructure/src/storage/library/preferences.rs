use domain::library::UnitOrder;
use domain::media::{MediaKind, MediaRef};

use super::document::{LibraryDocument, UnitOrderEntry};

const MAX_SEARCHES: usize = 8;

impl LibraryDocument {
    pub fn unit_order_of(&self, kind: MediaKind, media: &MediaRef) -> UnitOrder {
        self.unit_orders
            .iter()
            .find(|entry| entry.kind == kind && entry.media == *media)
            .map(|entry| entry.order)
            .unwrap_or_default()
    }

    pub fn set_unit_order(&mut self, kind: MediaKind, media: &MediaRef, order: UnitOrder) {
        self.unit_orders
            .retain(|entry| !(entry.kind == kind && entry.media == *media));
        if order != UnitOrder::default() {
            self.unit_orders.push(UnitOrderEntry {
                kind,
                media: media.clone(),
                order,
            });
        }
    }

    pub fn preference_of(&self, name: &str) -> Option<String> {
        self.preferences.get(name).cloned()
    }

    pub fn set_preference(&mut self, name: &str, value: &str) {
        self.preferences.insert(name.to_string(), value.to_string());
    }

    pub fn searches_of(&self, kind: MediaKind) -> Vec<String> {
        self.searches
            .get(kind.as_str())
            .cloned()
            .unwrap_or_default()
    }

    pub fn add_search(&mut self, kind: MediaKind, query: &str) {
        let query = query.trim();
        if query.is_empty() {
            return;
        }
        let recent = self.searches.entry(kind.as_str().to_string()).or_default();
        let wanted = query.to_lowercase();
        recent.retain(|known| known.to_lowercase() != wanted);
        recent.insert(0, query.to_string());
        recent.truncate(MAX_SEARCHES);
    }

    pub fn clear_searches(&mut self, kind: MediaKind) {
        self.searches.remove(kind.as_str());
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
    fn the_unit_order_defaults_to_oldest_first_and_is_remembered_per_title_and_kind() {
        let mut document = LibraryDocument::default();
        assert_eq!(
            document.unit_order_of(MediaKind::Anime, &media(1)),
            UnitOrder::Asc
        );
        document.set_unit_order(MediaKind::Anime, &media(1), UnitOrder::Desc);
        assert_eq!(
            document.unit_order_of(MediaKind::Anime, &media(1)),
            UnitOrder::Desc
        );
        assert_eq!(
            document.unit_order_of(MediaKind::Anime, &media(2)),
            UnitOrder::Asc
        );
        assert_eq!(
            document.unit_order_of(MediaKind::Manga, &media(1)),
            UnitOrder::Asc
        );
    }

    #[test]
    fn going_back_to_the_default_order_forgets_the_entry() {
        let mut document = LibraryDocument::default();
        document.set_unit_order(MediaKind::Anime, &media(1), UnitOrder::Desc);
        document.set_unit_order(MediaKind::Anime, &media(1), UnitOrder::Asc);
        assert!(document.unit_orders.is_empty());
    }

    #[test]
    fn small_preferences_are_remembered() {
        let mut document = LibraryDocument::default();
        assert_eq!(document.preference_of("lastMenu"), None);
        document.set_preference("lastMenu", "manga");
        document.set_preference("lastMenu", "anime");
        assert_eq!(document.preference_of("lastMenu").as_deref(), Some("anime"));
    }

    #[test]
    fn keeps_the_last_eight_searches_newest_first_without_duplicates() {
        let mut document = LibraryDocument::default();
        for query in ["a", "b", "c", "d", "e", "f", "g", "h", "i", "B "] {
            document.add_search(MediaKind::Anime, query);
        }
        let searches = document.searches_of(MediaKind::Anime);
        assert_eq!(searches.len(), 8);
        assert_eq!(searches[0], "B");
        assert_eq!(
            searches
                .iter()
                .filter(|query| query.to_lowercase() == "b")
                .count(),
            1
        );
    }

    #[test]
    fn blank_searches_are_ignored_and_clearing_is_per_kind() {
        let mut document = LibraryDocument::default();
        document.add_search(MediaKind::Anime, "naruto");
        document.add_search(MediaKind::Manga, "berserk");
        document.add_search(MediaKind::Anime, "   ");
        assert_eq!(document.searches_of(MediaKind::Anime), vec!["naruto"]);
        document.clear_searches(MediaKind::Anime);
        assert!(document.searches_of(MediaKind::Anime).is_empty());
        assert_eq!(document.searches_of(MediaKind::Manga), vec!["berserk"]);
    }
}
