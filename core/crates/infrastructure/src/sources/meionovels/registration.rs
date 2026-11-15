use std::sync::Arc;

use application::ports::SourceProvider;
use domain::error::SourceError;

use super::source::{MEIONOVELS_ID, MeionovelsSource};
use crate::config::{Defaults, SourceSettings};
use crate::sources::registry::{Registration, SourceEnv};

pub const REGISTRATION: Registration = Registration {
    defaults: Defaults {
        id: MEIONOVELS_ID,
        base_url: "https://meionovels.com",
        api_url: None,
        priority: 5,
        allowed_hosts: &["meionovels.com", "*.meionovels.com"],
    },
    build,
    #[cfg(test)]
    contract: super::contract::site,
};

fn build(
    env: &SourceEnv,
    settings: &SourceSettings,
) -> Result<Arc<dyn SourceProvider>, SourceError> {
    let source = MeionovelsSource::new(
        env.http.clone(),
        env.clock.clone(),
        &settings.base_url,
        settings.priority,
    )?;
    Ok(Arc::new(source))
}
