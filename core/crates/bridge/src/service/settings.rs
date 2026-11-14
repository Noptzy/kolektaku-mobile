use application::ports::MetadataCatalog;
use domain::media::MediaKind;
use domain::settings::AppSettings;
use domain::source::SourceId;

use crate::dto::settings::SettingsDto;
use crate::error::BridgeError;
use crate::state::AppState;

pub fn current<C: MetadataCatalog>(state: &AppState<C>) -> SettingsDto {
    SettingsDto::from(&state.settings.get())
}

fn is_anime_source<C: MetadataCatalog>(state: &AppState<C>, id: &str) -> bool {
    state
        .registry
        .get(&SourceId::new(id))
        .is_some_and(|source| source.info().kind == MediaKind::Anime)
}

pub async fn save<C: MetadataCatalog>(
    state: &AppState<C>,
    wanted: SettingsDto,
) -> Result<SettingsDto, BridgeError> {
    let mut settings = AppSettings::from(&wanted);
    if let Some(source) = &settings.anime_source
        && !is_anime_source(state, source.as_str())
    {
        settings.anime_source = None;
    }
    state
        .settings
        .save(state.library.as_ref(), settings)
        .await?;
    Ok(current(state))
}
