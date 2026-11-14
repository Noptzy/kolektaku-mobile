use std::collections::HashMap;

use domain::error::SourceError;
use domain::source::{Genre, SourceItem, SourcePage};

#[derive(Default)]
pub struct FakeGenres {
    list: Vec<Genre>,
    pages: HashMap<String, Vec<SourceItem>>,
}

impl FakeGenres {
    pub fn new(list: &[(&str, &str)]) -> Self {
        Self {
            list: list
                .iter()
                .map(|(slug, name)| Genre::new(*slug, *name))
                .collect(),
            pages: HashMap::new(),
        }
    }

    pub fn with_page(mut self, slug: &str, items: Vec<SourceItem>) -> Self {
        self.pages.insert(slug.to_string(), items);
        self
    }

    pub fn list(&self) -> Vec<Genre> {
        self.list.clone()
    }

    pub fn page(&self, slug: &str, page: u32) -> Result<SourcePage, SourceError> {
        let items = self
            .pages
            .get(slug)
            .cloned()
            .ok_or_else(|| SourceError::NotFound(format!("genre {slug}")))?;
        Ok(SourcePage {
            items,
            page,
            total_pages: 1,
        })
    }
}

#[cfg(test)]
mod tests {
    use domain::source::ItemId;

    use super::*;

    #[test]
    fn lists_its_genres_and_serves_known_pages_only() {
        let genres = FakeGenres::new(&[("action", "Action")])
            .with_page("action", vec![SourceItem::new(ItemId::new("1"), "A")]);
        assert_eq!(genres.list()[0].slug, "action");
        assert_eq!(genres.page("action", 2).unwrap().page, 2);
        assert!(matches!(
            genres.page("drama", 1),
            Err(SourceError::NotFound(_))
        ));
    }
}
