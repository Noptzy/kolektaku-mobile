use std::sync::Arc;

use application::ports::SourceProvider;
use domain::error::SourceError;

use super::source::{KOMIKINDO_ID, KomikindoSource};
use crate::config::{Defaults, SourceSettings};
use crate::sources::registry::{Registration, SourceEnv};

pub const REGISTRATION: Registration = Registration {
    defaults: Defaults {
        id: KOMIKINDO_ID,
        base_url: "https://komikindo.ch",
        api_url: None,
        priority: 8,
        allowed_hosts: &["komikindo.ch", "*.komikindo.ch"],
    },
    build,
    #[cfg(test)]
    contract: super::contract::site,
};

fn build(
    env: &SourceEnv,
    settings: &SourceSettings,
) -> Result<Arc<dyn SourceProvider>, SourceError> {
    let source = KomikindoSource::new(
        env.http.clone(),
        env.clock.clone(),
        &settings.base_url,
        settings.priority,
    )?;
    Ok(Arc::new(source))
}
