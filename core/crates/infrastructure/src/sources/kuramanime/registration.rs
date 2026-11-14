use std::sync::Arc;

use application::ports::SourceProvider;
use domain::error::SourceError;

use super::source::{KURAMANIME_ID, KuramanimeSource};
use crate::config::{Defaults, SourceSettings};
use crate::sources::registry::{Registration, SourceEnv};

pub const REGISTRATION: Registration = Registration {
    defaults: Defaults {
        id: KURAMANIME_ID,
        base_url: "https://v20.kuramanime.ing",
        api_url: None,
        priority: 1,
        allowed_hosts: &["kuramanime.ing", "*.kuramanime.ing"],
    },
    build,
    #[cfg(test)]
    contract: super::contract::site,
};

fn build(
    env: &SourceEnv,
    settings: &SourceSettings,
) -> Result<Arc<dyn SourceProvider>, SourceError> {
    let source = KuramanimeSource::new(
        env.http.clone(),
        env.clock.clone(),
        &settings.base_url,
        settings.priority,
    )?;
    Ok(Arc::new(source))
}
