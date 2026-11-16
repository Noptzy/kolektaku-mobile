use domain::error::SourceError;

use super::urls::MeionovelsUrls;

const BASE: &str = "https://meionovels.example";

fn urls() -> MeionovelsUrls {
    MeionovelsUrls::new(BASE).unwrap()
}

#[test]
fn only_web_addresses_are_accepted_as_a_base() {
    assert!(MeionovelsUrls::new("ftp://x.test").is_err());
    assert!(MeionovelsUrls::new("not a url").is_err());
    assert!(MeionovelsUrls::new(BASE).is_ok());
}

#[test]
fn the_first_page_of_the_latest_list_has_no_page_number() {
    assert_eq!(urls().latest(1), format!("{BASE}/novel/?m_orderby=latest"));
    assert_eq!(urls().latest(0), urls().latest(1));
    assert_eq!(
        urls().latest(3),
        format!("{BASE}/novel/page/3/?m_orderby=latest")
    );
}

#[test]
fn a_search_is_encoded_and_asks_for_novels_of_the_theme() {
    assert_eq!(
        urls().search(" re:zero & more "),
        format!("{BASE}/?s=re%3Azero+%26+more&post_type=wp-manga")
    );
}

#[test]
fn a_title_has_a_page_and_a_chapter_list_address() {
    assert_eq!(
        urls().detail("mushoku-tensei-ln").unwrap(),
        format!("{BASE}/novel/mushoku-tensei-ln/")
    );
    assert_eq!(
        urls().chapter_list("mushoku-tensei-ln").unwrap(),
        format!("{BASE}/novel/mushoku-tensei-ln/ajax/chapters/")
    );
}

#[test]
fn a_chapter_id_carries_the_title_and_the_chapter() {
    assert_eq!(
        urls()
            .chapter("mushoku-tensei-ln/volume-1-chapter-0")
            .unwrap(),
        format!("{BASE}/novel/mushoku-tensei-ln/volume-1-chapter-0/")
    );
}

#[test]
fn percent_encoded_slugs_are_kept_as_they_are() {
    let slug = "magical%e2%98%85explorer-ln";
    assert_eq!(
        urls().detail(slug).unwrap(),
        format!("{BASE}/novel/{slug}/")
    );
}

#[test]
fn bad_ids_never_become_addresses() {
    for bad in ["", "../x", "a/b", "-x", "a b", "x?y"] {
        assert!(
            matches!(urls().detail(bad), Err(SourceError::NotFound(_))),
            "{bad}"
        );
        assert!(
            matches!(urls().chapter_list(bad), Err(SourceError::NotFound(_))),
            "{bad}"
        );
    }
    for bad in ["only-one-part", "a/../b", "a/b//c", "/b", "a/", "a/b/"] {
        assert!(
            matches!(urls().chapter(bad), Err(SourceError::NotFound(_))),
            "{bad}"
        );
    }
}

#[test]
fn a_chapter_filed_under_a_group_becomes_a_nested_address() {
    assert_eq!(
        urls().chapter("ngnl-ln/htl/volume-12-chapter-5").unwrap(),
        format!("{BASE}/novel/ngnl-ln/htl/volume-12-chapter-5/")
    );
}
