use application::detail::MediaViewer;
use application::ports::MetadataCatalog;
use application::scene::{FindScene, OpenScene};
use domain::media::MediaKind;

use crate::dto::scene::{SceneFindingDto, SceneMatchDto, SceneTargetDto};
use crate::error::BridgeError;
use crate::state::AppState;

pub async fn find_scene<C: MetadataCatalog>(
    state: &AppState<C>,
    image: Vec<u8>,
) -> Result<SceneFindingDto, BridgeError> {
    let finder = FindScene::new(state.scene.clone());
    Ok(SceneFindingDto::from(&finder.execute(image).await?))
}

pub async fn open_scene<C: MetadataCatalog + 'static>(
    state: &AppState<C>,
    scene: &SceneMatchDto,
) -> Result<SceneTargetDto, BridgeError> {
    let resolver = std::sync::Arc::new(state.resolver(MediaKind::Anime));
    let viewer = MediaViewer::new(state.catalog.clone(), resolver, state.directory.clone());
    let target = OpenScene::new(std::sync::Arc::new(viewer))
        .execute(&scene.into_domain()?)
        .await?;
    Ok(SceneTargetDto::from(&target))
}
