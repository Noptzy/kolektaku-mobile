use domain::media::{MediaKind, MediaRef};

use super::search_test_support::{anime, harness, item, source};
use crate::testing::FakeCatalog;

fn catalog_with(query: &str, found: Vec<domain::media::MediaSummary>) -> FakeCatalog {
    FakeCatalog::new().with_search(MediaKind::Anime, query, found)
}

#[tokio::test]
async fn a_matched_item_and_entry_become_one_card_with_a_capped_link() {
    let h = harness(
        catalog_with("naruto", vec![anime(20, "Naruto", &[])]),
        vec![source("a").with_search("naruto", vec![item("1/naruto", "Naruto")])],
    );
    let outcome = h
        .use_case
        .execute(MediaKind::Anime, "naruto", 1)
        .await
        .unwrap();
    assert_eq!(outcome.cards.len(), 1);
    let card = &outcome.cards[0];
    assert!(matches!(card.reference, MediaRef::Catalog { .. }));
    assert_eq!(card.links.len(), 1);
    assert_eq!(card.links[0].source.as_str(), "a");
    assert_eq!(card.links[0].item.as_str(), "1/naruto");
    assert!(card.links[0].confidence.get() <= 0.84);
    assert!(!card.links[0].manual && card.links[0].checked_at_secs == 1_000);
    assert!(card.summary.is_some());
}

#[tokio::test]
async fn kimi_no_na_wa_keeps_the_film_and_the_promo_as_separate_cards() {
    let promo = anime(
        97962,
        "Suntory Minami Alps no Tennen Mizu",
        &["Suntory Minami Alps no Tennensui", "Kimi no Na wa."],
    );
    let film = anime(21519, "Kimi no Na wa.", &["Your Name."]);
    let h = harness(
        catalog_with("kimi no na wa", vec![promo, film]),
        vec![source("a").with_search(
            "kimi no na wa",
            vec![
                item("1020/kimi-no-na-wa", "Kimi no Na wa."),
                item("1021/suntory", "Suntory Minami Alps no Tennensui"),
            ],
        )],
    );
    let outcome = h
        .use_case
        .execute(MediaKind::Anime, "kimi no na wa", 1)
        .await
        .unwrap();
    assert_eq!(outcome.cards.len(), 2);
    let film_card = outcome
        .cards
        .iter()
        .find(|card| card.title == "Kimi no Na wa.")
        .unwrap();
    assert_eq!(film_card.links[0].item.as_str(), "1020/kimi-no-na-wa");
    let promo_card = outcome
        .cards
        .iter()
        .find(|card| card.title.starts_with("Suntory"))
        .unwrap();
    assert_eq!(promo_card.links[0].item.as_str(), "1021/suntory");
}

#[tokio::test]
async fn your_name_finds_the_film_through_anilist_alone() {
    let h = harness(
        catalog_with(
            "your name",
            vec![anime(21519, "Kimi no Na wa.", &["Your Name."])],
        ),
        vec![source("a")],
    );
    let outcome = h
        .use_case
        .execute(MediaKind::Anime, "your name", 1)
        .await
        .unwrap();
    assert_eq!(outcome.cards.len(), 1);
    assert!(outcome.cards[0].links.is_empty());
}

#[tokio::test]
async fn a_site_item_unknown_to_anilist_still_appears_and_stays_playable() {
    let h = harness(
        catalog_with("judul", vec![anime(1, "Judul Lain Sekali", &[])]),
        vec![source("a").with_search("judul", vec![item("9/judul-aneh", "Judul Aneh Banget")])],
    );
    let outcome = h
        .use_case
        .execute(MediaKind::Anime, "judul", 1)
        .await
        .unwrap();
    assert_eq!(outcome.cards.len(), 2);
    let only = outcome
        .cards
        .iter()
        .find(|card| card.summary.is_none())
        .unwrap();
    assert_eq!(only.title, "Judul Aneh Banget");
    assert!(matches!(only.reference, MediaRef::Source { .. }));
    assert_eq!(only.links.len(), 1);
}

#[tokio::test]
async fn two_sites_with_the_same_title_share_one_catalog_card() {
    let h = harness(
        catalog_with("naruto", vec![anime(20, "Naruto", &[])]),
        vec![
            source("a").with_search("naruto", vec![item("1/naruto", "Naruto")]),
            source("b").with_search("naruto", vec![item("naruto-x", "Naruto")]),
        ],
    );
    let outcome = h
        .use_case
        .execute(MediaKind::Anime, "naruto", 1)
        .await
        .unwrap();
    assert_eq!(outcome.cards.len(), 1);
    let sources: Vec<&str> = outcome.cards[0]
        .links
        .iter()
        .map(|link| link.source.as_str())
        .collect();
    assert_eq!(sources, vec!["a", "b"]);
}

#[tokio::test]
async fn the_same_unknown_title_on_two_sites_is_one_card_with_two_links() {
    let h = harness(
        catalog_with("zzz", vec![]),
        vec![
            source("a").with_search("zzz", vec![item("1/zzz", "Zzz Show")]),
            source("b").with_search("zzz", vec![item("zzz-show", "Zzz Show")]),
        ],
    );
    let outcome = h
        .use_case
        .execute(MediaKind::Anime, "zzz", 1)
        .await
        .unwrap();
    assert_eq!(outcome.cards.len(), 1);
    assert_eq!(outcome.cards[0].links.len(), 2);
}

#[tokio::test]
async fn the_site_label_and_cover_fill_in_when_the_catalog_has_none() {
    let mut with_art = item("1/naruto", "Naruto");
    with_art.cover_url = Some("https://img.test/naruto.jpg".into());
    with_art.latest_label = Some("Ep 220".into());
    let h = harness(
        catalog_with("naruto", vec![anime(20, "Naruto", &[])]),
        vec![source("a").with_search("naruto", vec![with_art])],
    );
    let card = h
        .use_case
        .execute(MediaKind::Anime, "naruto", 1)
        .await
        .unwrap()
        .cards
        .remove(0);
    assert_eq!(
        card.cover_url.as_deref(),
        Some("https://img.test/naruto.jpg")
    );
    assert_eq!(card.latest_label.as_deref(), Some("Ep 220"));
}
