use application::catalog::{
    GenrePage, HomeOutcome, HomeSection, HomeSectionId, MediaCard, SearchNotice, SearchOutcome,
};

use super::media::{MediaRefDto, tag};
use crate::error::BridgeError;

#[derive(Debug, Clone, PartialEq)]
pub struct MediaCardDto {
    pub reference: MediaRefDto,
    pub title: String,
    pub title_english: Option<String>,
    pub cover_url: Option<String>,
    pub latest_label: Option<String>,
    pub score: Option<f32>,
    pub year: Option<u16>,
    pub format: Option<String>,
    pub status: Option<String>,
    pub genres: Vec<String>,
    pub unit_count: Option<u32>,
    pub limited: bool,
    pub sources: Vec<String>,
}

impl From<&MediaCard> for MediaCardDto {
    fn from(card: &MediaCard) -> Self {
        let summary = card.summary.as_ref();
        Self {
            reference: (&card.reference).into(),
            title: card.title.clone(),
            title_english: summary.and_then(|media| media.title.english.clone()),
            cover_url: card.cover_url.clone(),
            latest_label: card.latest_label.clone(),
            score: summary.and_then(|media| media.score),
            year: summary.and_then(|media| media.year),
            format: summary.and_then(|media| media.format.as_ref().map(tag)),
            status: summary.and_then(|media| media.status.as_ref().map(tag)),
            genres: summary
                .map(|media| media.genres.clone())
                .unwrap_or_default(),
            unit_count: summary.and_then(|media| media.unit_count),
            limited: summary.is_none(),
            sources: card
                .links
                .iter()
                .map(|link| link.source.to_string())
                .collect(),
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct NoticeDto {
    pub source: Option<String>,
    pub error: BridgeError,
}

impl From<&SearchNotice> for NoticeDto {
    fn from(notice: &SearchNotice) -> Self {
        Self {
            source: notice.origin.as_ref().map(|origin| origin.to_string()),
            error: notice.error.clone().into(),
        }
    }
}

pub fn notices_dto(notices: &[SearchNotice]) -> Vec<NoticeDto> {
    notices.iter().map(Into::into).collect()
}

pub fn cards_dto(cards: &[MediaCard]) -> Vec<MediaCardDto> {
    cards.iter().map(Into::into).collect()
}

#[derive(Debug, Clone, PartialEq)]
pub struct HomeSectionDto {
    pub id: String,
    pub cards: Vec<MediaCardDto>,
}

fn section_name(id: HomeSectionId) -> &'static str {
    match id {
        HomeSectionId::Trending => "trending",
        HomeSectionId::Seasonal => "seasonal",
        HomeSectionId::Popular => "popular",
        HomeSectionId::Latest => "latest",
    }
}

impl From<&HomeSection> for HomeSectionDto {
    fn from(section: &HomeSection) -> Self {
        Self {
            id: section_name(section.id).to_string(),
            cards: cards_dto(&section.cards),
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct HomeDto {
    pub sections: Vec<HomeSectionDto>,
    pub notices: Vec<NoticeDto>,
}

impl From<&HomeOutcome> for HomeDto {
    fn from(outcome: &HomeOutcome) -> Self {
        Self {
            sections: outcome.sections.iter().map(Into::into).collect(),
            notices: notices_dto(&outcome.notices),
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct CardPageDto {
    pub cards: Vec<MediaCardDto>,
    pub has_next_page: bool,
    pub notices: Vec<NoticeDto>,
}

impl From<&SearchOutcome> for CardPageDto {
    fn from(outcome: &SearchOutcome) -> Self {
        Self {
            cards: cards_dto(&outcome.cards),
            has_next_page: outcome.has_next_page,
            notices: notices_dto(&outcome.notices),
        }
    }
}

impl From<&GenrePage> for CardPageDto {
    fn from(page: &GenrePage) -> Self {
        Self {
            cards: cards_dto(&page.cards),
            has_next_page: page.has_next_page,
            notices: notices_dto(&page.notices),
        }
    }
}

#[cfg(test)]
mod tests {
    use domain::media::{MediaFormat, MediaId, MediaKind, MediaRef, MediaSummary, MediaTitle};

    use super::*;

    #[test]
    fn a_catalog_card_shows_the_catalog_data() {
        let mut media = MediaSummary::new(
            MediaId::new(1).unwrap(),
            MediaKind::Anime,
            MediaTitle::new("Alpha"),
        );
        media.format = Some(MediaFormat::Movie);
        media.score = Some(8.1);
        let card = MediaCardDto::from(&MediaCard::of_media(media));
        assert_eq!(card.format.as_deref(), Some("MOVIE"));
        assert_eq!(card.score, Some(8.1));
        assert!(!card.limited && card.sources.is_empty());
    }

    #[test]
    fn a_site_only_card_is_marked_limited() {
        let card = MediaCard {
            reference: MediaRef::source(
                domain::source::SourceId::new("a"),
                domain::source::ItemId::new("x"),
            ),
            title: "Mystery".into(),
            cover_url: None,
            latest_label: Some("Ep 3".into()),
            summary: None,
            links: Vec::new(),
        };
        let dto = MediaCardDto::from(&card);
        assert!(dto.limited);
        assert_eq!(dto.latest_label.as_deref(), Some("Ep 3"));
        assert_eq!(dto.reference, MediaRefDto::site("a", "x"));
    }

    #[test]
    fn section_ids_become_stable_names() {
        let section = HomeSection {
            id: HomeSectionId::Latest,
            cards: Vec::new(),
        };
        assert_eq!(HomeSectionDto::from(&section).id, "latest");
    }
}
