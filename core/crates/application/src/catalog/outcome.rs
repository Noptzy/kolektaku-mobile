use domain::error::SourceError;
use domain::source::SourceId;

use super::MediaCard;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SearchNotice {
    pub origin: Option<SourceId>,
    pub error: SourceError,
}

#[derive(Debug, Clone, PartialEq)]
pub struct SearchOutcome {
    pub cards: Vec<MediaCard>,
    pub has_next_page: bool,
    pub notices: Vec<SearchNotice>,
}
