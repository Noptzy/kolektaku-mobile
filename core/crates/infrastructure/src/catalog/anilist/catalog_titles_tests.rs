use std::sync::Arc;

use application::ports::MetadataCatalog;
use domain::error::SourceError;
use domain::media::{MediaId, MediaKind};
use serde_json::Value;

use super::catalog_test_support::{OCTOBER_2026, catalog_over};
use crate::fixtures;
use crate::http::{FakeHttp, HttpResponse};

fn detail_reply(mal_id: Option<u64>, streaming: Value) -> String {
    let mut body: Value = serde_json::from_str(&fixtures::anilist("detail-anime.json")).unwrap();
    let media = &mut body["data"]["Media"];
    media["idMal"] = mal_id.map_or(Value::Null, Value::from);
    media["episodes"] = Value::from(12);
    media["streamingEpisodes"] = streaming;
    body.to_string()
}

fn id() -> MediaId {
    MediaId::new(101_922).unwrap()
}

#[tokio::test]
async fn the_catalog_id_is_asked_for_with_the_detail() {
    let (catalog, http) =
        super::catalog_test_support::catalog_replying(detail_reply(Some(1), Value::Null));
    catalog.detail(MediaKind::Anime, id()).await.unwrap();
    assert!(super::catalog_test_support::sent_query(&http, 0).contains("idMal"));
}

#[tokio::test]
async fn titles_from_the_other_catalog_fill_in_what_this_one_lacks() {
    let http = Arc::new(FakeHttp::scripted(vec![
        Ok(HttpResponse::new(
            200,
            detail_reply(Some(59741), Value::Null),
        )),
        Ok(HttpResponse::new(200, fixtures::mal("episodes-59741.html"))),
    ]));
    let catalog = catalog_over(http.clone(), OCTOBER_2026);
    let detail = catalog.detail(MediaKind::Anime, id()).await.unwrap();
    assert_eq!(detail.mal_id, Some(59741));
    assert_eq!(detail.episodes[0].number, 1.0);
    assert_eq!(detail.episodes[0].title, "I'm Elymas the Heavy Knight");
    assert_eq!(http.requests().len(), 2);
    assert!(http.requests()[1].url.contains("/anime/59741/x/episode"));
}

#[tokio::test]
async fn a_picture_from_this_catalog_keeps_its_place_beside_the_other_title() {
    let streaming = serde_json::json!([
        { "title": "Episode 1", "thumbnail": "https://img.test/1.jpg" }
    ]);
    let http = Arc::new(FakeHttp::scripted(vec![
        Ok(HttpResponse::new(200, detail_reply(Some(59741), streaming))),
        Ok(HttpResponse::new(200, fixtures::mal("episodes-59741.html"))),
    ]));
    let catalog = catalog_over(http, OCTOBER_2026);
    let detail = catalog.detail(MediaKind::Anime, id()).await.unwrap();
    assert_eq!(detail.episodes[0].title, "I'm Elymas the Heavy Knight");
    assert_eq!(
        detail.episodes[0].thumbnail_url.as_deref(),
        Some("https://img.test/1.jpg")
    );
}

#[tokio::test]
async fn without_a_catalog_id_no_second_request_is_made() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(
        200,
        detail_reply(None, Value::Null),
    )));
    let catalog = catalog_over(http.clone(), OCTOBER_2026);
    catalog.detail(MediaKind::Anime, id()).await.unwrap();
    assert_eq!(http.requests().len(), 1);
}

#[tokio::test]
async fn manga_never_asks_for_episode_titles() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(
        200,
        fixtures::anilist("detail-manga.json"),
    )));
    let catalog = catalog_over(http.clone(), OCTOBER_2026);
    catalog
        .detail(MediaKind::Manga, MediaId::new(87_216).unwrap())
        .await
        .unwrap();
    assert_eq!(http.requests().len(), 1);
}

#[tokio::test]
async fn a_failing_title_page_never_breaks_the_detail() {
    let http = Arc::new(FakeHttp::scripted(vec![
        Ok(HttpResponse::new(
            200,
            detail_reply(Some(59741), Value::Null),
        )),
        Err(SourceError::Network("down".into())),
    ]));
    let catalog = catalog_over(http, OCTOBER_2026);
    let detail = catalog.detail(MediaKind::Anime, id()).await.unwrap();
    assert_eq!(detail.summary.title.romaji, "Kimetsu no Yaiba");
    assert!(detail.episodes.is_empty());
}

#[tokio::test]
async fn the_quick_detail_does_not_wait_for_the_other_catalog() {
    let http = Arc::new(FakeHttp::scripted(vec![Ok(HttpResponse::new(
        200,
        detail_reply(Some(59741), Value::Null),
    ))]));
    let catalog = catalog_over(http.clone(), OCTOBER_2026);
    let detail = catalog.detail_fast(MediaKind::Anime, id()).await.unwrap();
    assert_eq!(detail.mal_id, Some(59741));
    assert_eq!(http.requests().len(), 1);
}

#[tokio::test]
async fn the_titles_can_be_fetched_afterwards_for_the_quick_detail() {
    let http = Arc::new(FakeHttp::scripted(vec![
        Ok(HttpResponse::new(
            200,
            detail_reply(Some(59741), Value::Null),
        )),
        Ok(HttpResponse::new(200, fixtures::mal("episodes-59741.html"))),
    ]));
    let catalog = catalog_over(http.clone(), OCTOBER_2026);
    let detail = catalog.detail_fast(MediaKind::Anime, id()).await.unwrap();
    let titled = catalog.episode_titles(&detail).await;
    assert_eq!(titled[0].title, "I'm Elymas the Heavy Knight");
    assert_eq!(http.requests().len(), 2);
}

#[tokio::test]
async fn a_manga_never_asks_the_other_catalog_for_titles() {
    let http = Arc::new(FakeHttp::scripted(vec![Ok(HttpResponse::new(
        200,
        fixtures::anilist("detail-manga.json"),
    ))]));
    let catalog = catalog_over(http.clone(), OCTOBER_2026);
    let detail = catalog
        .detail_fast(MediaKind::Manga, MediaId::new(87_216).unwrap())
        .await
        .unwrap();
    let titled = catalog.episode_titles(&detail).await;
    assert_eq!(titled, detail.episodes);
    assert_eq!(http.requests().len(), 1);
}
