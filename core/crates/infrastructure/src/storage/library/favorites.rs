use domain::library::{Favorite, FavoriteInput};
use domain::media::{MediaKind, MediaRef};

use super::document::LibraryDocument;

impl LibraryDocument {
    pub fn favorites_of(&self, kind: MediaKind) -> Vec<Favorite> {
        self.favorites
            .iter()
            .filter(|favorite| favorite.entry.kind == kind)
            .cloned()
            .collect()
    }

    pub fn is_favorite(&self, kind: MediaKind, media: &MediaRef) -> bool {
        self.favorites
            .iter()
            .any(|favorite| favorite.entry.kind == kind && favorite.entry.media == *media)
    }

    pub fn toggle_favorite(&mut self, input: FavoriteInput, now_secs: u64) -> bool {
        let before = self.favorites.len();
        self.favorites.retain(|favorite| {
            !(favorite.entry.kind == input.kind && favorite.entry.media == input.media)
        });
        if self.favorites.len() < before {
            return false;
        }
        self.favorites.insert(0, Favorite::added(input, now_secs));
        true
    }
}

#[cfg(test)]
mod tests {
    use domain::media::MediaId;

    use super::*;

    fn input(id: u64, kind: MediaKind, title: &str) -> FavoriteInput {
        FavoriteInput {
            media: MediaRef::catalog(MediaId::new(id).unwrap()),
            kind,
            title: title.into(),
            cover_url: None,
        }
    }

    #[test]
    fn toggling_adds_then_removes() {
        let mut document = LibraryDocument::default();
        assert!(document.toggle_favorite(input(1, MediaKind::Anime, "Frieren"), 10));
        assert!(document.is_favorite(
            MediaKind::Anime,
            &MediaRef::catalog(MediaId::new(1).unwrap())
        ));
        assert!(!document.toggle_favorite(input(1, MediaKind::Anime, "Frieren"), 20));
        assert!(document.favorites_of(MediaKind::Anime).is_empty());
    }

    #[test]
    fn the_same_id_as_anime_and_manga_stays_apart() {
        let mut document = LibraryDocument::default();
        document.toggle_favorite(input(1, MediaKind::Anime, "A"), 1);
        document.toggle_favorite(input(1, MediaKind::Manga, "M"), 2);
        assert_eq!(document.favorites_of(MediaKind::Anime)[0].entry.title, "A");
        assert_eq!(document.favorites_of(MediaKind::Manga)[0].entry.title, "M");
        assert!(!document.is_favorite(
            MediaKind::Manga,
            &MediaRef::catalog(MediaId::new(2).unwrap())
        ));
    }

    #[test]
    fn the_newest_favorite_comes_first() {
        let mut document = LibraryDocument::default();
        document.toggle_favorite(input(1, MediaKind::Anime, "old"), 1);
        document.toggle_favorite(input(2, MediaKind::Anime, "new"), 2);
        let titles: Vec<String> = document
            .favorites_of(MediaKind::Anime)
            .into_iter()
            .map(|f| f.entry.title)
            .collect();
        assert_eq!(titles, vec!["new", "old"]);
        assert_eq!(document.favorites_of(MediaKind::Anime)[0].added_at_secs, 2);
    }

    #[test]
    fn a_site_only_title_can_be_a_favorite_too() {
        use domain::source::{ItemId, SourceId};
        let reference = MediaRef::source(SourceId::new("komiku"), ItemId::new("one-piece"));
        let mut document = LibraryDocument::default();
        let favorite = FavoriteInput {
            media: reference.clone(),
            kind: MediaKind::Manga,
            title: "One Piece".into(),
            cover_url: None,
        };
        assert!(document.toggle_favorite(favorite, 1));
        assert!(document.is_favorite(MediaKind::Manga, &reference));
    }
}
