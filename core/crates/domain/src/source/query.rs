use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum SourceOrder {
    #[default]
    Newest,
    Oldest,
    Az,
    Za,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SourceSearch {
    pub query: String,
    pub page: u32,
    pub order: SourceOrder,
}

impl SourceSearch {
    pub fn new(query: impl Into<String>) -> Self {
        Self {
            query: query.into(),
            page: 1,
            order: SourceOrder::default(),
        }
    }

    pub fn with_query(&self, query: impl Into<String>) -> Self {
        Self {
            query: query.into(),
            page: self.page,
            order: self.order,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_search_starts_on_page_one_newest_first() {
        let search = SourceSearch::new("kimi no na wa");
        assert_eq!(search.page, 1);
        assert_eq!(search.order, SourceOrder::Newest);
    }

    #[test]
    fn with_query_keeps_page_and_order() {
        let search = SourceSearch {
            query: "a".into(),
            page: 3,
            order: SourceOrder::Az,
        };
        let relaxed = search.with_query("b");
        assert_eq!(
            (relaxed.query.as_str(), relaxed.page, relaxed.order),
            ("b", 3, SourceOrder::Az)
        );
    }
}
