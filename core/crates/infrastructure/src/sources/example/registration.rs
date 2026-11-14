use std::sync::Arc;

use application::ports::SourceProvider;
use domain::error::SourceError;

use super::source::{EXAMPLE_ID, ExampleSource};
use crate::config::{Defaults, SourceSettings};
use crate::sources::registry::{Registration, SourceEnv};

pub const REGISTRATION: Registration = Registration {
    defaults: Defaults {
        id: EXAMPLE_ID,
        base_url: "https://example.test",
        api_url: None,
        priority: 9,
        allowed_hosts: &["example.test"],
    },
    build,
    #[cfg(test)]
    contract: super::contract::site,
};

fn build(
    env: &SourceEnv,
    settings: &SourceSettings,
) -> Result<Arc<dyn SourceProvider>, SourceError> {
    let source = ExampleSource::new(
        env.http.clone(),
        env.clock.clone(),
        &settings.base_url,
        settings.priority,
    )?;
    Ok(Arc::new(source))
}
