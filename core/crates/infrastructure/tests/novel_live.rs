use std::sync::Arc;

use application::ports::MetadataCatalog;
use application::ports::{Clock, SourceProvider};
use application::sources::{ResolveSources, SourceHealth};
use domain::media::MediaKind;
use domain::source::{ItemId, SourceSearch, TextBlock};
use infrastructure::catalog::anilist::AniListCatalog;
use infrastructure::clock::SystemClock;
use infrastructure::config::merge;
use infrastructure::http::{HttpClient, ReqwestClient};
use infrastructure::http::{RateLimitSettings, RateLimitedClient, SystemPause};
use infrastructure::sources::registry::{SourceEnv, SourceRegistry, all_defaults};
use infrastructure::storage::JsonSourceLinkStore;

fn novel_sources() -> Vec<Arc<dyn SourceProvider>> {
    let http: Arc<dyn HttpClient> = Arc::new(ReqwestClient::standard().unwrap());
    let clock: Arc<dyn Clock> = Arc::new(SystemClock);
    let env = SourceEnv { http, clock };
    let registry = SourceRegistry::build(&env, &merge(&all_defaults(), None).settings);
    registry.for_kind(MediaKind::Novel)
}

#[tokio::test]
#[ignore = "talks to the novel sites"]
async fn the_first_novel_source_reads_a_title_from_search_to_its_text() {
    let sources = novel_sources();
    let source = sources
        .iter()
        .find(|source| source.info().id.as_str() == "meionovels")
        .expect("the first novel source is registered");
    let found = source
        .search(SourceSearch::new("mushoku tensei"))
        .await
        .unwrap();
    let item = found
        .items
        .iter()
        .find(|item| item.item_id.as_str() == "mushoku-tensei-ln")
        .expect("the title is found");
    assert_eq!(item.title, "Mushoku Tensei");
    let detail = source.detail(item.item_id.clone()).await.unwrap();
    assert!(detail.unit_count.unwrap_or(0) >= 400);
    let units = source
        .units(ItemId::new("mushoku-tensei-ln"))
        .await
        .unwrap();
    assert!(units.len() >= 400, "{} chapters", units.len());
    assert_eq!(units[0].number, 1.0);
    assert!(units[0].label.contains("Chapter 0"), "{}", units[0].label);
    let first_real = &units[1];
    let text = source
        .texts()
        .unwrap()
        .chapter_text(first_real.id.clone())
        .await
        .unwrap();
    assert_eq!(text.language, "id");
    assert!(text.paragraphs().count() > 30);
    let illustrated = source
        .texts()
        .unwrap()
        .chapter_text(units[0].id.clone())
        .await
        .unwrap();
    assert!(
        illustrated
            .blocks
            .iter()
            .any(|block| matches!(block, TextBlock::Image(_)))
    );
}

#[tokio::test]
#[ignore = "talks to the novel sites"]
async fn the_latest_list_pages_forward() {
    let sources = novel_sources();
    let source = sources
        .iter()
        .find(|source| source.info().id.as_str() == "meionovels")
        .expect("the first novel source is registered");
    let first = source.latest(1).await.unwrap();
    let second = source.latest(2).await.unwrap();
    assert!(!first.items.is_empty() && !second.items.is_empty());
    assert!(first.total_pages > 1);
    assert_ne!(first.items[0].item_id, second.items[0].item_id);
}

#[tokio::test]
#[ignore = "talks to the novel sites"]
async fn the_second_novel_source_lists_every_chapter_of_a_long_novel() {
    let sources = novel_sources();
    let source = sources
        .iter()
        .find(|source| source.info().id.as_str() == "novelphoenix")
        .expect("the second novel source is registered");
    let found = source
        .search(SourceSearch::new("the beginning after the end"))
        .await
        .unwrap();
    assert!(
        found
            .items
            .iter()
            .any(|item| item.item_id.as_str() == "the-beginning-after-the-end")
    );
    let detail = source
        .detail(ItemId::new("the-beginning-after-the-end"))
        .await
        .unwrap();
    let expected = detail.unit_count.unwrap() as usize;
    assert!(expected >= 300, "{expected}");
    let units = source
        .units(ItemId::new("the-beginning-after-the-end"))
        .await
        .unwrap();
    assert_eq!(units.len(), expected);
    assert_eq!(units[0].number, 1.0);
    assert_eq!(units[0].id, "the-beginning-after-the-end/chapter-1");
    let text = source
        .texts()
        .unwrap()
        .chapter_text(units[0].id.clone())
        .await
        .unwrap();
    assert_eq!(text.language, "en");
    assert!(text.paragraphs().count() >= 10);
}

const TITLES: [&str; 10] = [
    "Mushoku Tensei: Isekai Ittara Honki Dasu",
    "Re:Zero kara Hajimeru Isekai Seikatsu",
    "Overlord",
    "Sword Art Online",
    "86",
    "Youkoso Jitsuryoku Shijou Shugi no Kyoushitsu e",
    "Kusuriya no Hitorigoto",
    "Tensei shitara Slime Datta Ken",
    "Kono Subarashii Sekai ni Shukufuku wo!",
    "Ookami to Koushinryou",
];

#[tokio::test]
#[ignore = "talks to AniList and the novel sites"]
async fn ten_light_novels_are_matched_to_the_right_source_and_never_to_fan_fiction() {
    let transport = Arc::new(ReqwestClient::standard().unwrap());
    let plain: Arc<dyn HttpClient> = transport.clone();
    let limited: Arc<dyn HttpClient> = Arc::new(RateLimitedClient::new(
        transport,
        Arc::new(SystemPause),
        RateLimitSettings::default(),
    ));
    let clock: Arc<dyn Clock> = Arc::new(SystemClock);
    let catalog = AniListCatalog::new(limited, clock.clone());
    let env = SourceEnv {
        http: plain,
        clock: clock.clone(),
    };
    let registry = SourceRegistry::build(&env, &merge(&all_defaults(), None).settings);
    let folder = std::env::temp_dir().join(format!("kolektaku-novel-live-{}", std::process::id()));
    std::fs::create_dir_all(&folder).unwrap();
    let mut first_source_hits = 0;
    println!("| judul | katalog | sumber | cocok |");
    println!("|---|---|---|---|");
    for title in TITLES {
        let found = catalog.search(MediaKind::Novel, title, 1).await.unwrap();
        let media = found
            .items
            .into_iter()
            .find(|item| !item.is_adult)
            .expect("catalog has the title");
        for source in registry.for_kind(MediaKind::Novel) {
            let id = source.info().id.to_string();
            let store = Arc::new(JsonSourceLinkStore::new(
                folder.join(format!("{id}-{}.json", media.id.get())),
            ));
            let health = Arc::new(SourceHealth::new(clock.clone()));
            let resolver = ResolveSources::new(vec![source.clone()], store, health, clock.clone());
            let resolved = resolver.execute(&media).await.unwrap();
            let matched = resolved.best().map(|link| link.item.to_string());
            if id == "meionovels" && matched.is_some() {
                first_source_hits += 1;
            }
            println!(
                "| {title} | {} | {id} | {} |",
                media.title.romaji,
                matched.as_deref().unwrap_or("-")
            );
        }
    }
    let _ = std::fs::remove_dir_all(&folder);
    assert!(first_source_hits >= 8, "{first_source_hits} of 10");
}
