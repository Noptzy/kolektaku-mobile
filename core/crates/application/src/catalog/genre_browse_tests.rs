use std::sync::Arc;

use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::SourceOrder;

use super::GenreBrowse;
use super::search_test_support::{anime, item};
use crate::ports::SourceProvider;
use crate::testing::{FakeCatalog, FakeClock, FakeGenres, FakeSource};

fn browse(catalog: FakeCatalog, sources: Vec<FakeSource>) -> GenreBrowse<FakeCatalog> {
    let providers: Vec<Arc<dyn SourceProvider>> = sources
        .into_iter()
        .map(|source| Arc::new(source) as Arc<dyn SourceProvider>)
        .collect();
    GenreBrowse::new(Arc::new(catalog), providers, Arc::new(FakeClock::at(3)))
}

fn site(id: &str, genres: FakeGenres) -> FakeSource {
    FakeSource::new(id, MediaKind::Anime).with_genres(genres)
}

#[tokio::test]
async fn genres_of_all_sites_are_merged_without_duplicates_in_site_order() {
    let a = site(
        "a",
        FakeGenres::new(&[("action", "Action"), ("drama", "Drama")]),
    );
    let b = site(
        "b",
        FakeGenres::new(&[("drama", "Drama!"), ("comedy", "Comedy")]),
    );
    let genres = browse(FakeCatalog::new(), vec![a, b])
        .genres()
        .await
        .unwrap();
    let slugs: Vec<&str> = genres.iter().map(|genre| genre.slug.as_str()).collect();
    assert_eq!(slugs, vec!["action", "drama", "comedy"]);
    assert_eq!(genres[1].name, "Drama");
}

#[tokio::test]
async fn a_site_without_genres_is_simply_skipped() {
    let plain = FakeSource::new("plain", MediaKind::Anime);
    let with = site("a", FakeGenres::new(&[("action", "Action")]));
    assert_eq!(
        browse(FakeCatalog::new(), vec![plain, with])
            .genres()
            .await
            .unwrap()
            .len(),
        1
    );
}

#[tokio::test]
async fn a_failing_site_only_matters_when_nobody_else_answers() {
    let down =
        site("a", FakeGenres::new(&[])).failing_with(SourceError::Unavailable("down".into()));
    let ok = site("b", FakeGenres::new(&[("action", "Action")]));
    assert_eq!(
        browse(FakeCatalog::new(), vec![down, ok])
            .genres()
            .await
            .unwrap()
            .len(),
        1
    );
    let only_down =
        site("a", FakeGenres::new(&[])).failing_with(SourceError::Unavailable("down".into()));
    let error = browse(FakeCatalog::new(), vec![only_down])
        .genres()
        .await
        .unwrap_err();
    assert!(matches!(error, SourceError::Unavailable(_)));
}

#[tokio::test]
async fn a_genre_page_links_site_items_to_the_catalog() {
    let a = site(
        "a",
        FakeGenres::new(&[("action", "Action")]).with_page(
            "action",
            vec![item("1/alpha", "Alpha"), item("2/mystery", "Mystery")],
        ),
    );
    let catalog =
        FakeCatalog::new().with_candidates(MediaKind::Anime, "Alpha", vec![anime(1, "Alpha", &[])]);
    let page = browse(catalog, vec![a])
        .by_genre(MediaKind::Anime, "action", 1, SourceOrder::Newest)
        .await
        .unwrap();
    assert_eq!(page.cards.len(), 2);
    assert!(page.cards[0].summary.is_some());
    assert!(page.cards[1].summary.is_none());
}

#[tokio::test]
async fn a_site_lacking_the_genre_is_ignored_while_others_answer() {
    let without = site("a", FakeGenres::new(&[("drama", "Drama")]));
    let with = site(
        "b",
        FakeGenres::new(&[("action", "Action")]).with_page("action", vec![item("b-1", "Alpha")]),
    );
    let page = browse(FakeCatalog::new(), vec![without, with])
        .by_genre(MediaKind::Anime, "action", 1, SourceOrder::Az)
        .await
        .unwrap();
    assert_eq!(page.cards.len(), 1);
    assert!(page.notices.is_empty());
}

#[tokio::test]
async fn a_real_failure_with_no_other_answer_is_reported() {
    let down = site("a", FakeGenres::new(&[])).failing_with(SourceError::Network("offline".into()));
    let error = browse(FakeCatalog::new(), vec![down])
        .by_genre(MediaKind::Anime, "action", 1, SourceOrder::Newest)
        .await
        .unwrap_err();
    assert_eq!(error, SourceError::Network("offline".into()));
}

#[tokio::test]
async fn a_genre_nobody_has_is_an_empty_page() {
    let a = site("a", FakeGenres::new(&[("drama", "Drama")]));
    let page = browse(FakeCatalog::new(), vec![a])
        .by_genre(MediaKind::Anime, "ghost", 1, SourceOrder::Newest)
        .await
        .unwrap();
    assert!(page.cards.is_empty() && !page.has_next_page);
}
