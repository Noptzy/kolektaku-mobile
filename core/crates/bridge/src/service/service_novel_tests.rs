use application::testing::FakeCatalog;
use domain::media::{MediaId, MediaKind, MediaListKind, MediaSummary, MediaTitle};

use super::service_support::{Folder, catalog_ref, state_with_catalog};
use super::{browse, library};
use crate::dto::library::FavoriteDto;
use crate::dto::media::MediaKindDto;

fn novel(id: u64, title: &str) -> MediaSummary {
    MediaSummary::new(
        MediaId::new(id).unwrap(),
        MediaKind::Novel,
        MediaTitle::new(title),
    )
}

fn favorite(kind: MediaKindDto) -> FavoriteDto {
    FavoriteDto {
        reference: catalog_ref(),
        kind,
        title: "Overlord".into(),
        cover_url: None,
        added_at_secs: 0,
    }
}

#[tokio::test]
async fn novel_favorites_are_kept_apart_from_comics_and_anime() {
    let folder = Folder::new();
    let state = state_with_catalog(&folder, FakeCatalog::new()).await;
    assert!(
        library::toggle_favorite(&state, favorite(MediaKindDto::Novel))
            .await
            .unwrap()
    );
    let novels = library::favorites(&state, MediaKindDto::Novel)
        .await
        .unwrap();
    assert_eq!(novels.len(), 1);
    assert_eq!(novels[0].kind, MediaKindDto::Novel);
    for other in [MediaKindDto::Manga, MediaKindDto::Anime] {
        assert!(library::favorites(&state, other).await.unwrap().is_empty());
        let marked = library::is_favorite(&state, other, &catalog_ref()).await;
        assert!(!marked.unwrap());
    }
}

#[tokio::test]
async fn searching_novels_asks_the_catalog_for_novels() {
    let folder = Folder::new();
    let catalog =
        FakeCatalog::new().with_search(MediaKind::Novel, "overlord", vec![novel(7, "Overlord")]);
    let state = state_with_catalog(&folder, catalog).await;
    let page = browse::search(&state, MediaKindDto::Novel, "overlord", 1)
        .await
        .unwrap();
    assert_eq!(page.cards.len(), 1);
    assert_eq!(page.cards[0].title, "Overlord");
    let comics = browse::search(&state, MediaKindDto::Manga, "overlord", 1)
        .await
        .unwrap();
    assert!(comics.cards.is_empty());
}

#[tokio::test]
async fn the_novel_home_has_one_popular_rail() {
    let folder = Folder::new();
    let catalog = FakeCatalog::new().with_list(
        MediaKind::Novel,
        MediaListKind::Popular,
        vec![novel(7, "Overlord"), novel(8, "Re:Zero")],
    );
    let state = state_with_catalog(&folder, catalog).await;
    let home = browse::home(&state, MediaKindDto::Novel).await.unwrap();
    assert_eq!(home.sections.len(), 1);
    assert_eq!(home.sections[0].cards.len(), 2);
}
