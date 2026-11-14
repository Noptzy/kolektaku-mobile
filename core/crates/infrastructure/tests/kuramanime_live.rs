use std::sync::Arc;

use application::ports::SourceProvider;
use domain::source::{SourceOrder, SourceSearch};
use domain::stream::StreamPlan;
use infrastructure::clock::SystemClock;
use infrastructure::http::ReqwestClient;
use infrastructure::sources::kuramanime::KuramanimeSource;

fn base_url() -> String {
    std::env::var("KURAMANIME_BASE_URL").unwrap_or_else(|_| "https://v20.kuramanime.ing".into())
}

fn source() -> KuramanimeSource {
    let http = Arc::new(ReqwestClient::standard().unwrap());
    KuramanimeSource::new(http, Arc::new(SystemClock), &base_url(), 1).unwrap()
}

#[tokio::test]
#[ignore = "live network"]
async fn kuramanime_lists_the_newest_episodes_and_paginates() {
    let source = source();
    let first = source.latest(1).await.unwrap();
    let second = source.latest(2).await.unwrap();
    assert!(first.items.len() >= 10);
    assert_eq!(second.page, 2);
    assert_ne!(first.items[0].item_id, second.items[0].item_id);
}

#[tokio::test]
#[ignore = "live network"]
async fn kuramanime_lists_the_genres_without_adult_ones() {
    let genres = source().genres().await.unwrap();
    let slugs: Vec<&str> = genres.iter().map(|genre| genre.slug.as_str()).collect();
    assert!(genres.len() >= 70);
    for expected in ["action", "comedy", "drama"] {
        assert!(slugs.contains(&expected), "{expected}");
    }
    assert!(!slugs.contains(&"hentai") && !slugs.contains(&"erotica"));
}

#[tokio::test]
#[ignore = "live network"]
async fn kuramanime_opens_a_genre_page_and_paginates_it_in_both_orders() {
    let source = source();
    let newest = source
        .by_genre("action".into(), 1, SourceOrder::Newest)
        .await
        .unwrap();
    let second = source
        .by_genre("action".into(), 2, SourceOrder::Newest)
        .await
        .unwrap();
    let az = source
        .by_genre("action".into(), 1, SourceOrder::Az)
        .await
        .unwrap();
    assert!(newest.items.len() >= 10 && newest.total_pages > 5);
    assert_eq!(second.page, 2);
    assert!(second.total_pages > second.page);
    assert_ne!(second.items[0].item_id, newest.items[0].item_id);
    assert_ne!(az.items[0].item_id, newest.items[0].item_id);
}

#[tokio::test]
#[ignore = "live network"]
async fn kuramanime_searches_then_reads_the_detail_and_every_episode() {
    let source = source();
    let found = source.search(SourceSearch::new("one piece")).await.unwrap();
    let target = found
        .items
        .iter()
        .find(|item| item.title.to_lowercase() == "one piece")
        .unwrap_or(&found.items[0]);
    let detail = source.detail(target.item_id.clone()).await.unwrap();
    assert_eq!(detail.type_text.as_deref(), Some("TV"));
    assert_eq!(detail.year, Some(1999));
    assert!(!detail.genres.is_empty() && !detail.alternative_titles.is_empty());
    let units = source.units(target.item_id.clone()).await.unwrap();
    assert!(units.len() > 100);
    assert!(units.first().unwrap().number < units.last().unwrap().number);
}

#[tokio::test]
#[ignore = "live network"]
async fn kuramanime_reads_a_movie_type_and_its_single_unit() {
    let source = source();
    let found = source
        .search(SourceSearch::new("kimi no na wa"))
        .await
        .unwrap();
    let detail = source.detail(found.items[0].item_id.clone()).await.unwrap();
    assert_eq!(detail.type_text.as_deref(), Some("Movie"));
    assert_eq!(detail.unit_count, Some(1));
}

#[tokio::test]
#[ignore = "live network"]
async fn kuramanime_lists_the_servers_of_an_episode_and_plans_a_web_view_stream() {
    let source = source();
    let found = source.search(SourceSearch::new("one piece")).await.unwrap();
    let item = found.items[0].item_id.clone();
    let units = source.units(item).await.unwrap();
    let episode = units.last().unwrap().id.clone();
    let video = source.video().unwrap();
    let servers = video.servers(episode.clone()).await.unwrap();
    assert!(!servers.is_empty());
    let plan = video
        .stream_plan(episode, servers[0].id.clone())
        .await
        .unwrap();
    assert!(matches!(plan, StreamPlan::NeedsWebView { .. }));
}
