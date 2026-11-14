use domain::media::{MediaFormat, MediaStatus, MediaSummary};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MatchTarget {
    pub titles: Vec<String>,
    pub format: Option<MediaFormat>,
    pub year: Option<u16>,
    pub unit_count: Option<u32>,
    pub status: Option<MediaStatus>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CandidateFacts {
    pub titles: Vec<String>,
    pub type_text: Option<String>,
    pub year: Option<u16>,
    pub unit_count: Option<u32>,
}

impl MatchTarget {
    pub fn of(media: &MediaSummary) -> Self {
        let titles = media
            .title
            .names()
            .into_iter()
            .map(str::to_string)
            .chain(
                media
                    .synonyms
                    .iter()
                    .filter(|name| !name.trim().is_empty())
                    .cloned(),
            )
            .collect();
        Self {
            titles,
            format: media.format,
            year: media.year,
            unit_count: media.unit_count,
            status: media.status,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use domain::media::{MediaId, MediaKind, MediaTitle};

    #[test]
    fn of_collects_every_title_and_synonym() {
        let title = MediaTitle {
            romaji: "Kimi no Na wa.".into(),
            english: Some("Your Name.".into()),
            native: None,
        };
        let mut media = MediaSummary::new(MediaId::new(21519).unwrap(), MediaKind::Anime, title);
        media.synonyms = vec!["Your Name".into(), " ".into()];
        media.format = Some(MediaFormat::Movie);
        media.year = Some(2016);
        let target = MatchTarget::of(&media);
        assert_eq!(
            target.titles,
            vec!["Kimi no Na wa.", "Your Name.", "Your Name"]
        );
        assert_eq!(target.format, Some(MediaFormat::Movie));
        assert_eq!(target.year, Some(2016));
    }
}
