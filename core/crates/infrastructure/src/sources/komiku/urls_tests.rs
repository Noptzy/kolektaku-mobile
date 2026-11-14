use domain::error::SourceError;
use domain::source::SourceOrder;

use super::urls::KomikuUrls;

fn urls() -> KomikuUrls {
    KomikuUrls::new("https://komiku.example", "https://api.komiku.example").unwrap()
}

#[test]
fn listing_urls_live_on_the_api_host_with_order_and_page() {
    let urls = urls();
    assert_eq!(
        urls.latest(1),
        "https://api.komiku.example/manga/?orderby=modified"
    );
    assert_eq!(
        urls.latest(3),
        "https://api.komiku.example/manga/page/3/?orderby=modified"
    );
    assert_eq!(
        urls.genre("Slice-Of-Life", 2, SourceOrder::Az).unwrap(),
        "https://api.komiku.example/genre/slice-of-life/page/2/?orderby=title&order=asc"
    );
    assert_eq!(
        urls.genre("action", 1, SourceOrder::Oldest).unwrap(),
        "https://api.komiku.example/genre/action/?orderby=modified&order=asc"
    );
}

#[test]
fn search_urls_carry_the_query_and_only_a_non_default_order() {
    let urls = urls();
    assert_eq!(
        urls.search(" one piece ", SourceOrder::Newest),
        "https://api.komiku.example/?post_type=manga&s=one+piece"
    );
    assert_eq!(
        urls.search("one piece", SourceOrder::Za),
        "https://api.komiku.example/?post_type=manga&s=one+piece&orderby=title&order=desc"
    );
}

#[test]
fn page_urls_live_on_the_site_host() {
    let urls = urls();
    assert_eq!(urls.genres(), "https://komiku.example/genre/action/");
    assert_eq!(
        urls.detail("123213-chainsaw-man").unwrap(),
        "https://komiku.example/manga/123213-chainsaw-man/"
    );
    assert_eq!(
        urls.chapter("chainsaw-man-chapter-01").unwrap(),
        "https://komiku.example/chainsaw-man-chapter-01/"
    );
}

#[test]
fn anything_that_is_not_an_id_is_refused() {
    let urls = urls();
    assert!(matches!(
        urls.detail("../admin"),
        Err(SourceError::NotFound(_))
    ));
    assert!(matches!(urls.chapter("a/b"), Err(SourceError::NotFound(_))));
    assert!(matches!(
        urls.genre("../x", 1, SourceOrder::Newest),
        Err(SourceError::NotFound(_))
    ));
}

#[test]
fn both_addresses_must_be_web_addresses() {
    assert!(KomikuUrls::new("nonsense", "https://api.komiku.example").is_err());
    assert!(KomikuUrls::new("https://komiku.example", "ftp://x").is_err());
}
