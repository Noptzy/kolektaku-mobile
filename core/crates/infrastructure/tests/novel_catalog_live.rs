use std::sync::Arc;

use application::ports::{Clock, MetadataCatalog};
use domain::media::{Discover, MediaFormat, MediaId, MediaKind, MediaListKind, MediaPage};
use infrastructure::catalog::anilist::AniListCatalog;
use infrastructure::clock::SystemClock;
use infrastructure::http::{
    HttpClient, RateLimitSettings, RateLimitedClient, ReqwestClient, SystemPause,
};

fn catalog() -> AniListCatalog {
    let transport = Arc::new(ReqwestClient::standard().unwrap());
    let limited: Arc<dyn HttpClient> = Arc::new(RateLimitedClient::new(
        transport,
        Arc::new(SystemPause),
        RateLimitSettings::default(),
    ));
    let clock: Arc<dyn Clock> = Arc::new(SystemClock);
    AniListCatalog::new(limited, clock)
}

fn assert_only(page: &MediaPage, kind: MediaKind, what: &str) {
    assert!(!page.items.is_empty(), "{what}: nothing came back");
    for item in &page.items {
        assert_eq!(item.kind, kind, "{what}: {}", item.title.romaji);
        assert_eq!(
            item.format == Some(MediaFormat::Novel),
            kind == MediaKind::Novel,
            "{what}: {}",
            item.title.romaji
        );
    }
}

#[tokio::test]
#[ignore = "talks to AniList"]
async fn comic_and_novel_lists_never_mix() {
    let catalog = catalog();
    for list in [MediaListKind::Popular, MediaListKind::Trending] {
        let comics = catalog.list(MediaKind::Manga, list, 1).await.unwrap();
        assert_only(&comics, MediaKind::Manga, "comic list");
        let novels = catalog.list(MediaKind::Novel, list, 1).await.unwrap();
        assert_only(&novels, MediaKind::Novel, "novel list");
    }
}

#[tokio::test]
#[ignore = "talks to AniList"]
async fn searching_keeps_the_two_apart() {
    let catalog = catalog();
    let comics = catalog
        .search(MediaKind::Manga, "overlord", 1)
        .await
        .unwrap();
    assert_only(&comics, MediaKind::Manga, "comic search");
    let novels = catalog
        .search(MediaKind::Novel, "overlord", 1)
        .await
        .unwrap();
    assert_only(&novels, MediaKind::Novel, "novel search");
}

#[tokio::test]
#[ignore = "talks to AniList"]
async fn discovering_keeps_the_two_apart() {
    let catalog = catalog();
    let filter = Discover::in_genre("Fantasy");
    let comics = catalog
        .discover(MediaKind::Manga, &filter, 1)
        .await
        .unwrap();
    assert_only(&comics, MediaKind::Manga, "comic discover");
    let novels = catalog
        .discover(MediaKind::Novel, &filter, 1)
        .await
        .unwrap();
    assert_only(&novels, MediaKind::Novel, "novel discover");
}

#[tokio::test]
#[ignore = "talks to AniList"]
async fn formats_are_read_for_a_mix_of_comics_and_novels() {
    let catalog = catalog();
    let novels = catalog
        .list(MediaKind::Novel, MediaListKind::Popular, 1)
        .await
        .unwrap();
    let comics = catalog
        .list(MediaKind::Manga, MediaListKind::Popular, 1)
        .await
        .unwrap();
    let novel_id: MediaId = novels.items[0].id;
    let comic_id: MediaId = comics.items[0].id;
    let found = catalog.comic_formats(&[novel_id, comic_id]).await.unwrap();
    let format_of = |id: MediaId| found.iter().find(|(known, _)| *known == id).unwrap().1;
    assert_eq!(format_of(novel_id), Some(MediaFormat::Novel));
    assert_ne!(format_of(comic_id), Some(MediaFormat::Novel));
}
