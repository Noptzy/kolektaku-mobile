use std::sync::Arc;

use application::ports::SourceProvider;
use domain::error::SourceError;

use super::source::{KOMIKU_ID, KomikuSource};
use crate::config::{Defaults, SourceSettings};
use crate::sources::registry::{Registration, SourceEnv};

pub const REGISTRATION: Registration = Registration {
    defaults: Defaults {
        id: KOMIKU_ID,
        base_url: "https://komiku.org",
        api_url: Some("https://api.komiku.org"),
        priority: 5,
        allowed_hosts: &["komiku.org", "*.komiku.org"],
    },
    build,
    #[cfg(test)]
    contract: super::contract::site,
};

fn build(
    env: &SourceEnv,
    settings: &SourceSettings,
) -> Result<Arc<dyn SourceProvider>, SourceError> {
    let api_url = settings
        .api_url
        .as_deref()
        .ok_or_else(|| SourceError::Unsupported("the listing address is missing".into()))?;
    let source = KomikuSource::new(
        env.http.clone(),
        env.clock.clone(),
        &settings.base_url,
        api_url,
        settings.priority,
    )?;
    Ok(Arc::new(source))
}
