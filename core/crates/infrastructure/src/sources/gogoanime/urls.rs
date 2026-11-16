use domain::error::SourceError;
use url::Url;

use crate::sources::support::is_slug;

const MAX_SLUG: usize = 200;

#[derive(Debug, Clone)]
pub struct GogoanimeUrls {
    base: Url,
}

pub fn valid_slug(slug: &str) -> bool {
    slug.len() <= MAX_SLUG && is_slug(slug, &[])
}

fn not_found(what: &str, value: &str) -> SourceError {
    SourceError::NotFound(format!("not a valid {what}: {value}"))
}

fn single_segment(path: &str) -> Option<String> {
    let mut parts = path.split('/').filter(|part| !part.is_empty());
    let first = parts.next()?;
    parts.next().is_none().then(|| first.to_string())
}

impl GogoanimeUrls {
    pub fn new(base_url: &str) -> Result<Self, SourceError> {
        let base = Url::parse(base_url)
            .ok()
            .filter(|url| url.scheme() == "https" && url.host_str().is_some())
            .ok_or_else(|| SourceError::Unsupported(format!("invalid source address: {base_url}")))?;
        Ok(Self { base })
    }

    pub fn base(&self) -> &Url {
        &self.base
    }

    fn with_path(&self, path: &str) -> Url {
        let mut url = self.base.clone();
        url.set_path(path);
        url.set_query(None);
        url
    }

    pub fn latest(&self, page: u32) -> String {
        let mut url = self.with_path("/anime/");
        url.query_pairs_mut()
            .append_pair("status", "")
            .append_pair("type", "")
            .append_pair("order", "update")
            .append_pair("page", &page.max(1).to_string());
        url.into()
    }

    pub fn search(&self, query: &str, page: u32) -> String {
        let path = match page {
            0 | 1 => "/".to_string(),
            more => format!("/page/{more}/"),
        };
        let mut url = self.with_path(&path);
        url.query_pairs_mut().append_pair("s", query.trim());
        url.into()
    }

    pub fn anime(&self, slug: &str) -> Result<String, SourceError> {
        if !valid_slug(slug) {
            return Err(not_found("title", slug));
        }
        Ok(self.with_path(&format!("/anime/{slug}/")).into())
    }

    pub fn episode(&self, slug: &str) -> Result<String, SourceError> {
        if !valid_slug(slug) {
            return Err(not_found("episode", slug));
        }
        Ok(self.with_path(&format!("/{slug}/")).into())
    }

    pub fn anime_slug(&self, href: &str) -> Option<String> {
        let url = self.base.join(href.trim()).ok()?;
        if url.host_str() != self.base.host_str() {
            return None;
        }
        let rest = url.path().strip_prefix("/anime/")?;
        single_segment(rest).filter(|slug| valid_slug(slug))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn urls() -> GogoanimeUrls {
        GogoanimeUrls::new("https://gogoanime.or.at").unwrap()
    }

    #[test]
    fn latest_asks_for_the_most_recently_updated_page() {
        assert_eq!(
            urls().latest(2),
            "https://gogoanime.or.at/anime/?status=&type=&order=update&page=2"
        );
        assert!(urls().latest(0).ends_with("page=1"));
    }

    #[test]
    fn search_uses_the_first_page_path_then_numbered_pages() {
        assert_eq!(urls().search("oshi no ko", 1), "https://gogoanime.or.at/?s=oshi+no+ko");
        assert_eq!(urls().search(" naruto ", 3), "https://gogoanime.or.at/page/3/?s=naruto");
    }

    #[test]
    fn a_title_and_an_episode_have_their_own_addresses() {
        assert_eq!(
            urls().anime("oshi-no-ko-season-2").unwrap(),
            "https://gogoanime.or.at/anime/oshi-no-ko-season-2/"
        );
        assert_eq!(
            urls().episode("oshi-no-ko-season-2-episode-13").unwrap(),
            "https://gogoanime.or.at/oshi-no-ko-season-2-episode-13/"
        );
    }

    #[test]
    fn anything_that_could_leave_the_site_is_refused() {
        for bad in ["", "../x", "a/b", "a?b", "-x", "a b", "a%2fb", "x\\y"] {
            assert!(urls().anime(bad).is_err(), "{bad}");
            assert!(urls().episode(bad).is_err(), "{bad}");
        }
        assert!(urls().anime(&"a".repeat(MAX_SLUG + 1)).is_err());
    }

    #[test]
    fn slugs_are_read_back_only_from_this_site() {
        let urls = urls();
        assert_eq!(
            urls.anime_slug("https://gogoanime.or.at/anime/one-piece/").as_deref(),
            Some("one-piece")
        );
        assert_eq!(urls.anime_slug("/anime/one-piece/").as_deref(), Some("one-piece"));
        assert_eq!(urls.anime_slug("https://other.example/anime/one-piece/"), None);
        assert_eq!(urls.anime_slug("https://gogoanime.or.at/anime/a/b/"), None);
        assert_eq!(urls.anime_slug("https://gogoanime.or.at/genres/drama/"), None);
    }

    #[test]
    fn an_address_that_is_not_https_is_unsupported() {
        assert!(GogoanimeUrls::new("http://gogoanime.or.at").is_err());
        assert!(GogoanimeUrls::new("not a url").is_err());
    }
}
