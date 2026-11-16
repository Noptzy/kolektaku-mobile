use domain::media::{MediaId, MediaKind, MediaSummary, MediaTitle};

use super::search_queries::search_queries;

fn media(romaji: &str, english: Option<&str>, synonyms: &[&str]) -> MediaSummary {
    let mut title = MediaTitle::new(romaji);
    title.english = english.map(str::to_string);
    let mut media = MediaSummary::new(MediaId::new(1).unwrap(), MediaKind::Anime, title);
    media.synonyms = synonyms.iter().map(|name| name.to_string()).collect();
    media
}

#[test]
fn a_subtitled_title_also_asks_for_its_distinctive_parts_without_the_noise() {
    let queries = search_queries(&media(
        "Kimetsu no Yaiba: Mugenjou-hen Movie 1 - Akaza Sairai",
        None,
        &[],
    ));
    assert_eq!(
        queries,
        vec![
            "Kimetsu no Yaiba: Mugenjou-hen Movie 1 - Akaza Sairai",
            "Kimetsu no Yaiba Mugenjou-hen Movie 1 - Akaza Sairai",
            "Akaza Sairai",
            "Mugenjou-hen",
            "Kimetsu no Yaiba",
        ]
    );
}

#[test]
fn fragments_come_after_every_full_title_and_synonym() {
    let queries = search_queries(&media(
        "Sword Art Online: Alicization",
        Some("Sword Art Online Alicization"),
        &["SAO Alicization Arc"],
    ));
    let first_fragment = queries
        .iter()
        .position(|query| query == "Alicization")
        .unwrap();
    let last_full = queries
        .iter()
        .position(|query| query == "SAO Alicization Arc")
        .unwrap();
    assert!(first_fragment > last_full);
}

#[test]
fn a_title_without_a_subtitle_adds_no_fragments() {
    let queries = search_queries(&media("Steins;Gate", None, &[]));
    assert!(queries.iter().all(|query| query.starts_with("Steins")));
}

#[test]
fn a_fragment_that_is_only_noise_is_dropped_and_the_head_stays() {
    let queries = search_queries(&media("Gintama: The Movie", None, &[]));
    assert_eq!(
        queries,
        vec!["Gintama: The Movie", "Gintama The Movie", "Gintama"]
    );
}

#[test]
fn fragments_are_bounded_and_never_repeat_an_earlier_query() {
    let queries = search_queries(&media(
        "Alpha Beta: Gamma Delta - Epsilon Zeta - Theta Iota - Kappa Lambda",
        None,
        &[],
    ));
    let fragments = queries.len() - 2;
    assert!(fragments <= 3);
    let mut sorted: Vec<String> = queries.iter().map(|query| query.to_lowercase()).collect();
    sorted.sort();
    sorted.dedup();
    assert_eq!(sorted.len(), queries.len());
}
