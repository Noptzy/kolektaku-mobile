use crate::dto::scene::{SceneFindingDto, SceneMatchDto, SceneTargetDto};
use crate::error::BridgeError;
use crate::service::scene;
use crate::state::global;

pub async fn find_scene(image: Vec<u8>) -> Result<SceneFindingDto, BridgeError> {
    scene::find_scene(global()?, image).await
}

pub async fn open_scene(scene: SceneMatchDto) -> Result<SceneTargetDto, BridgeError> {
    scene::open_scene(global()?, &scene).await
}
