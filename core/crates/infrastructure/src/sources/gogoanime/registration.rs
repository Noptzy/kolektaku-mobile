use std::sync::Arc;

use application::ports::SourceProvider;
use domain::error::SourceError;

use super::source::{GOGOANIME_ID, GogoanimeSource};
use crate::config::{Defaults, SourceSettings};
use crate::sources::registry::{Registration, SourceEnv};

pub const REGISTRATION: Registration = Registration {
    defaults: Defaults {
        id: GOGOANIME_ID,
        base_url: "https://gogoanime.or.at",
        api_url: None,
        priority: 3,
        allowed_hosts: &[
            "gogoanime.or.at",
            "*.gogoanime.or.at",
            "gogoanime.me.uk",
            "*.gogoanime.me.uk",
            "megaplay.buzz",
            "*.megaplay.buzz",
            "vidwish.live",
            "*.vidwish.live",
        ],
    },
    build,
    #[cfg(test)]
    contract: super::contract::site,
};

fn build(
    env: &SourceEnv,
    settings: &SourceSettings,
) -> Result<Arc<dyn SourceProvider>, SourceError> {
    let source = GogoanimeSource::new(
        env.http.clone(),
        env.clock.clone(),
        &settings.base_url,
        settings.priority,
    )?;
    Ok(Arc::new(source))
}
