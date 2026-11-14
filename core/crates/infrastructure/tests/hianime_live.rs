use std::sync::Arc;

use application::ports::SourceProvider;
use domain::source::SourceSearch;
use domain::stream::StreamPlan;
use infrastructure::clock::SystemClock;
use infrastructure::http::ReqwestClient;
use infrastructure::sources::hianime::HianimeSource;

fn source() -> HianimeSource {
    let http = Arc::new(ReqwestClient::standard().unwrap());
    HianimeSource::new(http, Arc::new(SystemClock), "https://animehot.cc/api", 2).unwrap()
}

#[tokio::test]
#[ignore = "live network"]
async fn the_latest_list_has_titles_with_covers() {
    let page = source().latest(1).await.unwrap();
    assert!(page.items.len() >= 5);
    assert!(page.total_pages > 1);
    assert!(page.items.iter().all(|item| !item.title.trim().is_empty()));
}

#[tokio::test]
#[ignore = "live network"]
async fn a_romaji_style_title_is_found_through_the_shortened_queries() {
    let page = source()
        .search(SourceSearch::new(
            "STEEL BALL RUN JoJo's Bizarre Adventure 2nd - 3rd STAGE",
        ))
        .await
        .unwrap();
    assert!(
        page.items
            .iter()
            .any(|item| item.title.contains("2nd Stage")),
        "{:?}",
        page.items
    );
}

#[tokio::test]
#[ignore = "live network"]
async fn steel_ball_run_goes_from_search_to_a_web_view_plan() {
    let source = source();
    let page = source
        .search(SourceSearch::new("steel ball run"))
        .await
        .unwrap();
    let item = page
        .items
        .iter()
        .find(|item| item.title.contains("2nd Stage"))
        .unwrap_or_else(|| panic!("no 2nd stage in {:?}", page.items));
    let detail = source.detail(item.item_id.clone()).await.unwrap();
    assert!(detail.unit_count.unwrap_or(0) >= 1);
    let units = source.units(item.item_id.clone()).await.unwrap();
    assert!(units.len() >= 8, "{}", units.len());
    let video = source.video().unwrap();
    let servers = video.servers(units[0].id.clone()).await.unwrap();
    assert!(servers.iter().any(|server| server.id == "sub-1"));
    let plan = video
        .stream_plan(units[0].id.clone(), "sub-1".into())
        .await
        .unwrap();
    let StreamPlan::NeedsWebView {
        url, allowed_host, ..
    } = plan
    else {
        panic!("expected a web view plan");
    };
    assert!(url.starts_with("https://"));
    assert!(url.contains(&allowed_host));
}
