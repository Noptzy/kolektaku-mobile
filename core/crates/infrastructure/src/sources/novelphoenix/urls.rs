use domain::error::SourceError;
use url::Url;

use crate::sources::support::is_slug;

const SLUG_EXTRA: [char; 3] = ['.', '_', '%'];

#[derive(Debug, Clone)]
pub struct NovelPhoenixUrls {
    base: Url,
}

fn not_found(what: &str, value: &str) -> SourceError {
    SourceError::NotFound(format!("not a valid {what}: {value}"))
}

fn is_chapter_slug(text: &str) -> bool {
    text.strip_prefix("chapter-")
        .is_some_and(|number| !number.is_empty() && number.chars().all(|c| c.is_ascii_digit()))
}

impl NovelPhoenixUrls {
    pub fn new(base_url: &str) -> Result<Self, SourceError> {
        let base = Url::parse(base_url)
            .ok()
            .filter(|url| matches!(url.scheme(), "http" | "https") && url.host_str().is_some())
            .ok_or_else(|| {
                SourceError::Unsupported(format!("invalid source address: {base_url}"))
            })?;
        Ok(Self { base })
    }

    pub fn base(&self) -> &Url {
        &self.base
    }

    fn at(&self, path: &str) -> Url {
        let mut url = self.base.clone();
        url.set_path(path);
        url.set_query(None);
        url
    }

    pub fn latest(&self, page: u32) -> String {
        let mut url = self.at("/genre-all/sort-new/status-all/all-novel");
        if page > 1 {
            url.query_pairs_mut().append_pair("page", &page.to_string());
        }
        url.into()
    }

    pub fn search(&self, query: &str) -> String {
        let mut url = self.at("/search");
        url.query_pairs_mut().append_pair("keyword", query.trim());
        url.into()
    }

    pub fn detail(&self, slug: &str) -> Result<String, SourceError> {
        self.checked(slug)?;
        Ok(self.at(&format!("/novel/{slug}")).into())
    }

    pub fn chapter_list(&self, slug: &str, page: u32) -> Result<String, SourceError> {
        self.checked(slug)?;
        let mut url = self.at(&format!("/novel/{slug}/chapters"));
        url.query_pairs_mut().append_pair("page", &page.max(1).to_string());
        Ok(url.into())
    }

    pub fn chapter(&self, id: &str) -> Result<String, SourceError> {
        let (slug, chapter) = id
            .split_once('/')
            .ok_or_else(|| not_found("chapter id", id))?;
        self.checked(slug)?;
        if !is_chapter_slug(chapter) {
            return Err(not_found("chapter id", id));
        }
        Ok(self.at(&format!("/novel/{slug}/{chapter}")).into())
    }

    fn checked(&self, slug: &str) -> Result<(), SourceError> {
        if is_slug(slug, &SLUG_EXTRA) {
            Ok(())
        } else {
            Err(not_found("title id", slug))
        }
    }
}
