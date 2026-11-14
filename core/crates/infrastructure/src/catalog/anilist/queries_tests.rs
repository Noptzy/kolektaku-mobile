use super::*;

#[test]
fn every_document_shares_the_summary_fragment() {
    for document in [
        detail_query(),
        list_query(false, false),
        search_query(),
        batch_match_query(1),
    ] {
        assert!(document.contains("fragment S on Media"));
        assert!(document.contains("...S"));
    }
}

#[test]
fn lists_exclude_adult_titles_at_the_source() {
    assert!(list_query(false, false).contains("isAdult: false"));
    assert!(search_query().contains("isAdult: false"));
    assert!(batch_match_query(2).contains("isAdult: false"));
}

#[test]
fn the_batch_asks_for_one_alias_per_title() {
    let document = batch_match_query(3);
    for index in 0..3 {
        assert!(document.contains(&format!("m{index}: Page(perPage: 3)")));
        assert!(document.contains(&format!("$t{index}: String")));
    }
    assert!(!document.contains("m3:"));
}

#[test]
fn the_discover_query_filters_by_text_genre_tag_and_dates_without_adult_titles() {
    let document = discover_query();
    for part in [
        "search: $search",
        "genre: $genre",
        "tag: $tag",
        "startDate_greater: $from",
        "startDate_lesser: $to",
        "format_in: $formats",
        "status: $status",
        "source: $source",
        "isAdult: false",
        "fragment S on Media",
    ] {
        assert!(document.contains(part), "{part}");
    }
}

#[test]
fn the_cover_query_asks_for_a_genre_and_a_tag_per_name_without_adult_titles() {
    let document = genre_covers_query(2);
    for index in 0..2 {
        assert!(document.contains(&format!("g{index}: Page(perPage: 4)")));
        assert!(document.contains(&format!("t{index}: Page(perPage: 4)")));
        assert!(document.contains(&format!("genre: $n{index}")));
        assert!(document.contains(&format!("tag: $n{index}")));
        assert!(document.contains(&format!("$n{index}: String")));
    }
    assert!(document.contains("isAdult: false"));
    assert!(document.contains("genre_not_in: [\"Hentai\", \"Ecchi\"]"));
    assert!(document.contains("tag: $n0, minimumTagRank: 80,"));
    assert!(!document.contains("genre: $n0, minimumTagRank"));
    assert!(!document.contains("g2:"));
}

#[test]
fn the_detail_asks_for_cast_staff_relations_and_recommendations() {
    let document = detail_query();
    for field in [
        "characters(",
        "staff(",
        "relations {",
        "recommendations(",
        "nextAiringEpisode",
    ] {
        assert!(document.contains(field), "{field}");
    }
}

#[test]
fn only_the_rich_list_asks_for_the_synopsis_and_the_sharp_cover() {
    let rich = list_query(true, false);
    assert!(rich.contains("synopsis: description(asHtml: false)"));
    assert!(rich.contains("coverImage { large extraLarge }"));
    let plain = list_query(false, false);
    assert!(!plain.contains("synopsis"));
    assert!(!plain.contains("extraLarge"));
}

#[test]
fn only_the_comeback_list_asks_for_prequel_links() {
    assert!(list_query(true, true).contains("prequels: relations"));
    assert!(!list_query(true, false).contains("prequels"));
    assert!(!list_query(false, false).contains("prequels"));
}

#[test]
fn the_list_query_accepts_a_status_and_date_window() {
    let document = list_query(false, false);
    assert!(document.contains("$status: MediaStatus"));
    assert!(document.contains("$startFrom: FuzzyDateInt"));
    assert!(document.contains("startDate_greater: $startFrom"));
    assert!(document.contains("endDate_greater: $endFrom"));
}
