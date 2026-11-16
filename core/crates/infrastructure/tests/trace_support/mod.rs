use std::sync::Arc;

use application::ports::Clock;
use application::ports::MetadataCatalog;
use domain::media::{Discover, MediaKind, MediaListKind, MediaStatus, MediaSummary};
use infrastructure::catalog::anilist::AniListCatalog;
use infrastructure::clock::SystemClock;
use infrastructure::config::merge;
use infrastructure::http::{
    HttpClient, RateLimitSettings, RateLimitedClient, ReqwestClient, SystemPause,
};
use infrastructure::sources::registry::{SourceEnv, SourceRegistry, all_defaults};

const ANIME_TITLES: &str = "Kimetsu no Yaiba;Kimetsu no Yaiba Movie: Mugenjou-hen";

pub fn env_text(name: &str, fallback: &str) -> String {
    std::env::var(name).unwrap_or_else(|_| fallback.to_string())
}

pub fn kind_of(text: &str) -> MediaKind {
    match text {
        "manga" => MediaKind::Manga,
        "novel" => MediaKind::Novel,
        _ => MediaKind::Anime,
    }
}

pub fn catalog_and_registry() -> (AniListCatalog, SourceRegistry, Arc<dyn Clock>) {
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
    (catalog, registry, clock)
}

pub async fn targets(catalog: &AniListCatalog, kind: MediaKind) -> Vec<MediaSummary> {
    let top: usize = env_text("TRACE_TOP", "1").parse().unwrap_or(1);
    if env_text("TRACE_MODE", "titles") == "popular" {
        let mut found = Vec::new();
        let pages: u32 = env_text("TRACE_PAGES", "1").parse().unwrap_or(1);
        for page in 1..=pages {
            let listed = catalog
                .list(kind, MediaListKind::Popular, page)
                .await
                .unwrap();
            found.extend(listed.items.into_iter().filter(|item| !item.is_adult));
        }
        return found.into_iter().take(top).collect();
    }
    if env_text("TRACE_MODE", "titles") == "unreleased" {
        let filter = Discover::default().with_status(MediaStatus::NotYetReleased);
        let page = catalog.discover(kind, &filter, 1).await.unwrap();
        return page.items.into_iter().take(top).collect();
    }
    let default = if kind == MediaKind::Anime {
        ANIME_TITLES
    } else {
        ""
    };
    let mut found = Vec::new();
    for title in env_text("TRACE_TITLES", default)
        .split(';')
        .filter(|title| !title.trim().is_empty())
    {
        let page = catalog.search(kind, title.trim(), 1).await.unwrap();
        found.extend(
            page.items
                .into_iter()
                .filter(|item| !item.is_adult)
                .take(top),
        );
    }
    found
}
