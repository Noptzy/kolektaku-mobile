use domain::media::MediaSummary;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct CatalogIds {
    pub anilist: u64,
    pub mal: Option<u64>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Verdict {
    Certain,
    Refused,
    Judge,
}

impl CatalogIds {
    pub fn of(media: &MediaSummary) -> Self {
        Self {
            anilist: media.id.get(),
            mal: media.id_mal,
        }
    }

    pub fn verdict(&self, anilist: Option<u64>, mal: Option<u64>) -> Verdict {
        if let Some(known) = anilist {
            return if known == self.anilist {
                Verdict::Certain
            } else {
                Verdict::Refused
            };
        }
        match (self.mal, mal) {
            (Some(wanted), Some(known)) if wanted == known => Verdict::Certain,
            (Some(_), Some(_)) => Verdict::Refused,
            _ => Verdict::Judge,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn ids(mal: Option<u64>) -> CatalogIds {
        CatalogIds { anilist: 100, mal }
    }

    #[test]
    fn the_same_anilist_number_is_certain_and_another_is_refused() {
        assert_eq!(ids(None).verdict(Some(100), None), Verdict::Certain);
        assert_eq!(ids(None).verdict(Some(7), None), Verdict::Refused);
    }

    #[test]
    fn the_mal_number_decides_when_the_site_has_no_anilist_number() {
        assert_eq!(ids(Some(5)).verdict(None, Some(5)), Verdict::Certain);
        assert_eq!(ids(Some(5)).verdict(None, Some(6)), Verdict::Refused);
    }

    #[test]
    fn a_missing_number_on_either_side_leaves_it_to_the_judge() {
        assert_eq!(ids(Some(5)).verdict(None, None), Verdict::Judge);
        assert_eq!(ids(None).verdict(None, Some(5)), Verdict::Judge);
        assert_eq!(ids(None).verdict(None, None), Verdict::Judge);
    }

    #[test]
    fn the_anilist_number_wins_over_the_mal_number() {
        assert_eq!(ids(Some(5)).verdict(Some(100), Some(9)), Verdict::Certain);
    }
}
