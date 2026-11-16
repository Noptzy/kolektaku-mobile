use std::path::Path;
use std::sync::Arc;

use application::library::MigrateNovelEntries;
use application::ports::Clock;
use infrastructure::catalog::anilist::{AniListCatalog, catalog_ttl};
use infrastructure::clock::SystemClock;
use infrastructure::config::{ConfigLoader, FileConfigStore, merge};
use infrastructure::http::{
    CachedHttp, HttpClient, RateLimitSettings, RateLimitedClient, ReqwestClient, ResponseCache,
    SystemPause,
};
use infrastructure::scene::trace_moe::TraceMoeSceneSearch;
use infrastructure::sources::registry::{SourceEnv, SourceRegistry, all_defaults};
use infrastructure::sources::share_page_cache;
use infrastructure::storage::{Database, import_legacy};
use infrastructure::translate::google::GoogleTranslator;
use infrastructure::translate::{CACHE_CAPACITY as TRANSLATION_CACHE_CAPACITY, CachedTranslator};

use crate::error::BridgeError;
use crate::state::AppState;

const CACHE_CAPACITY: usize = 400;
const PAGE_CACHE_CAPACITY: usize = 600;
const DATABASE_FILE: &str = "kolektaku.db";

const RELEASE_CONFIG_URL: &str =
    "https://github.com/Noptzy/kolektaku-mobile/releases/latest/download/config.json";

pub(crate) async fn open_database(data_dir: &Path) -> Result<Database, BridgeError> {
    let database = Database::open(&data_dir.join(DATABASE_FILE))?;
    import_legacy(&database, data_dir).await?;
    let _ = tokio::fs::remove_dir_all(data_dir.join("cache")).await;
    Ok(database)
}

pub(crate) fn translation_service(
    database: &Database,
    http: &Arc<dyn HttpClient>,
    clock: &Arc<dyn Clock>,
) -> Arc<CachedTranslator> {
    let cache = Arc::new(ResponseCache::in_database(
        database.clone(),
        "translation",
        clock.clone(),
        TRANSLATION_CACHE_CAPACITY,
    ));
    let pruned = cache.clone();
    tokio::spawn(async move {
        pruned.prune().await;
    });
    let online = Arc::new(GoogleTranslator::new(http.clone()));
    Arc::new(CachedTranslator::new(online, cache, clock.clone()))
}

pub async fn build_production(data_dir: &Path) -> Result<AppState<AniListCatalog>, BridgeError> {
    let transport = Arc::new(ReqwestClient::standard()?);
    let plain: Arc<dyn HttpClient> = transport.clone();
    let scene = Arc::new(TraceMoeSceneSearch::new(
        plain.clone(),
        Arc::new(SystemPause),
    ));
    let limited: Arc<dyn HttpClient> = Arc::new(RateLimitedClient::new(
        transport,
        Arc::new(SystemPause),
        RateLimitSettings::default(),
    ));
    let clock: Arc<dyn Clock> = Arc::new(SystemClock);
    let store = Arc::new(FileConfigStore::new(data_dir.join("config.json")));
    let loader = Arc::new(ConfigLoader::new(plain.clone(), store, RELEASE_CONFIG_URL));
    let cached = loader.cached().await;
    let settings = merge(&all_defaults(), cached.as_ref()).settings;
    let env = SourceEnv {
        http: plain.clone(),
        clock: clock.clone(),
    };
    let registry = SourceRegistry::build(&env, &settings);
    tokio::spawn(async move {
        loader.refresh().await;
    });
    let database = open_database(data_dir).await?;
    let cache = Arc::new(ResponseCache::in_database(
        database.clone(),
        "catalog",
        clock.clone(),
        CACHE_CAPACITY,
    ));
    let pruned = cache.clone();
    tokio::spawn(async move {
        pruned.prune().await;
    });
    let pages = Arc::new(ResponseCache::in_database(
        database.clone(),
        "pages",
        clock.clone(),
        PAGE_CACHE_CAPACITY,
    ));
    share_page_cache(pages.clone());
    tokio::spawn(async move {
        pages.prune().await;
    });
    let remembered: Arc<dyn HttpClient> =
        Arc::new(CachedHttp::new(limited, cache.clone(), catalog_ttl));
    let catalog = Arc::new(AniListCatalog::new(remembered, clock.clone()));
    let state = AppState::assemble_in(database, catalog, registry, clock, scene, plain).await?;
    let migration = MigrateNovelEntries::new(state.library.clone(), state.catalog.clone());
    tokio::spawn(async move {
        migration.execute().await;
    });
    Ok(state.with_response_cache(cache))
}

static GLOBAL: std::sync::OnceLock<AppState<AniListCatalog>> = std::sync::OnceLock::new();

pub fn global() -> Result<&'static AppState<AniListCatalog>, BridgeError> {
    GLOBAL.get().ok_or_else(BridgeError::not_ready)
}

pub async fn install(data_dir: &Path) -> Result<(), BridgeError> {
    if GLOBAL.get().is_some() {
        return Ok(());
    }
    let state = build_production(data_dir).await?;
    let _ = GLOBAL.set(state);
    Ok(())
}
