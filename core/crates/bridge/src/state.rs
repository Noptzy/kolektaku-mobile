use std::path::Path;
use std::sync::Arc;

use application::library::MigrateNovelEntries;
use application::ports::{Clock, MetadataCatalog, SourceProvider, TranslationHealth, Translator};
use application::settings::AppSettingsStore;
use application::sources::{ResolveSources, SourceDirectory, SourceHealth, SourceSwitches};
use domain::media::MediaKind;
use infrastructure::catalog::anilist::{AniListCatalog, catalog_ttl};
use infrastructure::clock::SystemClock;
use infrastructure::config::{ConfigLoader, FileConfigStore, merge};
use infrastructure::http::{
    CachedHttp, HttpClient, RateLimitSettings, RateLimitedClient, ReqwestClient, ResponseCache,
    SystemPause,
};
use infrastructure::scene::trace_moe::TraceMoeSceneSearch;
use infrastructure::sources::registry::{SourceEnv, SourceRegistry, all_defaults};
use infrastructure::storage::{JsonLibraryRepository, JsonSourceLinkStore};
use infrastructure::translate::google::GoogleTranslator;
use infrastructure::translate::{CACHE_CAPACITY as TRANSLATION_CACHE_CAPACITY, CachedTranslator};

use crate::error::BridgeError;

const CACHE_CAPACITY: usize = 400;

const RELEASE_CONFIG_URL: &str =
    "https://github.com/Noptzy/kolektaku-mobile/releases/latest/download/config.json";

pub struct AppState<C: MetadataCatalog> {
    pub catalog: Arc<C>,
    pub registry: SourceRegistry,
    pub directory: Arc<SourceDirectory>,
    pub library: Arc<JsonLibraryRepository>,
    pub links: Arc<JsonSourceLinkStore>,
    pub health: Arc<SourceHealth>,
    pub switches: Arc<SourceSwitches>,
    pub settings: Arc<AppSettingsStore>,
    pub clock: Arc<dyn Clock>,
    pub scene: Arc<TraceMoeSceneSearch>,
    pub translator: Arc<dyn Translator>,
    pub translation_health: Arc<dyn TranslationHealth>,
    pub http: Arc<dyn HttpClient>,
    pub response_cache: Option<Arc<ResponseCache>>,
}

impl<C: MetadataCatalog + 'static> AppState<C> {
    pub async fn assemble(
        catalog: Arc<C>,
        registry: SourceRegistry,
        data_dir: &Path,
        clock: Arc<dyn Clock>,
        scene: Arc<TraceMoeSceneSearch>,
        http: Arc<dyn HttpClient>,
    ) -> Self {
        let library = Arc::new(JsonLibraryRepository::new(
            data_dir.join("library.json"),
            clock.clone(),
        ));
        let links = Arc::new(JsonSourceLinkStore::new(data_dir.join("source_links.json")));
        let switches = SourceSwitches::load(library.as_ref()).await;
        let settings = AppSettingsStore::load(library.as_ref()).await;
        let directory =
            Arc::new(SourceDirectory::new(registry.all()).with_settings(settings.clone()));
        let health = Arc::new(SourceHealth::new(clock.clone()));
        let translation = translation_service(data_dir, &http, &clock);
        Self {
            catalog,
            registry,
            directory,
            library,
            links,
            health,
            switches,
            settings,
            clock,
            scene,
            translator: translation.clone(),
            translation_health: translation,
            http,
            response_cache: None,
        }
    }

    pub fn with_translator(
        mut self,
        translator: Arc<dyn Translator>,
        health: Arc<dyn TranslationHealth>,
    ) -> Self {
        self.translator = translator;
        self.translation_health = health;
        self
    }

    pub fn with_response_cache(mut self, cache: Arc<ResponseCache>) -> Self {
        self.response_cache = Some(cache);
        self
    }

    pub fn active_sources(&self, kind: MediaKind) -> Vec<Arc<dyn SourceProvider>> {
        self.registry
            .for_kind(kind)
            .into_iter()
            .filter(|source| self.switches.is_enabled(&source.info().id))
            .collect()
    }

    pub fn resolver(&self, kind: MediaKind) -> ResolveSources<JsonSourceLinkStore> {
        ResolveSources::new(
            self.active_sources(kind),
            self.links.clone(),
            self.health.clone(),
            self.clock.clone(),
        )
        .with_settings(self.settings.clone())
    }
}

fn translation_service(
    data_dir: &Path,
    http: &Arc<dyn HttpClient>,
    clock: &Arc<dyn Clock>,
) -> Arc<CachedTranslator> {
    let cache = Arc::new(ResponseCache::new(
        data_dir.join("cache").join("translation"),
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
    let cache = Arc::new(ResponseCache::new(
        data_dir.join("cache").join("catalog"),
        clock.clone(),
        CACHE_CAPACITY,
    ));
    let pruned = cache.clone();
    tokio::spawn(async move {
        pruned.prune().await;
    });
    let remembered: Arc<dyn HttpClient> =
        Arc::new(CachedHttp::new(limited, cache.clone(), catalog_ttl));
    let catalog = Arc::new(AniListCatalog::new(remembered, clock.clone()));
    let state = AppState::assemble(catalog, registry, data_dir, clock, scene, plain).await;
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
