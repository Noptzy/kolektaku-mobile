use domain::error::SourceError;
use domain::scene::SceneReply;
use serde::Deserialize;

pub const QUOTA_ENDPOINT: &str = "https://api.trace.moe/me";

#[derive(Debug, Deserialize)]
struct RawQuota {
    #[serde(default)]
    quota: Option<u64>,
    #[serde(default, rename = "quotaUsed")]
    quota_used: Option<u64>,
}

pub fn read_quota(body: &str) -> Result<u32, SourceError> {
    let raw: RawQuota = serde_json::from_str(body)
        .map_err(|error| SourceError::MarkupChanged(format!("trace.moe quota: {error}")))?;
    SceneReply::quota_from(raw.quota, raw.quota_used)
        .ok_or_else(|| SourceError::MarkupChanged("trace.moe quota: numbers missing".into()))
}
