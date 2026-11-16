use domain::error::SourceError;

use super::urls::BakaTsukiUrls;

fn urls() -> BakaTsukiUrls {
    BakaTsukiUrls::new("https://www.baka-tsuki.org").unwrap()
}

#[test]
fn the_series_list_asks_the_english_light_novel_category() {
    let url = urls().categories();
    assert!(url.starts_with("https://www.baka-tsuki.org/project/api.php?"));
    assert!(url.contains("list=categorymembers"));
    assert!(url.contains("Light+novel+%28English%29") || url.contains("Light%20novel"));
}

#[test]
fn a_page_title_is_sent_as_a_query_value_with_spaces_for_underscores() {
    assert_eq!(
        urls().page("Hyouka:Volume_1_Chapter_1").unwrap(),
        "https://www.baka-tsuki.org/project/index.php?title=Hyouka%3AVolume+1+Chapter+1"
    );
}

#[test]
fn awkward_but_legal_titles_are_encoded_not_pasted() {
    let url = urls().page(".Hack//ZERO").unwrap();
    assert!(url.ends_with("title=.Hack%2F%2FZERO"));
}

#[test]
fn titles_that_could_change_the_request_never_become_addresses() {
    for bad in [
        "", "  ", "a|b", "a#b", "<x>", "[x]", "{x}", "a
b", "../x", "a/../b", "..",
    ] {
        assert!(
            matches!(urls().page(bad), Err(SourceError::NotFound(_))),
            "{bad:?}"
        );
    }
    assert!(urls().page(&"x".repeat(300)).is_err());
}

#[test]
fn a_site_address_must_be_a_web_address() {
    assert!(BakaTsukiUrls::new("not a url").is_err());
    assert!(BakaTsukiUrls::new("ftp://example.test").is_err());
}
