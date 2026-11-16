use std::sync::Arc;

use application::ports::SourceProvider;
use domain::error::SourceError;

use super::source::{BAKATSUKI_ID, BakaTsukiSource};
use crate::config::{Defaults, SourceSettings};
use crate::sources::registry::{Registration, SourceEnv};

pub const REGISTRATION: Registration = Registration {
    defaults: Defaults {
        id: BAKATSUKI_ID,
        base_url: "https://www.baka-tsuki.org",
        api_url: None,
        priority: 10,
        allowed_hosts: &["baka-tsuki.org", "*.baka-tsuki.org"],
    },
    build,
    #[cfg(test)]
    contract: super::contract::site,
};

fn build(
    env: &SourceEnv,
    settings: &SourceSettings,
) -> Result<Arc<dyn SourceProvider>, SourceError> {
    let source = BakaTsukiSource::new(
        env.http.clone(),
        env.clock.clone(),
        &settings.base_url,
        settings.priority,
    )?;
    Ok(Arc::new(source))
}
