use std::sync::Arc;
use std::time::{Duration, Instant};

use application::catalog::SearchMedia;
use application::ports::{Clock, MetadataCatalog};
use domain::media::MediaKind;
use domain::source::SourceSearch;
use infrastructure::catalog::anilist::AniListCatalog;
use infrastructure::clock::SystemClock;
use infrastructure::config::merge;
use infrastructure::http::{
    HttpClient, RateLimitSettings, RateLimitedClient, ReqwestClient, SystemPause,
};
use infrastructure::sources::registry::{SourceEnv, SourceRegistry, all_defaults};

const RUNS: usize = 5;

fn setup() -> (Arc<AniListCatalog>, SourceRegistry, Arc<dyn Clock>) {
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
    (catalog, registry, clock)
}

fn report(label: &str, mut times: Vec<Duration>) {
    times.sort();
    let median = times[times.len() / 2];
    let worst = times[times.len() - 1];
    println!(
        "{label}: median {:.2}s, terburuk {:.2}s ({} kali)",
        median.as_secs_f64(),
        worst.as_secs_f64(),
        times.len()
    );
}

#[tokio::test]
#[ignore = "talks to AniList and the sites"]
async fn how_long_searches_take() {
    let (catalog, registry, clock) = setup();
    for query in ["kimetsu", "one piece"] {
        let mut catalog_only = Vec::new();
        let mut combined = Vec::new();
        for _ in 0..RUNS {
            let started = Instant::now();
            let _ = catalog.search(MediaKind::Anime, query, 1).await;
            catalog_only.push(started.elapsed());
            let search = SearchMedia::new(
                catalog.clone(),
                registry.for_kind(MediaKind::Anime),
                clock.clone(),
            );
            let started = Instant::now();
            let outcome = search.execute(MediaKind::Anime, query, 1).await;
            combined.push(started.elapsed());
            if let Ok(outcome) = outcome {
                for notice in &outcome.notices {
                    println!("  catatan \"{query}\": {:?}", notice.error);
                }
            }
        }
        report(&format!("katalog saja \"{query}\""), catalog_only);
        report(&format!("katalog + situs \"{query}\""), combined);
    }
}

#[tokio::test]
#[ignore = "talks to the sites"]
async fn how_long_each_site_takes() {
    let (_, registry, _) = setup();
    for kind in [MediaKind::Anime, MediaKind::Manga, MediaKind::Novel] {
        for query in ["kimetsu", "one piece", "hyouka"] {
            for source in registry.for_kind(kind) {
                let started = Instant::now();
                let outcome = source.search(SourceSearch::new(query)).await;
                let took = started.elapsed().as_secs_f64();
                let note = match outcome {
                    Ok(page) => format!("{} hasil", page.items.len()),
                    Err(error) => format!("gagal: {error}"),
                };
                println!(
                    "{:?} \"{query}\" {}: {took:.2}s, {note}",
                    kind,
                    source.info().id
                );
            }
        }
    }
}
