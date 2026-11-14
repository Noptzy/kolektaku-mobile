use std::sync::Arc;

use application::catalog::{SearchMedia, SearchOutcome};
use application::ports::SourceProvider;
use domain::media::MediaKind;
use infrastructure::catalog::anilist::AniListCatalog;
use infrastructure::clock::SystemClock;
use infrastructure::http::{RateLimitSettings, RateLimitedClient, ReqwestClient, SystemPause};
use infrastructure::sources::kuramanime::KuramanimeSource;

async fn search(query: &str) -> SearchOutcome {
    let transport = Arc::new(ReqwestClient::standard().unwrap());
    let http = Arc::new(RateLimitedClient::new(
        transport.clone(),
        Arc::new(SystemPause),
        RateLimitSettings::default(),
    ));
    let clock = Arc::new(SystemClock);
    let catalog = Arc::new(AniListCatalog::new(http, clock.clone()));
    let kuramanime =
        KuramanimeSource::new(transport, clock.clone(), "https://v20.kuramanime.ing", 1).unwrap();
    let sources: Vec<Arc<dyn SourceProvider>> = vec![Arc::new(kuramanime)];
    SearchMedia::new(catalog, sources, clock)
        .execute(MediaKind::Anime, query, 1)
        .await
        .unwrap()
}

fn has_the_film(outcome: &SearchOutcome) -> bool {
    outcome.cards.iter().any(|card| {
        card.title == "Kimi no Na wa."
            && card
                .links
                .iter()
                .any(|link| link.source.as_str() == "kuramanime")
    })
}

#[tokio::test]
#[ignore = "live network"]
async fn search_finds_the_film_for_every_spelling() {
    for query in ["kimi no na wa", "your name", "kimi no nawa"] {
        let outcome = search(query).await;
        assert!(
            has_the_film(&outcome),
            "{query}: {:?}",
            outcome
                .cards
                .iter()
                .map(|card| &card.title)
                .collect::<Vec<_>>()
        );
    }
}

#[tokio::test]
#[ignore = "live network"]
async fn search_keeps_the_film_and_the_promo_apart() {
    let outcome = search("kimi no na wa").await;
    let film = outcome
        .cards
        .iter()
        .find(|card| card.title == "Kimi no Na wa.")
        .unwrap();
    assert_eq!(film.reference.catalog_id().map(|id| id.get()), Some(21519));
    assert!(
        outcome
            .cards
            .iter()
            .any(|card| card.title.starts_with("Suntory"))
    );
}
