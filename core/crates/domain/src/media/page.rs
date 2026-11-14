use serde::{Deserialize, Serialize};

use super::MediaSummary;

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MediaPage {
    pub items: Vec<MediaSummary>,
    pub page: u32,
    pub has_next_page: bool,
}

impl MediaPage {
    pub fn empty(page: u32) -> Self {
        Self {
            items: Vec::new(),
            page,
            has_next_page: false,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_page_has_no_items_and_no_next_page() {
        let page = MediaPage::empty(3);
        assert!(page.items.is_empty());
        assert_eq!(page.page, 3);
        assert!(!page.has_next_page);
    }
}
