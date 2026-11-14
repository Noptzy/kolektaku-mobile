use domain::error::SourceError;
use domain::source::SourceOrder;

use super::urls::KuramanimeUrls;

fn urls() -> KuramanimeUrls {
    KuramanimeUrls::new("https://v20.kuramanime.example/").unwrap()
}

#[test]
fn builds_the_allow_listed_listing_urls() {
    let urls = urls();
    assert_eq!(
        urls.latest(2),
        "https://v20.kuramanime.example/quick/ongoing?order_by=updated&page=2"
    );
    assert_eq!(
        urls.search(" one piece ", 1, SourceOrder::Newest),
        "https://v20.kuramanime.example/anime?search=one+piece&order_by=latest&page=1"
    );
    assert_eq!(
        urls.search("one piece", 3, SourceOrder::Az),
        "https://v20.kuramanime.example/anime?search=one+piece&order_by=ascending&page=3"
    );
    assert_eq!(
        urls.genres(),
        "https://v20.kuramanime.example/properties/genre?order_by=ascending"
    );
    assert_eq!(
        urls.genre("Slice-Of-Life", 2, SourceOrder::Oldest).unwrap(),
        "https://v20.kuramanime.example/properties/genre/slice-of-life?order_by=oldest&page=2"
    );
}

#[test]
fn detail_and_episode_urls_follow_the_id_shape() {
    let urls = urls();
    assert_eq!(
        urls.detail("50/one-piece", 1).unwrap(),
        "https://v20.kuramanime.example/anime/50/one-piece"
    );
    assert_eq!(
        urls.detail("50/one-piece", 3).unwrap(),
        "https://v20.kuramanime.example/anime/50/one-piece?page=3"
    );
    assert_eq!(
        urls.episode("50/one-piece/episode/7").unwrap(),
        "https://v20.kuramanime.example/anime/50/one-piece/episode/7"
    );
}

#[test]
fn special_characters_in_a_search_are_percent_encoded() {
    let url = urls().search("a&b=c é", 1, SourceOrder::Newest);
    assert!(url.contains("search=a%26b%3Dc+%C3%A9"), "{url}");
}

#[test]
fn rejects_genres_and_ids_that_are_not_well_formed() {
    let urls = urls();
    assert!(matches!(
        urls.genre("../admin", 1, SourceOrder::Newest),
        Err(SourceError::NotFound(_))
    ));
    assert!(matches!(
        urls.detail("https://evil.example/a", 1),
        Err(SourceError::NotFound(_))
    ));
    assert!(matches!(
        urls.episode("../admin"),
        Err(SourceError::NotFound(_))
    ));
    assert!(matches!(
        urls.detail("50/one-piece/episode/1", 1),
        Err(SourceError::NotFound(_))
    ));
    assert!(matches!(
        urls.episode("50/one-piece"),
        Err(SourceError::NotFound(_))
    ));
}

#[test]
fn the_base_address_must_be_a_web_address() {
    assert!(KuramanimeUrls::new("not a url").is_err());
    assert!(KuramanimeUrls::new("file:///etc/passwd").is_err());
    assert_eq!(urls().host(), "v20.kuramanime.example");
}
