use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ChapterPage {
    pub url: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ChapterPages {
    pub pages: Vec<ChapterPage>,
}

impl ChapterPages {
    pub fn from_urls(urls: impl IntoIterator<Item = String>) -> Self {
        Self {
            pages: urls.into_iter().map(|url| ChapterPage { url }).collect(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn from_urls_keeps_order() {
        let pages = ChapterPages::from_urls(["a".to_string(), "b".to_string()]);
        let urls: Vec<&str> = pages.pages.iter().map(|page| page.url.as_str()).collect();
        assert_eq!(urls, vec!["a", "b"]);
    }
}
