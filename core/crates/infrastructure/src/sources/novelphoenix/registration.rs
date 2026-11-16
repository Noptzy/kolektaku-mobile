use std::sync::Arc;

use application::ports::SourceProvider;
use domain::error::SourceError;

use super::source::{NOVELPHOENIX_ID, NovelPhoenixSource};
use crate::config::{Defaults, SourceSettings};
use crate::sources::registry::{Registration, SourceEnv};

pub const REGISTRATION: Registration = Registration {
    defaults: Defaults {
        id: NOVELPHOENIX_ID,
        base_url: "https://novelphoenix.com",
        api_url: None,
        priority: 6,
        allowed_hosts: &["novelphoenix.com", "*.novelphoenix.com"],
    },
    build,
    #[cfg(test)]
    contract: super::contract::site,
};

fn build(
    env: &SourceEnv,
    settings: &SourceSettings,
) -> Result<Arc<dyn SourceProvider>, SourceError> {
    let source = NovelPhoenixSource::new(
        env.http.clone(),
        env.clock.clone(),
        &settings.base_url,
        settings.priority,
    )?;
    Ok(Arc::new(source))
}
