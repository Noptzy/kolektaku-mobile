use domain::error::SourceError;

use super::urls::NovelPhoenixUrls;

const BASE: &str = "https://novelphoenix.example";

fn urls() -> NovelPhoenixUrls {
    NovelPhoenixUrls::new(BASE).unwrap()
}

#[test]
fn only_web_addresses_are_accepted_as_a_base() {
    assert!(NovelPhoenixUrls::new("ftp://x.test").is_err());
    assert!(NovelPhoenixUrls::new(BASE).is_ok());
}

#[test]
fn the_latest_list_pages_forward() {
    assert_eq!(
        urls().latest(1),
        format!("{BASE}/genre-all/sort-new/status-all/all-novel")
    );
    assert_eq!(
        urls().latest(3),
        format!("{BASE}/genre-all/sort-new/status-all/all-novel?page=3")
    );
}

#[test]
fn a_search_is_encoded() {
    assert_eq!(
        urls().search(" re:zero & more "),
        format!("{BASE}/search?keyword=re%3Azero+%26+more")
    );
}

#[test]
fn a_title_has_a_page_and_numbered_chapter_list_pages() {
    assert_eq!(urls().detail("a-b").unwrap(), format!("{BASE}/novel/a-b"));
    assert_eq!(
        urls().chapter_list("a-b", 1).unwrap(),
        format!("{BASE}/novel/a-b/chapters?page=1")
    );
    assert_eq!(
        urls().chapter_list("a-b", 0).unwrap(),
        urls().chapter_list("a-b", 1).unwrap()
    );
    assert_eq!(
        urls().chapter_list("a-b", 6).unwrap(),
        format!("{BASE}/novel/a-b/chapters?page=6")
    );
}

#[test]
fn a_chapter_id_carries_the_title_and_the_number() {
    assert_eq!(
        urls().chapter("a-b/chapter-12").unwrap(),
        format!("{BASE}/novel/a-b/chapter-12")
    );
}

#[test]
fn bad_ids_never_become_addresses() {
    for bad in ["", "../x", "a/b", "-x", "a b", "x?y"] {
        assert!(
            matches!(urls().detail(bad), Err(SourceError::NotFound(_))),
            "{bad}"
        );
    }
    for bad in [
        "only-one-part",
        "a/../b",
        "a/b/c",
        "/chapter-1",
        "a/",
        "a/chapter-",
        "a/chapter-x",
        "a/chapter-1/extra",
    ] {
        assert!(
            matches!(urls().chapter(bad), Err(SourceError::NotFound(_))),
            "{bad}"
        );
    }
}
