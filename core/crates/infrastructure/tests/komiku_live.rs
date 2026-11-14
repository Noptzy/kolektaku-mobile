use std::sync::Arc;

use application::ports::SourceProvider;
use domain::source::{SourceOrder, SourceSearch};
use infrastructure::clock::SystemClock;
use infrastructure::http::ReqwestClient;
use infrastructure::sources::komiku::KomikuSource;

fn source() -> KomikuSource {
    let http = Arc::new(ReqwestClient::standard().unwrap());
    KomikuSource::new(
        http,
        Arc::new(SystemClock),
        "https://komiku.org",
        "https://api.komiku.org",
        5,
    )
    .unwrap()
}

#[tokio::test]
#[ignore = "live network"]
async fn komiku_lists_the_newest_chapters_and_paginates() {
    let source = source();
    let first = source.latest(1).await.unwrap();
    let second = source.latest(2).await.unwrap();
    assert!(first.items.len() >= 5);
    assert!(
        first.items[0]
            .latest_label
            .as_deref()
            .unwrap()
            .chars()
            .any(|c| c.is_ascii_digit())
    );
    assert_ne!(first.items[0].item_id, second.items[0].item_id);
}

#[tokio::test]
#[ignore = "live network"]
async fn komiku_searches() {
    let found = source()
        .search(SourceSearch::new("chainsaw man"))
        .await
        .unwrap();
    assert!(
        found
            .items
            .iter()
            .any(|item| item.title.to_lowercase().contains("chainsaw man"))
    );
}

#[tokio::test]
#[ignore = "live network"]
async fn komiku_lists_genres_and_opens_a_genre_page_in_every_order() {
    let source = source();
    let genres = source.genres().await.unwrap();
    assert!(genres.len() > 60);
    assert!(genres.iter().all(|genre| genre.slug != "hentai"));
    for explicit in [
        "BDSM",
        "Blowjob",
        "Big Penis",
        "Nakadashi",
        "MILF",
        "Bondage",
    ] {
        assert!(
            genres.iter().all(|genre| genre.name != explicit),
            "{explicit} must stay hidden"
        );
    }
    let mut firsts = std::collections::HashSet::new();
    for order in [
        SourceOrder::Newest,
        SourceOrder::Oldest,
        SourceOrder::Az,
        SourceOrder::Za,
    ] {
        let page = source.by_genre("action".into(), 1, order).await.unwrap();
        assert!(!page.items.is_empty(), "{order:?}");
        firsts.insert(page.items[0].item_id.clone());
    }
    assert!(firsts.len() >= 3);
    assert_eq!(
        source
            .by_genre("action".into(), 2, SourceOrder::Newest)
            .await
            .unwrap()
            .page,
        2
    );
}

#[tokio::test]
#[ignore = "live network"]
async fn komiku_opens_a_title_lists_chapters_and_reads_real_chapter_images() {
    let source = source();
    let found = source
        .search(SourceSearch::new("chainsaw man"))
        .await
        .unwrap();
    let title = found
        .items
        .iter()
        .find(|item| item.title.eq_ignore_ascii_case("chainsaw man"))
        .unwrap_or(&found.items[0]);
    let detail = source.detail(title.item_id.clone()).await.unwrap();
    let kind = detail.type_text.unwrap_or_default().to_lowercase();
    assert!(
        ["manga", "manhwa", "manhua"]
            .iter()
            .any(|known| kind.contains(known))
    );
    assert!(detail.synopsis.len() > 20);
    let units = source.units(title.item_id.clone()).await.unwrap();
    assert!(units.len() > 50);
    assert!(units.first().unwrap().number < units.last().unwrap().number);
    let pages = source
        .pages()
        .unwrap()
        .chapter_pages(units[0].id.clone())
        .await
        .unwrap();
    assert!(pages.pages.len() >= 3);
    assert!(
        pages
            .pages
            .iter()
            .all(|page| page.url.starts_with("https://"))
    );
}

#[tokio::test]
#[ignore = "live network"]
async fn komiku_chapter_images_load_with_and_without_a_referer() {
    use infrastructure::http::{HttpClient, HttpRequest};

    let source = source();
    let found = source
        .search(SourceSearch::new("chainsaw man"))
        .await
        .unwrap();
    let title = found.items[0].item_id.clone();
    let units = source.units(title).await.unwrap();
    let pages = source
        .pages()
        .unwrap()
        .chapter_pages(units[0].id.clone())
        .await
        .unwrap();
    let url = pages.pages[0].url.clone();
    println!("first page: {url}");
    let http = ReqwestClient::standard().unwrap();
    let plain = http.send(HttpRequest::get(url.clone())).await.unwrap();
    println!(
        "no referer -> {} {:?}",
        plain.status,
        plain.header("content-type")
    );
    let with = http
        .send(HttpRequest::get(url).with_header("Referer", "https://komiku.org/"))
        .await
        .unwrap();
    println!(
        "referer    -> {} {:?}",
        with.status,
        with.header("content-type")
    );
    assert!(with.status == 200);
}
