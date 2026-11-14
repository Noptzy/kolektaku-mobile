use std::sync::Arc;

use application::ports::MetadataCatalog;
use domain::media::{MediaId, MediaKind};
use infrastructure::catalog::anilist::AniListCatalog;
use infrastructure::clock::SystemClock;
use infrastructure::http::{RateLimitSettings, RateLimitedClient, ReqwestClient, SystemPause};

fn catalog() -> AniListCatalog {
    let transport = Arc::new(ReqwestClient::standard().unwrap());
    let http = RateLimitedClient::new(
        transport,
        Arc::new(SystemPause),
        RateLimitSettings::default(),
    );
    AniListCatalog::new(Arc::new(http), Arc::new(SystemClock))
}

async fn titles_of(id: u64) -> Vec<(f64, String, bool)> {
    let detail = catalog()
        .detail(MediaKind::Anime, MediaId::new(id).unwrap())
        .await
        .unwrap();
    detail
        .episodes
        .into_iter()
        .map(|item| (item.number, item.title, item.thumbnail_url.is_some()))
        .collect()
}

#[tokio::test]
#[ignore = "live network"]
async fn a_current_season_title_the_catalog_has_no_episodes_for_gets_names_from_the_other_catalog()
{
    let episodes = titles_of(180_136).await;
    println!("{:?}", &episodes[..episodes.len().min(3)]);
    assert!(episodes.len() >= 3);
    assert_eq!(episodes[0].0, 1.0);
    assert!(!episodes[0].1.is_empty());
}

#[tokio::test]
#[ignore = "live network"]
async fn a_season_whose_catalog_list_belongs_to_another_season_gets_its_own_titles() {
    let episodes = titles_of(142_329).await;
    println!("{:?}", &episodes[..episodes.len().min(3)]);
    assert!(episodes.len() >= 11);
    assert!(episodes.iter().all(|(_, title, _)| title != "Cruelty"));
}

#[tokio::test]
#[ignore = "live network"]
async fn a_season_the_catalog_lists_correctly_keeps_its_pictures() {
    let episodes = titles_of(101_922).await;
    assert!(episodes.len() >= 26);
    assert!(episodes.iter().any(|(_, _, picture)| *picture));
}
