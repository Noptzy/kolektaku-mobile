use std::sync::Arc;

use application::ports::SourceProvider;
use domain::source::{ItemId, SourceSearch};
use domain::stream::StreamPlan;
use infrastructure::clock::SystemClock;
use infrastructure::config::merge;
use infrastructure::http::{HttpClient, ReqwestClient};
use infrastructure::sources::registry::{SourceEnv, SourceRegistry, all_defaults};

fn source() -> Arc<dyn SourceProvider> {
    let http: Arc<dyn HttpClient> = Arc::new(ReqwestClient::standard().unwrap());
    let env = SourceEnv {
        http,
        clock: Arc::new(SystemClock),
    };
    let registry = SourceRegistry::build(&env, &merge(&all_defaults(), None).settings);
    registry
        .all()
        .into_iter()
        .find(|source| source.info().id.as_str() == "gogoanime")
        .expect("gogoanime is registered")
}

#[tokio::test]
#[ignore = "talks to the real site"]
async fn the_site_answers_from_the_list_to_the_player() {
    let site = source();
    let latest = site.latest(1).await.unwrap();
    println!(
        "terbaru: {} judul, {} halaman",
        latest.items.len(),
        latest.total_pages
    );
    assert!(!latest.items.is_empty());

    let found = site.search(SourceSearch::new("oshi no ko")).await.unwrap();
    println!(
        "cari: {:?}",
        found
            .items
            .iter()
            .map(|item| item.title.clone())
            .collect::<Vec<_>>()
    );
    assert!(!found.items.is_empty());

    let item = ItemId::new("oshi-no-ko-season-2");
    let detail = site.detail(item.clone()).await.unwrap();
    println!(
        "detail: {} | {:?} | {:?} | {} genre | sinopsis {} huruf",
        detail.item.title,
        detail.year,
        detail.unit_count,
        detail.genres.len(),
        detail.synopsis.len()
    );
    let units = site.units(item).await.unwrap();
    println!(
        "episode: {} (pertama {}, terakhir {})",
        units.len(),
        units[0].label,
        units[units.len() - 1].label
    );
    assert!(units.len() >= 12);

    let video = site.video().expect("it can play");
    let episode = units[units.len() - 1].id.clone();
    let servers = video.servers(episode.clone()).await.unwrap();
    println!(
        "server: {:?}",
        servers
            .iter()
            .map(|server| server.label.clone())
            .collect::<Vec<_>>()
    );
    assert!(!servers.is_empty());
    for server in &servers {
        match video.stream_plan(episode.clone(), server.id.clone()).await {
            Ok(StreamPlan::NeedsWebView {
                url,
                allowed_host,
                referer,
                ..
            }) => println!(
                "rencana {}: {url} (host {allowed_host}, referer {referer:?})",
                server.id
            ),
            Ok(other) => println!("rencana {}: {other:?}", server.id),
            Err(error) => println!("rencana {} gagal: {error}", server.id),
        }
    }
}
