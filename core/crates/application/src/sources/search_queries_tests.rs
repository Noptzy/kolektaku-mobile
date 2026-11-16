use domain::media::{MediaId, MediaKind, MediaSummary, MediaTitle};

use super::search_queries::search_queries;

fn media(romaji: &str, english: Option<&str>, synonyms: &[&str]) -> MediaSummary {
    let mut title = MediaTitle::new(romaji);
    title.english = english.map(str::to_string);
    let mut media = MediaSummary::new(MediaId::new(1).unwrap(), MediaKind::Manga, title);
    media.synonyms = synonyms.iter().map(|name| name.to_string()).collect();
    media
}

#[test]
fn the_romaji_title_comes_first_then_the_english_one() {
    let queries = search_queries(&media("Kimi no Na wa.", Some("Your Name."), &[]));
    assert_eq!(queries, vec!["Kimi no Na wa.", "Your Name."]);
}

#[test]
fn an_english_title_equal_to_the_romaji_is_not_asked_twice() {
    let queries = search_queries(&media("Naruto", Some("naruto"), &[]));
    assert_eq!(queries, vec!["Naruto"]);
}

#[test]
fn a_blank_english_title_is_skipped() {
    let queries = search_queries(&media("Naruto", Some("   "), &[]));
    assert_eq!(queries, vec!["Naruto"]);
}

#[test]
fn latin_synonyms_follow_in_the_order_they_were_given() {
    let queries = search_queries(&media(
        "Bireomeogeul Hwansaeng",
        Some("My Blasted Reincarnated Life"),
        &["Damn Reincarnation", "Reincarnation Without Damage"],
    ));
    assert_eq!(
        queries,
        vec![
            "Bireomeogeul Hwansaeng",
            "My Blasted Reincarnated Life",
            "Damn Reincarnation",
            "Reincarnation Without Damage",
        ]
    );
}

#[test]
fn synonyms_in_other_scripts_are_not_searched() {
    let queries = search_queries(&media(
        "Mo Huang Da Guanjia",
        None,
        &[
            "三流反派的學院生存記",
            "จอมเขมือบกู้โลก",
            "ログイン武林",
            "Magic Emperor",
        ],
    ));
    assert_eq!(queries, vec!["Mo Huang Da Guanjia", "Magic Emperor"]);
}

#[test]
fn titles_that_are_too_short_to_search_are_skipped() {
    let queries = search_queries(&media("One Piece", None, &["OP", "1", "  "]));
    assert_eq!(queries, vec!["One Piece"]);
}

#[test]
fn a_synonym_repeating_an_earlier_title_in_other_case_is_dropped() {
    let queries = search_queries(&media("ONE PIECE", Some("One Piece"), &["one piece"]));
    assert_eq!(queries, vec!["ONE PIECE"]);
}

#[test]
fn at_most_three_synonyms_are_added_so_the_search_stays_bounded() {
    let queries = search_queries(&media(
        "Main",
        Some("English"),
        &["Alias One", "Alias Two", "Alias Three", "Alias Four"],
    ));
    assert_eq!(queries.len(), 5);
    assert_eq!(queries.last().map(String::as_str), Some("Alias Three"));
}

#[test]
fn a_title_in_brackets_is_also_asked_without_them() {
    let queries = search_queries(&media("[Oshi no Ko]", None, &[]));
    assert_eq!(queries, vec!["[Oshi no Ko]", "Oshi no Ko"]);
}

#[test]
fn the_variant_without_brackets_sits_next_to_its_title() {
    let queries = search_queries(&media("[Oshi no Ko]", Some("Oshi no Ko: Idol"), &[]));
    assert_eq!(
        queries,
        vec![
            "[Oshi no Ko]",
            "Oshi no Ko",
            "Oshi no Ko: Idol",
            "Oshi no Ko Idol"
        ]
    );
}

#[test]
fn a_variant_that_repeats_a_known_title_is_not_asked_twice() {
    let queries = search_queries(&media("[Oshi no Ko]", Some("Oshi no Ko"), &[]));
    assert_eq!(queries, vec!["[Oshi no Ko]", "Oshi no Ko"]);
}

#[test]
fn brackets_inside_a_title_leave_single_spaces() {
    let queries = search_queries(&media("Kaiju (No. 8) Special", None, &[]));
    assert_eq!(
        queries,
        vec!["Kaiju (No. 8) Special", "Kaiju No. 8 Special"]
    );
}

#[test]
fn a_title_with_a_colon_or_an_exclamation_mark_is_also_asked_without_them() {
    let queries = search_queries(&media("86: Eighty Six", None, &[]));
    assert_eq!(queries, vec!["86: Eighty Six", "86 Eighty Six"]);
    let queries = search_queries(&media("Kono Subarashii Sekai ni Shukufuku wo!", None, &[]));
    assert_eq!(
        queries,
        vec![
            "Kono Subarashii Sekai ni Shukufuku wo!",
            "Kono Subarashii Sekai ni Shukufuku wo"
        ]
    );
}

#[test]
fn a_plain_title_gets_no_extra_variant() {
    let queries = search_queries(&media("Naruto", Some("Naruto Shippuden"), &[]));
    assert_eq!(queries, vec!["Naruto", "Naruto Shippuden"]);
}

#[test]
fn vietnamese_and_accented_latin_titles_are_allowed() {
    let queries = search_queries(&media("Main", None, &["Vua Hải Tặc", "Café Étoilé"]));
    assert_eq!(queries, vec!["Main", "Vua Hải Tặc", "Café Étoilé"]);
}
