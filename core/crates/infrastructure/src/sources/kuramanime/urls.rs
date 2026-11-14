use domain::error::SourceError;
use domain::source::SourceOrder;
use url::Url;

use super::ids::{IdShape, id_shape, is_genre_slug};

#[derive(Debug, Clone)]
pub struct KuramanimeUrls {
    base: Url,
}

fn order_value(order: SourceOrder) -> &'static str {
    match order {
        SourceOrder::Newest => "latest",
        SourceOrder::Oldest => "oldest",
        SourceOrder::Az => "ascending",
        SourceOrder::Za => "descending",
    }
}

impl KuramanimeUrls {
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

    pub fn host(&self) -> String {
        self.base.host_str().unwrap_or_default().to_string()
    }

    pub fn latest(&self, page: u32) -> String {
        self.with_query(
            "/quick/ongoing",
            &[("order_by", "updated"), ("page", &page.to_string())],
        )
    }

    pub fn search(&self, query: &str, page: u32, order: SourceOrder) -> String {
        self.with_query(
            "/anime",
            &[
                ("search", query.trim()),
                ("order_by", order_value(order)),
                ("page", &page.to_string()),
            ],
        )
    }

    pub fn genres(&self) -> String {
        self.with_query("/properties/genre", &[("order_by", "ascending")])
    }

    pub fn genre(&self, slug: &str, page: u32, order: SourceOrder) -> Result<String, SourceError> {
        if !is_genre_slug(slug) {
            return Err(SourceError::NotFound(format!("genre {slug}")));
        }
        let path = format!("/properties/genre/{}", slug.to_lowercase());
        Ok(self.with_query(
            &path,
            &[
                ("order_by", order_value(order)),
                ("page", &page.to_string()),
            ],
        ))
    }

    pub fn detail(&self, id: &str, episode_page: u32) -> Result<String, SourceError> {
        self.checked(id, IdShape::Anime)?;
        let mut url = self.base.join(&format!("/anime/{id}")).map_err(invalid)?;
        if episode_page > 1 {
            url.query_pairs_mut()
                .append_pair("page", &episode_page.to_string());
        }
        Ok(url.into())
    }

    pub fn episode(&self, id: &str) -> Result<String, SourceError> {
        self.checked(id, IdShape::Episode)?;
        Ok(self
            .base
            .join(&format!("/anime/{id}"))
            .map_err(invalid)?
            .into())
    }

    fn checked(&self, id: &str, wanted: IdShape) -> Result<(), SourceError> {
        if id_shape(id) == Some(wanted) {
            Ok(())
        } else {
            Err(SourceError::NotFound(format!(
                "not a valid source id: {id}"
            )))
        }
    }

    fn with_query(&self, path: &str, pairs: &[(&str, &str)]) -> String {
        let mut url = self.base.clone();
        url.set_path(path);
        url.query_pairs_mut().clear().extend_pairs(pairs);
        url.into()
    }
}

fn invalid(error: url::ParseError) -> SourceError {
    SourceError::NotFound(format!("not a valid source address: {error}"))
}
