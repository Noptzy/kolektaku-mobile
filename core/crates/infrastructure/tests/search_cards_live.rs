use std::sync::Arc;

use application::catalog::SearchMedia;
use application::ports::Clock;
use domain::media::MediaKind;
use infrastructure::catalog::anilist::AniListCatalog;
use infrastructure::clock::SystemClock;
use infrastructure::config::merge;
use infrastructure::http::{
    HttpClient, RateLimitSettings, RateLimitedClient, ReqwestClient, SystemPause,
};
use infrastructure::sources::registry::{SourceEnv, SourceRegistry, all_defaults};

#[tokio::test]
#[ignore = "talks to AniList and the sites"]
async fn print_the_cards_a_search_produces() {
    let transport = Arc::new(ReqwestClient::standard().unwrap());
    let plain: Arc<dyn HttpClient> = transport.clone();
    let limited: Arc<dyn HttpClient> = Arc::new(RateLimitedClient::new(
        transport,
        Arc::new(SystemPause),
        RateLimitSettings::default(),
    ));
    let clock: Arc<dyn Clock> = Arc::new(SystemClock);
    let catalog = Arc::new(AniListCatalog::new(limited, clock.clone()));
    let env = SourceEnv {
        http: plain,
        clock: clock.clone(),
    };
    let registry = SourceRegistry::build(&env, &merge(&all_defaults(), None).settings);
    let query = std::env::var("CARDS_QUERY").unwrap_or_else(|_| "seishun buta yarou".into());
    let search = SearchMedia::new(catalog, registry.for_kind(MediaKind::Anime), clock);
    let outcome = search.execute(MediaKind::Anime, &query, 1).await.unwrap();
    println!("kartu: {}", outcome.cards.len());
    for card in &outcome.cards {
        let links: Vec<String> = card
            .links
            .iter()
            .map(|link| format!("{}:{}(+{})", link.source, link.item, link.variants.len()))
            .collect();
        println!(
            "- {} | katalog={} | {}",
            card.title,
            card.summary.is_some(),
            links.join(" ")
        );
    }
    for notice in &outcome.notices {
        println!("catatan: {:?}", notice.error);
    }
}
