use super::MediaCard;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HomeSectionId {
    Trending,
    Seasonal,
    Popular,
    TopRated,
    NewThisWeek,
    FinishedThisWeek,
    Returning,
    Latest,
}

impl HomeSectionId {
    pub fn is_weekly(self) -> bool {
        matches!(
            self,
            Self::TopRated | Self::NewThisWeek | Self::FinishedThisWeek | Self::Returning
        )
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct HomeSection {
    pub id: HomeSectionId,
    pub cards: Vec<MediaCard>,
}
