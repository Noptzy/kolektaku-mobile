use std::sync::Arc;

use application::ports::{MetadataCatalog, SourceProvider};
use domain::media::MediaKind;
use infrastructure::catalog::anilist::AniListCatalog;
use infrastructure::clock::SystemClock;
use infrastructure::http::{RateLimitSettings, RateLimitedClient, ReqwestClient, SystemPause};
use infrastructure::sources::komiku::KomikuSource;
use infrastructure::sources::kuramanime::KuramanimeSource;

fn catalog() -> AniListCatalog {
    let transport = Arc::new(ReqwestClient::standard().unwrap());
    let http = RateLimitedClient::new(
        transport,
        Arc::new(SystemPause),
        RateLimitSettings::default(),
    );
    AniListCatalog::new(Arc::new(http), Arc::new(SystemClock))
}

#[tokio::test]
#[ignore = "live network"]
async fn every_real_anime_site_genre_gets_a_cover_request_that_succeeds() {
    let transport = Arc::new(ReqwestClient::standard().unwrap());
    let site = KuramanimeSource::new(
        transport,
        Arc::new(SystemClock),
        "https://v20.kuramanime.ing",
        1,
    )
    .unwrap();
    let names: Vec<String> = site
        .genres()
        .await
        .unwrap()
        .into_iter()
        .map(|genre| genre.name)
        .collect();
    println!("{} genres: {names:?}", names.len());
    let result = catalog().genre_covers(MediaKind::Anime, &names).await;
    match result {
        Ok(found) => {
            for (name, covers) in names.iter().zip(&found) {
                println!("{name:<22} {}", covers.len());
            }
        }
        Err(error) => panic!("cover request failed: {error:?}"),
    }
}

#[tokio::test]
#[ignore = "live network"]
async fn every_real_manga_site_genre_gets_a_cover_request_that_succeeds() {
    let http = Arc::new(ReqwestClient::standard().unwrap());
    let site = KomikuSource::new(
        http,
        Arc::new(SystemClock),
        "https://komiku.org",
        "https://api.komiku.org",
        5,
    )
    .unwrap();
    let names: Vec<String> = site
        .genres()
        .await
        .unwrap()
        .into_iter()
        .map(|genre| genre.name)
        .collect();
    println!("{} genres", names.len());
    let found = catalog()
        .genre_covers(MediaKind::Manga, &names)
        .await
        .unwrap();
    let empty: Vec<&String> = names
        .iter()
        .zip(&found)
        .filter(|(_, covers)| covers.is_empty())
        .map(|(name, _)| name)
        .collect();
    println!("without cover: {empty:?}");
}
