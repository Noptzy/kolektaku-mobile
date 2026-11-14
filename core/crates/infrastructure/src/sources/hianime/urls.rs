use domain::error::SourceError;
use url::Url;

const MAX_SLUG: usize = 240;

#[derive(Debug, Clone)]
pub struct HianimeUrls {
    api: Url,
}

pub fn valid_slug(slug: &str) -> bool {
    !slug.is_empty()
        && slug.len() <= MAX_SLUG
        && !slug
            .chars()
            .any(|c| c.is_control() || matches!(c, '/' | '\\' | '?' | '#' | '%'))
}

pub fn valid_object_id(id: &str) -> bool {
    id.len() == 24 && id.chars().all(|c| c.is_ascii_hexdigit())
}

fn not_found(what: &str, value: &str) -> SourceError {
    SourceError::NotFound(format!("not a valid {what}: {value}"))
}

impl HianimeUrls {
    pub fn new(api_url: &str) -> Result<Self, SourceError> {
        let api = Url::parse(api_url)
            .ok()
            .filter(|url| matches!(url.scheme(), "http" | "https") && url.host_str().is_some())
            .ok_or_else(|| SourceError::Unsupported(format!("invalid source address: {api_url}")))?;
        Ok(Self { api })
    }

    fn endpoint(&self, segments: &[&str]) -> Url {
        let mut url = self.api.clone();
        url.set_query(None);
        if let Ok(mut path) = url.path_segments_mut() {
            path.pop_if_empty().extend(segments);
        }
        url
    }

    pub fn filter(&self) -> String {
        self.endpoint(&["filter"]).into()
    }

    pub fn latest(&self, page: u32) -> String {
        let mut url = self.endpoint(&["latest", "anime"]);
        url.query_pairs_mut().append_pair("page", &page.max(1).to_string());
        url.into()
    }

    pub fn anime(&self, slug: &str) -> Result<String, SourceError> {
        if !valid_slug(slug) {
            return Err(not_found("title", slug));
        }
        Ok(self.endpoint(&["anime", slug]).into())
    }

    pub fn episode(&self, slug: &str) -> Result<String, SourceError> {
        if !valid_slug(slug) {
            return Err(not_found("episode", slug));
        }
        Ok(self.endpoint(&["episode", slug]).into())
    }

    pub fn episodes(&self, id: &str, start: u32, end: u32) -> Result<String, SourceError> {
        if !valid_object_id(id) {
            return Err(not_found("title id", id));
        }
        let mut url = self.endpoint(&["episodes", id]);
        url.query_pairs_mut()
            .append_pair("start", &start.to_string())
            .append_pair("end", &end.to_string());
        Ok(url.into())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn urls() -> HianimeUrls {
        HianimeUrls::new("https://api.example.test/api").unwrap()
    }

    #[test]
    fn the_endpoints_hang_off_the_api_address() {
        assert_eq!(urls().filter(), "https://api.example.test/api/filter");
        assert_eq!(
            urls().latest(3),
            "https://api.example.test/api/latest/anime?page=3"
        );
        assert_eq!(
            urls().episodes("6ab63dce32e4b6276712b562", 1, 100).unwrap(),
            "https://api.example.test/api/episodes/6ab63dce32e4b6276712b562?start=1&end=100"
        );
    }

    #[test]
    fn a_trailing_slash_in_the_address_changes_nothing() {
        let urls = HianimeUrls::new("https://api.example.test/api/").unwrap();
        assert_eq!(urls.filter(), "https://api.example.test/api/filter");
    }

    #[test]
    fn page_zero_is_page_one() {
        assert!(urls().latest(0).ends_with("page=1"));
    }

    #[test]
    fn slugs_are_encoded_into_one_path_segment() {
        let anime = urls()
            .anime("steel-ball-run:-jojo's-bizarre-adventure-5ea2y3")
            .unwrap();
        assert!(anime.starts_with("https://api.example.test/api/anime/steel-ball-run"));
        assert!(!anime.contains(' '));
        assert_eq!(anime.matches('/').count(), 5);
        let episode = urls().episode("one-piece-episode-1-1m0d92").unwrap();
        assert_eq!(
            episode,
            "https://api.example.test/api/episode/one-piece-episode-1-1m0d92"
        );
    }

    #[test]
    fn a_slug_that_could_leave_its_segment_is_refused() {
        for bad in ["", "../admin", "a/b", "a?x=1", "a#b", "a%2fb", "a\\b", "a\nb"] {
            assert!(
                matches!(urls().anime(bad), Err(SourceError::NotFound(_))),
                "{bad:?}"
            );
            assert!(matches!(urls().episode(bad), Err(SourceError::NotFound(_))));
        }
        assert!(matches!(
            urls().anime(&"a".repeat(MAX_SLUG + 1)),
            Err(SourceError::NotFound(_))
        ));
    }

    #[test]
    fn only_a_real_object_id_names_an_episode_list() {
        for bad in ["", "123", "zzzzzzzzzzzzzzzzzzzzzzzz", "6ab63dce32e4b6276712b56g"] {
            assert!(matches!(
                urls().episodes(bad, 1, 100),
                Err(SourceError::NotFound(_))
            ));
        }
    }

    #[test]
    fn a_broken_api_address_is_refused() {
        for bad in ["", "not a url", "ftp://x.test/api", "mailto:a@b.c"] {
            assert!(matches!(
                HianimeUrls::new(bad),
                Err(SourceError::Unsupported(_))
            ));
        }
    }
}
