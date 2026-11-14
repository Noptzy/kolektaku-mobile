use std::sync::Arc;

use application::ports::MetadataCatalog;
use domain::media::{MediaId, MediaKind, MediaListKind, MediaStatus, RelationType, TrailerSite};
use infrastructure::catalog::anilist::AniListCatalog;
use infrastructure::clock::SystemClock;
use infrastructure::http::{RateLimitSettings, RateLimitedClient, ReqwestClient, SystemPause};

const DEMON_SLAYER: u64 = 101_922;
const MANGA_WITH_ANIME: u64 = 87_216;

fn catalog() -> AniListCatalog {
    let transport = Arc::new(ReqwestClient::standard().unwrap());
    let http = RateLimitedClient::new(
        transport,
        Arc::new(SystemPause),
        RateLimitSettings::default(),
    );
    AniListCatalog::new(Arc::new(http), Arc::new(SystemClock))
}

fn id(value: u64) -> MediaId {
    MediaId::new(value).unwrap()
}

#[tokio::test]
#[ignore = "live network"]
async fn anilist_detail_has_cast_voice_actors_trailer_relations_and_recommendations() {
    let detail = catalog()
        .detail(MediaKind::Anime, id(DEMON_SLAYER))
        .await
        .unwrap();
    assert_eq!(detail.summary.title.romaji, "Kimetsu no Yaiba");
    assert!(
        detail
            .characters
            .iter()
            .any(|character| !character.voice_actors.is_empty())
    );
    assert_eq!(
        detail.trailer.map(|trailer| trailer.site),
        Some(TrailerSite::Youtube)
    );
    assert!(!detail.relations.is_empty());
    assert!(!detail.recommendations.is_empty());
    assert!(!detail.studios.is_empty());
}

#[tokio::test]
#[ignore = "live network"]
async fn anilist_detail_of_an_airing_show_knows_its_next_episode() {
    let catalog = catalog();
    let seasonal = catalog
        .list(MediaKind::Anime, MediaListKind::Seasonal, 1)
        .await
        .unwrap();
    let airing = seasonal
        .items
        .iter()
        .find(|item| item.status == Some(MediaStatus::Releasing))
        .expect("an airing show this season");
    let detail = catalog.detail(MediaKind::Anime, airing.id).await.unwrap();
    assert!(detail.next_airing.is_none_or(|next| next.episode > 0));
}

#[tokio::test]
#[ignore = "live network"]
async fn anilist_manga_detail_links_to_its_anime_adaptation() {
    let detail = catalog()
        .detail(MediaKind::Manga, id(MANGA_WITH_ANIME))
        .await
        .unwrap();
    assert!(detail.relations.iter().any(|relation| {
        relation.relation_type == RelationType::Adaptation
            && relation.media.kind == MediaKind::Anime
    }));
}

#[tokio::test]
#[ignore = "live network"]
async fn anilist_anime_detail_links_to_its_manga_source() {
    let detail = catalog()
        .detail(MediaKind::Anime, id(DEMON_SLAYER))
        .await
        .unwrap();
    assert!(detail.relations.iter().any(|relation| {
        matches!(
            relation.relation_type,
            RelationType::Source | RelationType::Adaptation
        ) && relation.media.kind == MediaKind::Manga
    }));
}

#[tokio::test]
#[ignore = "live network"]
async fn anilist_lists_trending_seasonal_and_popular_items_of_the_right_kind() {
    let catalog = catalog();
    for (kind, list) in [
        (MediaKind::Anime, MediaListKind::Trending),
        (MediaKind::Anime, MediaListKind::Seasonal),
        (MediaKind::Manga, MediaListKind::Trending),
        (MediaKind::Manga, MediaListKind::Popular),
    ] {
        let page = catalog.list(kind, list, 1).await.unwrap();
        assert!(!page.items.is_empty(), "{kind:?}/{list:?}");
        assert!(page.items.iter().all(|item| item.kind == kind));
        assert!(page.items.iter().all(|item| !item.is_adult));
    }
}

#[tokio::test]
#[ignore = "live network"]
async fn anilist_answers_a_batch_of_titles_in_one_request() {
    let titles: Vec<String> = [
        "One Piece",
        "Oshi no Ko 2nd Season",
        "Spy x Family Code: White",
        "Shingeki no Kyojin: The Final Season Part 2",
    ]
    .iter()
    .map(|title| title.to_string())
    .collect();
    let matches = catalog()
        .match_titles(MediaKind::Anime, &titles)
        .await
        .unwrap();
    assert_eq!(matches.len(), titles.len());
    assert!(matches.iter().all(|candidates| !candidates.is_empty()));
}

#[tokio::test]
#[ignore = "live network"]
async fn anilist_search_finds_kimi_no_na_wa_by_its_spaced_spelling() {
    let page = catalog()
        .search(MediaKind::Anime, "kimi no na wa", 1)
        .await
        .unwrap();
    assert!(
        page.items
            .iter()
            .any(|item| item.title.romaji.starts_with("Kimi no Na wa"))
    );
}

#[tokio::test]
#[ignore = "live network"]
async fn anilist_detail_lists_episode_titles_with_thumbnails_for_licensed_anime() {
    let detail = catalog()
        .detail(MediaKind::Anime, id(DEMON_SLAYER))
        .await
        .unwrap();
    assert!(!detail.episodes.is_empty());
    let first = &detail.episodes[0];
    assert_eq!(first.number, 1.0);
    assert!(!first.title.is_empty());
    assert!(
        first
            .thumbnail_url
            .as_deref()
            .is_some_and(|url| url.starts_with("https://"))
    );
}
