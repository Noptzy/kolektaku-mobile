use std::sync::Arc;

use application::ports::MetadataCatalog;
use domain::media::{Discover, DiscoverSort, MediaKind, ProfileKind, YearSpan};
use infrastructure::catalog::anilist::AniListCatalog;
use infrastructure::clock::SystemClock;
use infrastructure::http::{RateLimitSettings, RateLimitedClient, ReqwestClient, SystemPause};

fn catalog() -> AniListCatalog {
    let transport = Arc::new(ReqwestClient::standard().unwrap());
    let http = RateLimitedClient::new(
        transport,
        Arc::new(SystemPause),
        RateLimitSettings::default(),
    );
    AniListCatalog::new(Arc::new(http), Arc::new(SystemClock))
}

const APP_GENRES: [&str; 41] = [
    "Action",
    "Adventure",
    "Avant Garde",
    "Award Winning",
    "Boys Love",
    "Comedy",
    "Demons",
    "Drama",
    "Ecchi",
    "Fantasy",
    "Game",
    "Girls Love",
    "Gourmet",
    "Harem",
    "Historical",
    "Horror",
    "Isekai",
    "Josei",
    "Kids",
    "Mahou Shoujo",
    "Martial Arts",
    "Mecha",
    "Military",
    "Music",
    "Mystery",
    "Parody",
    "Psychological",
    "Romance",
    "School",
    "Sci-Fi",
    "Seinen",
    "Shoujo",
    "Shounen",
    "Slice of Life",
    "Space",
    "Sports",
    "Super Power",
    "Supernatural",
    "Suspense",
    "Thriller",
    "Vampire",
];

#[tokio::test]
#[ignore = "live network"]
async fn anilist_serves_covers_for_every_app_genre_in_one_request() {
    let names: Vec<String> = APP_GENRES.iter().map(ToString::to_string).collect();
    let found = catalog()
        .genre_covers(MediaKind::Anime, &names)
        .await
        .unwrap();
    assert_eq!(found.len(), names.len());
    let empty: Vec<&str> = names
        .iter()
        .zip(&found)
        .filter(|(_, covers)| covers.is_empty())
        .map(|(name, _)| name.as_str())
        .collect();
    println!("genres without a cover: {empty:?}");
    assert!(empty.len() <= 5, "{empty:?}");
    assert!(
        found
            .iter()
            .flatten()
            .all(|url| url.starts_with("https://"))
    );
}

#[tokio::test]
#[ignore = "live network"]
async fn anilist_serves_manga_covers_too() {
    let names = vec!["Action".to_string(), "Romance".to_string()];
    let found = catalog()
        .genre_covers(MediaKind::Manga, &names)
        .await
        .unwrap();
    assert!(found.iter().all(|covers| !covers.is_empty()));
}

#[tokio::test]
#[ignore = "live network"]
async fn anilist_serves_a_character_with_the_titles_they_appear_in() {
    let profile = catalog()
        .profile(ProfileKind::Character, 127_518)
        .await
        .unwrap();
    assert_eq!(profile.name, "Nezuko Kamado");
    assert!(profile.image_url.is_some());
    assert!(!profile.description.is_empty());
    assert!(profile.appearances.len() >= 3);
    assert!(
        profile
            .appearances
            .iter()
            .all(|item| item.media.year.is_some())
    );
}

#[tokio::test]
#[ignore = "live network"]
async fn anilist_serves_a_voice_actor_with_the_characters_voiced() {
    let profile = catalog().profile(ProfileKind::Staff, 95_061).await.unwrap();
    assert_eq!(profile.name, "Chiwa Saitou");
    assert!(!profile.appearances.is_empty());
    assert!(
        profile
            .appearances
            .iter()
            .any(|item| !item.characters.is_empty())
    );
}

#[tokio::test]
#[ignore = "live network"]
async fn anilist_filters_a_genre_by_year_on_its_own_side() {
    let catalog = catalog();
    for years in [
        YearSpan::only(2015),
        YearSpan::up_to(2005),
        YearSpan::only(2026),
    ] {
        let filter = Discover::in_genre("Action").within(years);
        let page = catalog
            .discover(MediaKind::Anime, &filter, 1)
            .await
            .unwrap();
        assert!(!page.items.is_empty(), "{years:?}");
        assert!(
            page.items
                .iter()
                .all(|item| item.year.is_some_and(|year| years.contains(year))),
            "{years:?}"
        );
    }
}

#[tokio::test]
#[ignore = "live network"]
async fn anilist_filters_a_tag_genre_and_a_search_by_year() {
    let catalog = catalog();
    let tag = Discover::in_genre("CGDCT").within(YearSpan::only(2018));
    let tagged = catalog.discover(MediaKind::Anime, &tag, 1).await.unwrap();
    assert!(!tagged.items.is_empty());
    let search = Discover::searching("kimi no na wa").within(YearSpan::only(2016));
    let found = catalog
        .discover(MediaKind::Anime, &search, 1)
        .await
        .unwrap();
    assert!(
        found
            .items
            .iter()
            .any(|item| item.title.romaji.contains("Kimi no Na wa"))
    );
    let oldest = Discover::in_genre("Drama").sorted(DiscoverSort::Oldest);
    let first = catalog
        .discover(MediaKind::Anime, &oldest, 1)
        .await
        .unwrap();
    assert!(!first.items.is_empty());
}
