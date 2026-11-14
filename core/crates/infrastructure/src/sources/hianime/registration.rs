use std::sync::Arc;

use application::ports::SourceProvider;
use domain::error::SourceError;

use super::source::{HIANIME_ID, HianimeSource};
use crate::config::{Defaults, SourceSettings};
use crate::sources::registry::{Registration, SourceEnv};

pub const REGISTRATION: Registration = Registration {
    defaults: Defaults {
        id: HIANIME_ID,
        base_url: "https://hianimes.se",
        api_url: Some("https://animehot.cc/api"),
        priority: 2,
        allowed_hosts: &["hianimes.se", "*.hianimes.se", "animehot.cc", "*.animehot.cc"],
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
        .ok_or_else(|| SourceError::Unsupported("the data address is missing".into()))?;
    let source = HianimeSource::new(
        env.http.clone(),
        env.clock.clone(),
        api_url,
        settings.priority,
    )?;
    Ok(Arc::new(source))
}
