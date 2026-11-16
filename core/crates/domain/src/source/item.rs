use serde::{Deserialize, Serialize};

use super::ItemId;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SourceItem {
    pub item_id: ItemId,
    pub title: String,
    pub cover_url: Option<String>,
    pub latest_label: Option<String>,
}

impl SourceItem {
    pub fn new(item_id: ItemId, title: impl Into<String>) -> Self {
        Self {
            item_id,
            title: title.into(),
            cover_url: None,
            latest_label: None,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SourceDetail {
    pub item: SourceItem,
    pub alternative_titles: Vec<String>,
    pub type_text: Option<String>,
    pub year: Option<u16>,
    pub unit_count: Option<u32>,
    pub origin: Option<String>,
    pub synopsis: String,
    pub genres: Vec<String>,
    pub catalog_id: Option<u64>,
}

impl SourceDetail {
    pub fn new(item: SourceItem) -> Self {
        Self {
            item,
            alternative_titles: Vec::new(),
            type_text: None,
            year: None,
            unit_count: None,
            origin: None,
            synopsis: String::new(),
            genres: Vec::new(),
            catalog_id: None,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SourcePage {
    pub items: Vec<SourceItem>,
    pub page: u32,
    pub total_pages: u32,
}

impl SourcePage {
    pub fn single(items: Vec<SourceItem>) -> Self {
        Self {
            items,
            page: 1,
            total_pages: 1,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn detail_starts_empty_around_its_item() {
        let detail = SourceDetail::new(SourceItem::new(ItemId::new("1/x"), "Judul"));
        assert_eq!(detail.item.title, "Judul");
        assert!(detail.genres.is_empty());
        assert_eq!(detail.year, None);
    }

    #[test]
    fn single_page_has_one_total_page() {
        let page = SourcePage::single(vec![SourceItem::new(ItemId::new("a"), "A")]);
        assert_eq!((page.page, page.total_pages), (1, 1));
        assert_eq!(page.items.len(), 1);
    }
}
