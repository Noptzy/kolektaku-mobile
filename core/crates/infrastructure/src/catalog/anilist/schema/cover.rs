use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct RawCoverPage {
    pub media: Vec<RawCoverMedia>,
}

#[derive(Debug, Deserialize)]
pub struct RawCoverMedia {
    #[serde(rename = "coverImage")]
    pub cover_image: Option<RawCoverImage>,
}

#[derive(Debug, Deserialize)]
pub struct RawCoverImage {
    pub large: Option<String>,
}
