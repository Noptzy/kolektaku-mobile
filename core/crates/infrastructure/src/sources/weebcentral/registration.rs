use std::sync::Arc;

use application::ports::SourceProvider;
use domain::error::SourceError;

use super::source::{WEEBCENTRAL_ID, WeebCentralSource};
use crate::config::{Defaults, SourceSettings};
use crate::sources::registry::{Registration, SourceEnv};

pub const REGISTRATION: Registration = Registration {
    defaults: Defaults {
        id: WEEBCENTRAL_ID,
        base_url: "https://weebcentral.com",
        api_url: None,
        priority: 9,
        allowed_hosts: &["weebcentral.com", "*.weebcentral.com"],
    },
    build,
    #[cfg(test)]
    contract: super::contract::site,
};

fn build(
    env: &SourceEnv,
    settings: &SourceSettings,
) -> Result<Arc<dyn SourceProvider>, SourceError> {
    let source = WeebCentralSource::new(
        env.http.clone(),
        env.clock.clone(),
        &settings.base_url,
        settings.priority,
    )?;
    Ok(Arc::new(source))
}
