use domain::error::SourceError;
use domain::source::SourceOrder;
use url::Url;

use crate::sources::support::is_slug;

const SLUG_EXTRA: [char; 3] = ['.', '_', '%'];

#[derive(Debug, Clone)]
pub struct KomikindoUrls {
    base: Url,
}

fn order_value(order: SourceOrder) -> &'static str {
    match order {
        SourceOrder::Newest | SourceOrder::Oldest => "update",
        SourceOrder::Az => "title",
        SourceOrder::Za => "titlereverse",
    }
}

fn not_found(what: &str, value: &str) -> SourceError {
    SourceError::NotFound(format!("not a valid {what}: {value}"))
}

impl KomikindoUrls {
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

    pub fn latest(&self, page: u32) -> String {
        self.page_path("/komik-terbaru", page)
    }

    pub fn search(&self, query: &str) -> String {
        let mut url = self.base.clone();
        url.set_path("/");
        url.query_pairs_mut().clear().append_pair("s", query.trim());
        url.into()
    }

    pub fn genres(&self) -> String {
        self.page_path("/daftar-manga", 1)
    }

    pub fn genre(&self, slug: &str, page: u32, order: SourceOrder) -> Result<String, SourceError> {
        if !is_slug(slug, &SLUG_EXTRA) {
            return Err(not_found("genre", slug));
        }
        let mut url = Url::parse(&self.page_path("/daftar-manga", page))
            .map_err(|_| not_found("genre", slug))?;
        url.query_pairs_mut()
            .append_pair("genre[]", &slug.to_lowercase())
            .append_pair("order", order_value(order));
        Ok(url.into())
    }

    pub fn detail(&self, id: &str) -> Result<String, SourceError> {
        if !is_slug(id, &SLUG_EXTRA) {
            return Err(not_found("title id", id));
        }
        Ok(self.plain(&format!("/komik/{id}/")))
    }

    pub fn chapter(&self, id: &str) -> Result<String, SourceError> {
        if !is_slug(id, &SLUG_EXTRA) {
            return Err(not_found("chapter id", id));
        }
        Ok(self.plain(&format!("/{id}/")))
    }

    fn page_path(&self, path: &str, page: u32) -> String {
        if page > 1 {
            self.plain(&format!("{path}/page/{page}/"))
        } else {
            self.plain(&format!("{path}/"))
        }
    }

    fn plain(&self, path: &str) -> String {
        let mut url = self.base.clone();
        url.set_path(path);
        url.set_query(None);
        url.into()
    }
}
