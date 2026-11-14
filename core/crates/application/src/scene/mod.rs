mod find_scene;
mod open_scene;

#[cfg(test)]
mod find_scene_tests;
#[cfg(test)]
mod open_scene_tests;

pub use find_scene::{
    CANDIDATE_SIMILARITY, DIRECT_SIMILARITY, FindScene, MAX_CANDIDATES, SceneFinding, SceneOutcome,
};
pub use open_scene::{DetailReason, OpenScene, SceneTarget};
