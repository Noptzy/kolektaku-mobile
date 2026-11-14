use domain::error::SourceError;
use domain::source::SourceOrder;
use url::Url;

use crate::sources::support::is_slug;

const SLUG_EXTRA: [char; 2] = ['.', '_'];

#[derive(Debug, Clone)]
pub struct KomikuUrls {
    site: Url,
    api: Url,
}

fn order_pairs(order: SourceOrder) -> &'static [(&'static str, &'static str)] {
    match order {
        SourceOrder::Newest => &[("orderby", "modified")],
        SourceOrder::Oldest => &[("orderby", "modified"), ("order", "asc")],
        SourceOrder::Az => &[("orderby", "title"), ("order", "asc")],
        SourceOrder::Za => &[("orderby", "title"), ("order", "desc")],
    }
}

fn web_address(text: &str) -> Result<Url, SourceError> {
    Url::parse(text)
        .ok()
        .filter(|url| matches!(url.scheme(), "http" | "https") && url.host_str().is_some())
        .ok_or_else(|| SourceError::Unsupported(format!("invalid source address: {text}")))
}

fn not_found(what: &str, value: &str) -> SourceError {
    SourceError::NotFound(format!("not a valid {what}: {value}"))
}

impl KomikuUrls {
    pub fn new(site_url: &str, api_url: &str) -> Result<Self, SourceError> {
        Ok(Self {
            site: web_address(site_url)?,
            api: web_address(api_url)?,
        })
    }

    pub fn site(&self) -> &Url {
        &self.site
    }

    pub fn latest(&self, page: u32) -> String {
        self.listing("/manga", page, SourceOrder::Newest)
    }

    pub fn search(&self, query: &str, order: SourceOrder) -> String {
        let mut url = self.api.clone();
        url.set_path("/");
        {
            let mut pairs = url.query_pairs_mut();
            pairs.clear();
            pairs.append_pair("post_type", "manga");
            pairs.append_pair("s", query.trim());
            if order != SourceOrder::Newest {
                pairs.extend_pairs(order_pairs(order));
            }
        }
        url.into()
    }

    pub fn genres(&self) -> String {
        self.site_page("/genre/action/")
    }

    pub fn genre(&self, slug: &str, page: u32, order: SourceOrder) -> Result<String, SourceError> {
        if !is_slug(slug, &[]) {
            return Err(not_found("genre", slug));
        }
        Ok(self.listing(&format!("/genre/{}", slug.to_lowercase()), page, order))
    }

    pub fn detail(&self, id: &str) -> Result<String, SourceError> {
        if !is_slug(id, &SLUG_EXTRA) {
            return Err(not_found("title id", id));
        }
        Ok(self.site_page(&format!("/manga/{id}/")))
    }

    pub fn chapter(&self, id: &str) -> Result<String, SourceError> {
        if !is_slug(id, &SLUG_EXTRA) {
            return Err(not_found("chapter id", id));
        }
        Ok(self.site_page(&format!("/{id}/")))
    }

    fn site_page(&self, path: &str) -> String {
        let mut url = self.site.clone();
        url.set_path(path);
        url.set_query(None);
        url.into()
    }

    fn listing(&self, path: &str, page: u32, order: SourceOrder) -> String {
        let mut url = self.api.clone();
        let full_path = if page > 1 {
            format!("{path}/page/{page}/")
        } else {
            format!("{path}/")
        };
        url.set_path(&full_path);
        url.query_pairs_mut()
            .clear()
            .extend_pairs(order_pairs(order));
        url.into()
    }
}
