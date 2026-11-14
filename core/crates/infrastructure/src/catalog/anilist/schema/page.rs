use serde::Deserialize;

use super::detail::RawDetail;
use super::summary::RawSummary;

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RawPageInfo {
    pub current_page: Option<u32>,
    pub has_next_page: Option<bool>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RawPage {
    pub page_info: Option<RawPageInfo>,
    pub media: Vec<RawSummary>,
}

#[derive(Debug, Deserialize)]
pub struct RawListResponse {
    #[serde(rename = "Page")]
    pub page: RawPage,
}

#[derive(Debug, Deserialize)]
pub struct RawDetailResponse {
    #[serde(rename = "Media")]
    pub media: RawDetail,
}

#[derive(Debug, Deserialize)]
pub struct RawBatchPage {
    pub media: Vec<RawSummary>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_page_without_page_info_is_accepted() {
        let json = r#"{"Page":{"media":[]}}"#;
        let response: RawListResponse = serde_json::from_str(json).unwrap();
        assert!(response.page.page_info.is_none());
    }

    #[test]
    fn a_page_whose_items_have_the_wrong_shape_is_rejected() {
        let json = r#"{"Page":{"media":[{"id":"x"}]}}"#;
        assert!(serde_json::from_str::<RawListResponse>(json).is_err());
    }
}
