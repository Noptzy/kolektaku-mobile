use super::service_support::{Folder, catalog_ref, state};
use super::{browse, detail, people, play};
use crate::dto::discover::{DiscoverFilterDto, DiscoverSortDto};
use crate::dto::media::{MediaKindDto, MediaRefDto};
use crate::dto::profile::ProfileKindDto;
use crate::dto::stream::StreamPlanKind;
use crate::error::BridgeErrorKind;

#[tokio::test]
async fn home_maps_sections_cards_and_the_latest_from_sites() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let home = browse::home(&state, MediaKindDto::Anime).await.unwrap();
    let ids: Vec<&str> = home
        .sections
        .iter()
        .map(|section| section.id.as_str())
        .collect();
    assert_eq!(ids, vec!["trending", "seasonal", "popular", "latest"]);
    assert_eq!(home.sections[0].cards[0].title, "Spy x Family");
    assert_eq!(home.sections[0].cards[0].format.as_deref(), Some("TV"));
    assert!(home.sections[1].cards.is_empty());
    assert_eq!(home.sections[3].cards[0].sources, vec!["a"]);
}

#[tokio::test]
async fn genre_covers_follow_the_asked_genres_and_skip_those_without_a_cover() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let genres = vec!["Action".to_string(), "Award Winning".to_string()];
    let covers = browse::genre_covers(&state, MediaKindDto::Anime, &genres)
        .await
        .unwrap();
    let names: Vec<&str> = covers.iter().map(|cover| cover.genre.as_str()).collect();
    assert_eq!(names, vec!["Action"]);
    assert_eq!(covers[0].cover_url, "https://img.test/action.jpg");
}

#[tokio::test]
async fn search_returns_catalog_cards_with_their_site_links() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let page = browse::search(&state, MediaKindDto::Anime, "spy x family", 1)
        .await
        .unwrap();
    assert_eq!(page.cards.len(), 1);
    assert_eq!(page.cards[0].reference, catalog_ref());
    assert_eq!(page.cards[0].sources, vec!["a"]);
}

#[tokio::test]
async fn detail_and_units_follow_the_resolved_source() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let view = detail::media_detail(&state, MediaKindDto::Anime, &catalog_ref())
        .await
        .unwrap()
        .catalog
        .expect("expected the catalog view");
    let (shown, sources, resolve_error) = (view.detail, view.sources, view.resolve_error);
    assert_eq!(shown.summary.title_romaji, "Spy x Family");
    assert_eq!(sources.len(), 1);
    assert_eq!(
        (sources[0].source.as_str(), sources[0].source_name.as_str()),
        ("a", "a")
    );
    assert!(resolve_error.is_none());
    let units = detail::units(&state, &catalog_ref(), None).await.unwrap();
    assert_eq!(units.source, "a");
    assert_eq!(units.units.len(), 2);
}

#[tokio::test]
async fn a_site_only_reference_opens_with_limited_data() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let target = MediaRefDto::site("a", "a-spy");
    let view = detail::media_detail(&state, MediaKindDto::Anime, &target)
        .await
        .unwrap();
    assert!(view.site.is_some() && view.catalog.is_none());
}

#[tokio::test]
async fn an_invalid_reference_is_not_found() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let error = detail::media_detail(&state, MediaKindDto::Anime, &MediaRefDto::catalog(0))
        .await
        .unwrap_err();
    assert_eq!(error.kind, BridgeErrorKind::NotFound);
}

#[tokio::test]
async fn an_episode_opens_with_servers_then_a_plan_and_a_payload() {
    let folder = Folder::new();
    let state = state(&folder).await;
    detail::media_detail(&state, MediaKindDto::Anime, &catalog_ref())
        .await
        .unwrap();
    let playback = play::open_episode(&state, &catalog_ref(), 1.0, None, Vec::new())
        .await
        .unwrap();
    assert_eq!(playback.source, "a");
    assert_eq!(playback.unit.id, "a-ep-1");
    assert_eq!(playback.servers[0].id, "main");
    let plan = play::stream_plan(&state, "a", "a-ep-1".into(), "main".into())
        .await
        .unwrap();
    assert_eq!(plan.kind, StreamPlanKind::NeedsWebView);
    let set = play::parse_stream_payload(
        &state,
        "a",
        "https://cdn.test/v-720.mp4@720;https://cdn.test/v-480.mp4@480",
    )
    .unwrap();
    assert_eq!(set.sources[0].quality, 720);
}

#[tokio::test]
async fn a_profile_opens_with_its_titles_and_unknown_ids_are_not_found() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let found = people::profile(&state, ProfileKindDto::Character, 127518)
        .await
        .unwrap();
    assert_eq!(found.name, "Nezuko Kamado");
    assert_eq!(found.appearances[0].media.title_romaji, "Spy x Family");
    let missing = people::profile(&state, ProfileKindDto::Staff, 1)
        .await
        .unwrap_err();
    assert_eq!(missing.kind, BridgeErrorKind::NotFound);
}

#[tokio::test]
async fn discovering_by_genre_and_year_returns_catalog_cards() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let request = DiscoverFilterDto {
        genre: Some("Action".into()),
        year_from: Some(2015),
        year_to: Some(2015),
        formats: vec!["TV".into()],
        status: Some("FINISHED".into()),
        origin: Some("MANGA".into()),
        sort: DiscoverSortDto::Newest,
        ..DiscoverFilterDto::default()
    };
    let page = browse::discover(&state, MediaKindDto::Anime, request, 1)
        .await
        .unwrap();
    assert_eq!(page.cards.len(), 1);
    assert_eq!(page.cards[0].title, "Spy x Family");
    assert!(!page.has_next_page);
}
