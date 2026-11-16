use std::sync::Arc;

use application::testing::FakeClock;
use domain::library::{FavoriteInput, LibraryRepository, ProgressInput, UnitOrder};
use domain::matching::Confidence;
use domain::media::{MediaId, MediaKind, MediaRef};
use domain::source::{ItemId, SourceId, SourceLink, SourceLinkStore};

use super::import_json::{ImportReport, import_legacy};
use super::{Database, SqliteLibraryRepository, SqliteSourceLinkStore};
use crate::storage::{JsonLibraryRepository, JsonSourceLinkStore, TempFolder};

fn media(id: u64) -> MediaRef {
    MediaRef::catalog(MediaId::new(id).unwrap())
}

async fn old_data(folder: &TempFolder) {
    let library =
        JsonLibraryRepository::new(folder.file("library.json"), Arc::new(FakeClock::at(42)));
    for id in [1, 2] {
        let favorite = FavoriteInput {
            media: media(id),
            kind: MediaKind::Anime,
            title: format!("title {id}"),
            cover_url: None,
        };
        library.toggle_favorite(favorite).await.unwrap();
    }
    for (unit, at) in [(1.0, 10), (2.0, 11)] {
        let progress = ProgressInput {
            media: media(1),
            kind: MediaKind::Anime,
            unit_number: unit,
            title: "Frieren".into(),
            cover_url: None,
            position: 100.0,
            length: 1440.0,
            updated_at_secs: at,
        };
        library.save_progress(progress).await.unwrap();
    }
    library
        .set_unit_order(MediaKind::Anime, &media(1), UnitOrder::Desc)
        .await
        .unwrap();
    library
        .set_preference("setting.auto_next", "0")
        .await
        .unwrap();
    library
        .add_search(MediaKind::Anime, "frieren")
        .await
        .unwrap();
    library
        .add_search(MediaKind::Manga, "berserk")
        .await
        .unwrap();
    let links = JsonSourceLinkStore::new(folder.file("source_links.json"));
    let link = SourceLink::matched(
        SourceId::new("a"),
        ItemId::new("a-1"),
        Confidence::new(0.9),
        5,
    );
    links.save_all(&media(1), vec![link]).await.unwrap();
}

#[tokio::test]
async fn every_old_record_arrives_and_the_old_files_are_kept_aside() {
    let folder = TempFolder::new("import-all");
    old_data(&folder).await;
    let database = Database::open(&folder.file("kolektaku.db")).unwrap();
    let report = import_legacy(&database, &folder.file(""))
        .await
        .unwrap()
        .unwrap();
    assert_eq!(
        report,
        ImportReport {
            favorites: 2,
            history: 2,
            unit_orders: 1,
            searches: 2,
            preferences: 1,
            links: 1
        }
    );
    let library = SqliteLibraryRepository::new(database.clone(), Arc::new(FakeClock::at(1)));
    assert_eq!(library.favorites(MediaKind::Anime).await.unwrap().len(), 2);
    assert_eq!(library.history(MediaKind::Anime).await.unwrap().len(), 2);
    let order = library
        .unit_order(MediaKind::Anime, &media(1))
        .await
        .unwrap();
    assert_eq!(order, UnitOrder::Desc);
    let pref = library.preference("setting.auto_next").await.unwrap();
    assert_eq!(pref.as_deref(), Some("0"));
    assert_eq!(
        library.searches(MediaKind::Manga).await.unwrap(),
        vec!["berserk"]
    );
    let links = SqliteSourceLinkStore::new(database);
    let found = links.links_for(&media(1)).await.unwrap();
    assert_eq!(found[0].item.as_str(), "a-1");
    assert_eq!(found[0].matcher_version, 0);
    assert!(!folder.file("library.json").exists());
    assert!(folder.file("library.json.migrated").exists());
    assert!(folder.file("source_links.json.migrated").exists());
}

#[tokio::test]
async fn running_it_twice_does_not_double_anything() {
    let folder = TempFolder::new("import-twice");
    old_data(&folder).await;
    let database = Database::open(&folder.file("kolektaku.db")).unwrap();
    import_legacy(&database, &folder.file("")).await.unwrap();
    assert_eq!(
        import_legacy(&database, &folder.file("")).await.unwrap(),
        None
    );
    std::fs::copy(
        folder.file("library.json.migrated"),
        folder.file("library.json"),
    )
    .unwrap();
    import_legacy(&database, &folder.file("")).await.unwrap();
    let library = SqliteLibraryRepository::new(database, Arc::new(FakeClock::at(1)));
    assert_eq!(library.favorites(MediaKind::Anime).await.unwrap().len(), 2);
    assert_eq!(library.history(MediaKind::Anime).await.unwrap().len(), 2);
}

#[tokio::test]
async fn a_new_install_has_nothing_to_bring_in() {
    let folder = TempFolder::new("import-none");
    let database = Database::open(&folder.file("kolektaku.db")).unwrap();
    assert_eq!(
        import_legacy(&database, &folder.file("")).await.unwrap(),
        None
    );
}

#[tokio::test]
async fn a_broken_file_is_left_alone_and_does_not_stop_the_good_one() {
    let folder = TempFolder::new("import-broken");
    std::fs::write(folder.file("library.json"), "{ not json").unwrap();
    let links = JsonSourceLinkStore::new(folder.file("source_links.json"));
    let link = SourceLink::matched(
        SourceId::new("a"),
        ItemId::new("a-1"),
        Confidence::new(0.9),
        5,
    );
    links.save_all(&media(3), vec![link]).await.unwrap();
    let database = Database::open(&folder.file("kolektaku.db")).unwrap();
    let report = import_legacy(&database, &folder.file(""))
        .await
        .unwrap()
        .unwrap();
    assert_eq!(report.links, 1);
    assert!(folder.file("library.json").exists());
    assert!(!folder.file("library.json.migrated").exists());
    assert!(folder.file("source_links.json.migrated").exists());
}
