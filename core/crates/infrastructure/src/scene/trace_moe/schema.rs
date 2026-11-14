use serde::Deserialize;
use serde_json::Value;

#[derive(Debug, Deserialize)]
pub struct RawReply {
    #[serde(default)]
    pub error: Option<String>,
    #[serde(default)]
    pub quota: Option<u64>,
    #[serde(default, rename = "quotaUsed")]
    pub quota_used: Option<u64>,
    #[serde(default)]
    pub result: Vec<RawResult>,
}

#[derive(Debug, Deserialize)]
pub struct RawResult {
    pub anilist: RawAnilist,
    #[serde(default)]
    pub episode: Option<RawEpisode>,
    #[serde(default)]
    pub duration: Option<f64>,
    pub from: f64,
    #[serde(default)]
    pub at: Option<f64>,
    pub to: f64,
    pub similarity: f64,
    #[serde(default)]
    pub image: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(untagged)]
pub enum RawAnilist {
    Info(RawInfo),
    Id(u64),
}

#[derive(Debug, Deserialize)]
pub struct RawInfo {
    pub id: u64,
    #[serde(default)]
    pub title: Option<RawTitle>,
    #[serde(default, rename = "isAdult")]
    pub is_adult: bool,
}

#[derive(Debug, Deserialize)]
pub struct RawTitle {
    pub romaji: Option<String>,
    pub english: Option<String>,
    pub native: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(untagged)]
pub enum RawEpisode {
    Number(f64),
    Text(String),
    Other(Value),
}
