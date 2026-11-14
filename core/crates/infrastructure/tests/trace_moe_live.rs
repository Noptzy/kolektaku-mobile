use std::sync::Arc;

use application::ports::SceneSearch;
use infrastructure::http::{ReqwestClient, SystemPause};
use infrastructure::scene::trace_moe::TraceMoeSceneSearch;

const OFFICIAL_SAMPLE: &str = "https://images.plurk.com/32B15UXxymfSMwKGTObY5e.jpg";
const GOCHUUMON_SEASON_TWO: u64 = 21_034;

async fn sample_image() -> Vec<u8> {
    let _ = rustls::crypto::ring::default_provider().install_default();
    reqwest::get(OFFICIAL_SAMPLE)
        .await
        .unwrap()
        .bytes()
        .await
        .unwrap()
        .to_vec()
}

#[tokio::test]
#[ignore = "live network, uses one of the 100 daily searches"]
async fn the_official_sample_image_is_gochuumon_season_two_episode_one() {
    let http = Arc::new(ReqwestClient::new(std::time::Duration::from_secs(60)).unwrap());
    let search = TraceMoeSceneSearch::new(http, Arc::new(SystemPause));
    let reply = search.find(sample_image().await).await.unwrap();
    let best = &reply.matches[0];
    assert_eq!(best.media_id.get(), GOCHUUMON_SEASON_TWO);
    assert_eq!(best.episode, Some(1.0));
    assert!(best.similarity > 0.95);
    assert!((best.at_secs - 279.78).abs() < 1.0);
    assert!(reply.quota_left.is_some());
}
