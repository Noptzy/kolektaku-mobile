use domain::error::SourceError;

use super::urls::{WeebCentralUrls, is_series_code};

const BASE: &str = "https://weebcentral.example";
const CODE: &str = "01J76XYEB4BNMXCR7TP6YY0VN0";

fn urls() -> WeebCentralUrls {
    WeebCentralUrls::new(BASE).unwrap()
}

#[test]
fn a_search_always_excludes_adult_titles_and_asks_for_the_first_page() {
    let url = urls().search(" one piece ");
    assert!(url.starts_with(&format!("{BASE}/search/data?text=one+piece&limit=32&offset=0")));
    assert!(url.contains("adult=False"));
    assert!(!url.contains("adult=Any"));
}

#[test]
fn the_latest_list_pages_by_offset_and_still_excludes_adult_titles() {
    assert!(urls().latest(1).contains("offset=0"));
    assert!(urls().latest(3).contains("offset=64"));
    assert!(urls().latest(3).contains("sort=Latest+Updates"));
    assert!(urls().latest(3).contains("adult=False"));
}

#[test]
fn a_title_has_a_page_and_a_chapter_list_address() {
    let id = format!("{CODE}/Medalist");
    assert_eq!(
        urls().detail(&id).unwrap(),
        format!("{BASE}/series/{CODE}/Medalist")
    );
    assert_eq!(
        urls().chapter_list(&id).unwrap(),
        format!("{BASE}/series/{CODE}/full-chapter-list")
    );
}

#[test]
fn a_chapter_has_an_images_address_for_a_long_strip() {
    let url = urls().images(CODE).unwrap();
    assert!(url.starts_with(&format!("{BASE}/chapters/{CODE}/images?")));
    assert!(url.contains("reading_style=long_strip"));
}

#[test]
fn only_a_real_code_counts_as_a_series_or_chapter_code() {
    assert!(is_series_code(CODE));
    for bad in ["", "short", "01j76xyeb4bnmxcr7tp6yy0vn0", "01J76XYEB4BNMXCR7TP6YY0VN0X"] {
        assert!(!is_series_code(bad), "{bad}");
    }
}

#[test]
fn bad_ids_never_become_addresses() {
    for bad in ["", "Medalist", "../x", &format!("{CODE}/"), &format!("{CODE}/a b"), "short/Medalist"] {
        assert!(
            matches!(urls().detail(bad), Err(SourceError::NotFound(_))),
            "{bad}"
        );
        assert!(
            matches!(urls().chapter_list(bad), Err(SourceError::NotFound(_))),
            "{bad}"
        );
    }
    assert!(matches!(
        urls().images("../x"),
        Err(SourceError::NotFound(_))
    ));
}
