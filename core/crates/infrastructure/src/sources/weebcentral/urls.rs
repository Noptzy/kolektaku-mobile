use domain::error::SourceError;
use url::Url;

use crate::sources::support::is_slug;

const PAGE_SIZE: u32 = 32;
const SLUG_EXTRA: [char; 3] = ['.', '_', '%'];

#[derive(Debug, Clone)]
pub struct WeebCentralUrls {
    base: Url,
}

fn not_found(what: &str, value: &str) -> SourceError {
    SourceError::NotFound(format!("not a valid {what}: {value}"))
}

pub fn is_series_code(text: &str) -> bool {
    text.len() == 26 && text.chars().all(|c| c.is_ascii_digit() || c.is_ascii_uppercase())
}

impl WeebCentralUrls {
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

    fn listing(&self, text: &str, offset: u32, sort: &str) -> String {
        let mut url = self.at("/search/data");
        url.query_pairs_mut()
            .append_pair("text", text.trim())
            .append_pair("limit", &PAGE_SIZE.to_string())
            .append_pair("offset", &offset.to_string())
            .append_pair("sort", sort)
            .append_pair("order", "Descending")
            .append_pair("official", "Any")
            .append_pair("anime", "Any")
            .append_pair("adult", "False")
            .append_pair("display_mode", "Full Display");
        url.into()
    }

    pub fn search(&self, query: &str) -> String {
        self.listing(query, 0, "Best Match")
    }

    pub fn latest(&self, page: u32) -> String {
        let offset = page.saturating_sub(1) * PAGE_SIZE;
        self.listing("", offset, "Latest Updates")
    }

    fn series_parts<'a>(&self, id: &'a str) -> Result<(&'a str, &'a str), SourceError> {
        let (code, slug) = id.split_once('/').ok_or_else(|| not_found("title id", id))?;
        if is_series_code(code) && is_slug(slug, &SLUG_EXTRA) {
            Ok((code, slug))
        } else {
            Err(not_found("title id", id))
        }
    }

    pub fn detail(&self, id: &str) -> Result<String, SourceError> {
        let (code, slug) = self.series_parts(id)?;
        Ok(self.at(&format!("/series/{code}/{slug}")).into())
    }

    pub fn chapter_list(&self, id: &str) -> Result<String, SourceError> {
        let (code, _) = self.series_parts(id)?;
        Ok(self.at(&format!("/series/{code}/full-chapter-list")).into())
    }

    pub fn images(&self, chapter: &str) -> Result<String, SourceError> {
        if !is_series_code(chapter) {
            return Err(not_found("chapter id", chapter));
        }
        let mut url = self.at(&format!("/chapters/{chapter}/images"));
        url.query_pairs_mut()
            .append_pair("is_prev", "False")
            .append_pair("current_page", "1")
            .append_pair("reading_style", "long_strip");
        Ok(url.into())
    }
}
