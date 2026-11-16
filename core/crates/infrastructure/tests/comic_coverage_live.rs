use std::sync::Arc;

use application::ports::{Clock, MetadataCatalog, SourceProvider};
use application::sources::{ResolveSources, SourceHealth};
use domain::media::{MediaFormat, MediaKind, MediaSummary};
use infrastructure::catalog::anilist::AniListCatalog;
use infrastructure::clock::SystemClock;
use infrastructure::config::merge;
use infrastructure::http::{
    HttpClient, HttpRequest, RateLimitSettings, RateLimitedClient, ReqwestClient, SystemPause,
};
use infrastructure::sources::registry::{SourceEnv, SourceRegistry, all_defaults};
use infrastructure::storage::JsonSourceLinkStore;

const TITLES: [&str; 28] = [
    "One Piece",
    "Jujutsu Kaisen",
    "Chainsaw Man",
    "Kagurabachi",
    "Sakamoto Days",
    "Dandadan",
    "Blue Lock",
    "Sousou no Frieren",
    "Oshi no Ko",
    "Spy x Family",
    "Berserk",
    "Vinland Saga",
    "Kingdom",
    "Solo Leveling",
    "Omniscient Reader",
    "Tower of God",
    "Boruto: Two Blue Vortex",
    "Vagabond",
    "20th Century Boys",
    "Gachiakuta",
    "Kaiju No. 8",
    "Ao no Hako",
    "Witch Watch",
    "Monster",
    "Houseki no Kuni",
    "Oyasumi Punpun",
    "Kaoru Hana wa Rin to Saku",
    "Medalist",
];

struct Outcome {
    stage: &'static str,
    detail: String,
}

impl Outcome {
    fn reached(detail: impl Into<String>) -> Self {
        Self {
            stage: "ok",
            detail: detail.into(),
        }
    }

    fn stopped(stage: &'static str, detail: impl ToString) -> Self {
        Self {
            stage,
            detail: detail.to_string(),
        }
    }
}

async fn first_image_status(http: &Arc<dyn HttpClient>, url: &str) -> Outcome {
    match http.send(HttpRequest::get(url)).await {
        Ok(response) if response.status == 200 && !response.body.is_empty() => {
            Outcome::reached(format!("gambar 200, {} byte", response.body.len()))
        }
        Ok(response) => Outcome::stopped("gambar", format!("HTTP {}", response.status)),
        Err(error) => Outcome::stopped("gambar", error),
    }
}

async fn walk_source(
    source: Arc<dyn SourceProvider>,
    media: &MediaSummary,
    clock: &Arc<dyn Clock>,
    http: &Arc<dyn HttpClient>,
    folder: &std::path::Path,
) -> Outcome {
    let store = Arc::new(JsonSourceLinkStore::new(folder.join(format!(
        "{}-{}.json",
        source.info().id,
        media.id.get()
    ))));
    let health = Arc::new(SourceHealth::new(clock.clone()));
    let resolver = ResolveSources::new(vec![source.clone()], store, health, clock.clone());
    let resolved = match resolver.execute(media).await {
        Ok(resolved) => resolved,
        Err(error) => return Outcome::stopped("cari-cocok", error),
    };
    let Some(link) = resolved.best() else {
        return Outcome::stopped("cari-cocok", "tidak ada kandidat yang cocok");
    };
    let units = match source.units(link.item.clone()).await {
        Ok(units) if units.is_empty() => {
            return Outcome::stopped("daftar-chapter", "daftar kosong");
        }
        Ok(units) => units,
        Err(error) => return Outcome::stopped("daftar-chapter", error),
    };
    let Some(pages_port) = source.pages() else {
        return Outcome::stopped("halaman", "sumber tanpa pembaca halaman");
    };
    let pages = match pages_port.chapter_pages(units[0].id.clone()).await {
        Ok(pages) if pages.pages.is_empty() => {
            return Outcome::stopped("halaman", "chapter pertama tanpa halaman");
        }
        Ok(pages) => pages,
        Err(error) => return Outcome::stopped("halaman", error),
    };
    let image = first_image_status(http, &pages.pages[0].url).await;
    Outcome {
        detail: format!(
            "{} chapter, {} halaman di chapter 1; {}",
            units.len(),
            pages.pages.len(),
            image.detail
        ),
        ..image
    }
}

fn first_comic(items: Vec<MediaSummary>) -> Option<MediaSummary> {
    items
        .into_iter()
        .find(|item| item.format != Some(MediaFormat::Novel) && !item.is_adult)
}

#[tokio::test]
#[ignore = "talks to AniList and the comic sites"]
async fn every_test_title_is_followed_from_search_to_the_first_page_image() {
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
        http: plain.clone(),
        clock: clock.clone(),
    };
    let registry = SourceRegistry::build(&env, &merge(&all_defaults(), None).settings);
    let comics = registry.for_kind(MediaKind::Manga);
    let folder = std::env::temp_dir().join(format!("kolektaku-comic-live-{}", std::process::id()));
    std::fs::create_dir_all(&folder).unwrap();
    println!("| judul | katalog | sumber | tahap | rincian |");
    println!("|---|---|---|---|---|");
    for title in TITLES {
        let found = catalog.search(MediaKind::Manga, title, 1).await;
        let Some(media) = found.ok().and_then(|page| first_comic(page.items)) else {
            println!(
                "| {title} | (tidak ketemu) | - | katalog | AniList tidak mengembalikan komik |"
            );
            continue;
        };
        for source in &comics {
            let outcome = walk_source(source.clone(), &media, &clock, &plain, &folder).await;
            println!(
                "| {title} | {} (#{}) | {} | {} | {} |",
                media.title.romaji,
                media.id.get(),
                source.info().id,
                outcome.stage,
                outcome.detail.replace('|', "/")
            );
        }
    }
    let _ = std::fs::remove_dir_all(&folder);
}
