use domain::error::SourceError;
use domain::source::SourceOrder;

use super::urls::KomikindoUrls;

const BASE: &str = "https://komikindo.example";

fn urls() -> KomikindoUrls {
    KomikindoUrls::new(BASE).unwrap()
}

#[test]
fn builds_the_urls_the_site_understands() {
    let urls = urls();
    assert_eq!(urls.latest(1), format!("{BASE}/komik-terbaru/"));
    assert_eq!(urls.latest(3), format!("{BASE}/komik-terbaru/page/3/"));
    assert_eq!(urls.search(" one piece "), format!("{BASE}/?s=one+piece"));
    assert_eq!(urls.genres(), format!("{BASE}/daftar-manga/"));
    assert_eq!(
        urls.detail("chainsaw-man").unwrap(),
        format!("{BASE}/komik/chainsaw-man/")
    );
    assert_eq!(
        urls.chapter("chainsaw-man-chapter-1").unwrap(),
        format!("{BASE}/chainsaw-man-chapter-1/")
    );
}

#[test]
fn genre_urls_use_the_filter_form_and_its_order_values() {
    let urls = urls();
    assert_eq!(
        urls.genre("action", 2, SourceOrder::Az).unwrap(),
        format!("{BASE}/daftar-manga/page/2/?genre%5B%5D=action&order=title")
    );
    assert_eq!(
        urls.genre("Action", 1, SourceOrder::Za).unwrap(),
        format!("{BASE}/daftar-manga/?genre%5B%5D=action&order=titlereverse")
    );
    assert_eq!(
        urls.genre("action", 1, SourceOrder::Oldest).unwrap(),
        format!("{BASE}/daftar-manga/?genre%5B%5D=action&order=update")
    );
}

#[test]
fn anything_that_is_not_an_id_is_refused() {
    let urls = urls();
    assert!(matches!(urls.detail("../x"), Err(SourceError::NotFound(_))));
    assert!(matches!(urls.chapter("a/b"), Err(SourceError::NotFound(_))));
    assert!(matches!(
        urls.genre("a/b", 1, SourceOrder::Newest),
        Err(SourceError::NotFound(_))
    ));
}

#[test]
fn percent_escapes_are_allowed_inside_ids() {
    assert!(urls().detail("%E3%83%81-title").is_err());
    assert!(urls().detail("title%20x").is_ok());
}

#[test]
fn the_base_must_be_a_web_address() {
    assert!(KomikindoUrls::new("nonsense").is_err());
}
