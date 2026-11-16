use domain::media::{MediaId, MediaKind, MediaSummary, MediaTitle};
use domain::source::SourceId;

use super::assign_page::{PageItem, assign_page};

fn media(id: u64, romaji: &str, synonyms: &[&str]) -> MediaSummary {
    let mut summary = MediaSummary::new(
        MediaId::new(id).unwrap(),
        MediaKind::Anime,
        MediaTitle::new(romaji),
    );
    summary.synonyms = synonyms.iter().map(|name| name.to_string()).collect();
    summary
}

fn item(source: &str, title: &str) -> PageItem {
    PageItem {
        source: SourceId::new(source),
        title: title.into(),
    }
}

fn pairs(assignments: &[super::assign_page::Assignment]) -> Vec<(usize, usize)> {
    let mut found: Vec<(usize, usize)> = assignments
        .iter()
        .map(|assignment| (assignment.item_index, assignment.media_index))
        .collect();
    found.sort_unstable();
    found
}

#[test]
fn a_main_title_beats_the_same_text_as_a_synonym() {
    let catalog = [
        media(
            97962,
            "Suntory Minami Alps no Tennen Mizu",
            &["Kimi no Na wa."],
        ),
        media(21519, "Kimi no Na wa.", &[]),
    ];
    let found = assign_page(&catalog, &[item("a", "Kimi no Na wa.")]);
    assert_eq!(pairs(&found), vec![(0, 1)]);
    assert_eq!(found[0].score, 1.0);
}

#[test]
fn a_synonym_match_still_counts_but_at_nine_tenths() {
    let catalog = [media(1, "Shingeki no Kyojin", &["Attack on Titan"])];
    let found = assign_page(&catalog, &[item("a", "Attack on Titan")]);
    assert_eq!(pairs(&found), vec![(0, 0)]);
    assert!((found[0].score - 0.9).abs() < 1e-9);
}

#[test]
fn an_entry_goes_to_one_item_per_site_the_better_one_first() {
    let catalog = [media(1, "Naruto", &[]), media(2, "Naruto Shippuden", &[])];
    let items = [item("a", "Naruto Shippuuden"), item("a", "Naruto")];
    let found = assign_page(&catalog, &items);
    assert_eq!(pairs(&found), vec![(0, 1), (1, 0)]);
}

#[test]
fn two_sites_may_both_claim_the_same_entry() {
    let catalog = [media(1, "Naruto", &[])];
    let items = [item("a", "Naruto"), item("b", "Naruto")];
    assert_eq!(pairs(&assign_page(&catalog, &items)), vec![(0, 0), (1, 0)]);
}

#[test]
fn one_site_cannot_claim_the_same_entry_twice() {
    let catalog = [media(1, "Naruto", &[])];
    let items = [item("a", "Naruto"), item("a", "Naruto!")];
    assert_eq!(pairs(&assign_page(&catalog, &items)), vec![(0, 0)]);
}

#[test]
fn one_item_never_takes_two_entries() {
    let catalog = [media(1, "Naruto", &[]), media(2, "Naruto", &[])];
    assert_eq!(
        pairs(&assign_page(&catalog, &[item("a", "Naruto")])),
        vec![(0, 0)]
    );
}

#[test]
fn titles_that_do_not_resemble_each_other_stay_unassigned() {
    let catalog = [media(1, "One Piece", &[])];
    assert!(assign_page(&catalog, &[item("a", "Bleach")]).is_empty());
}

#[test]
fn the_promo_item_stays_apart_from_the_film_it_mentions() {
    let catalog = [media(21519, "Kimi no Na wa.", &[])];
    let items = [item(
        "a",
        "Suntory Minami Alps no Tennensui: Kimi no Na wa.",
    )];
    assert!(assign_page(&catalog, &items).is_empty());
}

#[test]
fn equal_scores_prefer_the_higher_ranked_catalog_entry() {
    let catalog = [media(1, "Hero", &[]), media(2, "Hero", &[])];
    assert_eq!(
        pairs(&assign_page(&catalog, &[item("a", "Hero")])),
        vec![(0, 0)]
    );
}

#[test]
fn a_later_season_is_not_the_first_one() {
    let catalog = [
        media(1, "Oshi no Ko", &[]),
        media(2, "Oshi no Ko 2nd Season", &[]),
    ];
    let found = assign_page(&catalog, &[item("a", "Oshi no Ko Season 2")]);
    assert_eq!(pairs(&found), vec![(0, 1)]);
}

#[test]
fn nothing_in_nothing_out() {
    assert!(assign_page(&[], &[item("a", "x")]).is_empty());
    assert!(assign_page(&[media(1, "x", &[])], &[]).is_empty());
}

#[test]
fn a_dub_twin_never_takes_the_slot_of_its_plain_entry_even_when_listed_first() {
    use domain::media::{MediaId, MediaKind, MediaTitle};
    use domain::source::SourceId;

    let media = vec![MediaSummary::new(
        MediaId::new(101922).unwrap(),
        MediaKind::Anime,
        MediaTitle::new("Kimetsu no Yaiba"),
    )];
    let items = vec![
        PageItem {
            source: SourceId::new("a"),
            title: "Kimetsu no Yaiba (Dub ID)".into(),
        },
        PageItem {
            source: SourceId::new("a"),
            title: "Kimetsu no Yaiba".into(),
        },
    ];
    let chosen = assign_page(&media, &items);
    assert_eq!(chosen.len(), 1);
    assert_eq!(chosen[0].item_index, 1);
}
