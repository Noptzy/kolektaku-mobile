use domain::error::SourceError;
use url::Url;

use crate::sources::support::is_slug;

const SLUG_EXTRA: [char; 3] = ['.', '_', '%'];

#[derive(Debug, Clone)]
pub struct MeionovelsUrls {
    base: Url,
}

fn not_found(what: &str, value: &str) -> SourceError {
    SourceError::NotFound(format!("not a valid {what}: {value}"))
}

impl MeionovelsUrls {
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
        let path = match page {
            0 | 1 => "/novel/".to_string(),
            number => format!("/novel/page/{number}/"),
        };
        let mut url = self.at(&path);
        url.query_pairs_mut().append_pair("m_orderby", "latest");
        url.into()
    }

    pub fn search(&self, query: &str) -> String {
        let mut url = self.at("/");
        url.query_pairs_mut()
            .append_pair("s", query.trim())
            .append_pair("post_type", "wp-manga");
        url.into()
    }

    pub fn detail(&self, slug: &str) -> Result<String, SourceError> {
        self.checked(slug, "title id")?;
        Ok(self.at(&format!("/novel/{slug}/")).into())
    }

    pub fn chapter_list(&self, slug: &str) -> Result<String, SourceError> {
        self.checked(slug, "title id")?;
        Ok(self.at(&format!("/novel/{slug}/ajax/chapters/")).into())
    }

    pub fn chapter(&self, id: &str) -> Result<String, SourceError> {
        let (slug, chapter) = id
            .split_once('/')
            .ok_or_else(|| not_found("chapter id", id))?;
        self.checked(slug, "chapter id")?;
        for segment in chapter.split('/') {
            self.checked(segment, "chapter id")?;
        }
        Ok(self.at(&format!("/novel/{slug}/{chapter}/")).into())
    }

    fn checked(&self, part: &str, what: &str) -> Result<(), SourceError> {
        if is_slug(part, &SLUG_EXTRA) {
            Ok(())
        } else {
            Err(not_found(what, part))
        }
    }
}
