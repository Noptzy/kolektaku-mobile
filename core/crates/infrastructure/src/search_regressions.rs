use std::sync::Arc;

use application::catalog::{MediaCard, SearchMedia, SearchOutcome};
use application::ports::SourceProvider;
use application::testing::FakeClock;
use domain::error::SourceError;
use domain::media::{MediaKind, MediaRef};
use serde_json::Value;

use crate::catalog::anilist::AniListCatalog;
use crate::fixtures;
use crate::http::{FakeHttp, HttpRequest, HttpResponse};
use crate::sources::kuramanime::KuramanimeSource;

const EMPTY_ANILIST: &str =
    r#"{"data":{"Page":{"pageInfo":{"currentPage":1,"hasNextPage":false},"media":[]}}}"#;

fn slug(text: &str) -> String {
    text.split(|c: char| !c.is_alphanumeric())
        .filter(|part| !part.is_empty())
        .collect::<Vec<_>>()
        .join("-")
}

fn searched_text(request: &HttpRequest) -> String {
    if request.url.contains("graphql.anilist.co") {
        let body: Value = serde_json::from_str(request.body.as_deref().unwrap()).unwrap();
        return body["variables"]["search"]
            .as_str()
            .unwrap_or_default()
            .to_string();
    }
    let url = url::Url::parse(&request.url).unwrap();
    url.query_pairs()
        .find(|(key, _)| key == "search")
        .map(|(_, value)| value.to_string())
        .unwrap_or_default()
}

fn recorded(request: &HttpRequest, anilist: AniListMode) -> HttpResponse {
    let name = slug(&searched_text(request));
    if request.url.contains("graphql.anilist.co") {
        return match anilist {
            AniListMode::Recorded => HttpResponse::new(
                200,
                fixtures::read("search", &format!("anilist-{name}.json")),
            ),
            AniListMode::KnowsNothing => HttpResponse::new(200, EMPTY_ANILIST),
            AniListMode::RateLimited => {
                HttpResponse::new(429, "{}").with_header("retry-after", "30")
            }
        };
    }
    HttpResponse::new(
        200,
        fixtures::read("search", &format!("kuramanime-{name}.html")),
    )
}

#[derive(Clone, Copy)]
enum AniListMode {
    Recorded,
    KnowsNothing,
    RateLimited,
}

async fn search(query: &str, mode: AniListMode) -> Result<SearchOutcome, SourceError> {
    let http = Arc::new(FakeHttp::replying(move |request: &HttpRequest| {
        Ok(recorded(request, mode))
    }));
    let clock = Arc::new(FakeClock::at(1_000));
    let catalog = Arc::new(AniListCatalog::new(http.clone(), clock.clone()));
    let kuramanime =
        KuramanimeSource::new(http, clock.clone(), "https://v20.kuramanime.ing", 1).unwrap();
    let sources: Vec<Arc<dyn SourceProvider>> = vec![Arc::new(kuramanime)];
    SearchMedia::new(catalog, sources, clock)
        .execute(MediaKind::Anime, query, 1)
        .await
}

fn card_for_item<'a>(outcome: &'a SearchOutcome, item: &str) -> &'a MediaCard {
    outcome
        .cards
        .iter()
        .find(|card| card.links.iter().any(|link| link.item.as_str() == item))
        .unwrap_or_else(|| panic!("no card links {item}"))
}

fn catalog_id(card: &MediaCard) -> Option<u64> {
    card.reference.catalog_id().map(|id| id.get())
}

#[tokio::test]
async fn kimi_no_na_wa_gives_the_film_card_and_a_separate_suntory_card() {
    let outcome = search("kimi no na wa", AniListMode::Recorded)
        .await
        .unwrap();
    let film = card_for_item(&outcome, "1020/kimi-no-na-wa");
    assert_eq!(catalog_id(film), Some(21519));
    assert_eq!(film.links.len(), 1);
    let promo = card_for_item(&outcome, "1021/suntory-minami-alps-no-tennensui");
    assert_ne!(promo.reference, film.reference);
    assert!(outcome.notices.is_empty());
}

#[tokio::test]
async fn your_name_finds_the_film() {
    let outcome = search("your name", AniListMode::Recorded).await.unwrap();
    let film = card_for_item(&outcome, "1020/kimi-no-na-wa");
    assert_eq!(catalog_id(film), Some(21519));
    let summary = film.summary.as_ref().unwrap();
    assert_eq!(summary.title.english.as_deref(), Some("Your Name."));
}

#[tokio::test]
async fn kimi_no_nawa_finds_the_film_through_the_relaxed_retry() {
    let outcome = search("kimi no nawa", AniListMode::Recorded).await.unwrap();
    let film = outcome
        .cards
        .iter()
        .find(|card| card.title == "Kimi no Na wa.")
        .expect("the film is in the results");
    assert!(
        film.links
            .iter()
            .any(|link| link.item.as_str() == "1020/kimi-no-na-wa")
    );
}

#[tokio::test]
async fn site_items_unknown_to_anilist_still_appear_and_stay_playable() {
    let outcome = search("kimi no na wa", AniListMode::KnowsNothing)
        .await
        .unwrap();
    let film = outcome
        .cards
        .iter()
        .find(|card| card.title == "Kimi no Na wa.")
        .unwrap();
    assert!(film.summary.is_none());
    assert!(matches!(film.reference, MediaRef::Source { .. }));
    assert_eq!(film.links.len(), 1);
    assert!(outcome.cards.len() >= 2);
}

#[tokio::test]
async fn anilist_rate_limiting_keeps_the_site_list() {
    let outcome = search("kimi no na wa", AniListMode::RateLimited)
        .await
        .unwrap();
    assert!(
        outcome
            .cards
            .iter()
            .any(|card| card.title == "Kimi no Na wa.")
    );
    assert_eq!(outcome.notices.len(), 1);
    assert!(matches!(
        outcome.notices[0].error,
        SourceError::RateLimited { .. }
    ));
    assert!(outcome.notices[0].origin.is_none());
}
