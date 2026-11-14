use domain::media::{MediaRef, MediaSummary};
use domain::source::SourceLink;

#[derive(Debug, Clone, PartialEq)]
pub struct MediaCard {
    pub reference: MediaRef,
    pub title: String,
    pub cover_url: Option<String>,
    pub latest_label: Option<String>,
    pub summary: Option<MediaSummary>,
    pub links: Vec<SourceLink>,
}

impl MediaCard {
    pub fn of_media(media: MediaSummary) -> Self {
        Self {
            reference: MediaRef::catalog(media.id),
            title: media.title.romaji.clone(),
            cover_url: media.cover_url.clone(),
            latest_label: None,
            summary: Some(media),
            links: Vec::new(),
        }
    }
}

#[cfg(test)]
mod tests {
    use domain::media::{MediaId, MediaKind, MediaTitle};

    use super::*;

    #[test]
    fn a_catalog_entry_becomes_a_card_without_links() {
        let mut media = MediaSummary::new(
            MediaId::new(5).unwrap(),
            MediaKind::Anime,
            MediaTitle::new("Bleach"),
        );
        media.cover_url = Some("https://img.test/b.jpg".into());
        let card = MediaCard::of_media(media);
        assert_eq!(card.reference.catalog_id().map(|id| id.get()), Some(5));
        assert_eq!(card.title, "Bleach");
        assert_eq!(card.cover_url.as_deref(), Some("https://img.test/b.jpg"));
        assert!(card.links.is_empty() && card.summary.is_some());
    }
}
