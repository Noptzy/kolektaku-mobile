use std::path::Path;
use std::sync::Arc;

use application::downloads::{DownloadQueue, DownloadSettingsStore};
use application::ports::{Clock, MetadataCatalog, SourceProvider, TranslationHealth, Translator};
use application::settings::AppSettingsStore;
use application::sources::{ResolveSources, SourceDirectory, SourceHealth, SourceSwitches};
use domain::media::MediaKind;
use infrastructure::download::EpisodeDownloader;
use infrastructure::http::{HttpClient, ReqwestClient, ResponseCache};
use infrastructure::scene::trace_moe::TraceMoeSceneSearch;
use infrastructure::sources::registry::SourceRegistry;
use infrastructure::storage::{
    Database, SqliteDownloadLedger, SqliteHighlightStore, SqliteLibraryRepository,
    SqliteSourceLinkStore, SqliteUpdateLedger,
};

use crate::error::BridgeError;

pub struct AppState<C: MetadataCatalog> {
    pub catalog: Arc<C>,
    pub registry: SourceRegistry,
    pub directory: Arc<SourceDirectory>,
    pub library: Arc<SqliteLibraryRepository>,
    pub links: Arc<SqliteSourceLinkStore>,
    pub updates: Arc<SqliteUpdateLedger>,
    pub highlights: Arc<SqliteHighlightStore>,
    pub health: Arc<SourceHealth>,
    pub switches: Arc<SourceSwitches>,
    pub settings: Arc<AppSettingsStore>,
    pub clock: Arc<dyn Clock>,
    pub scene: Arc<TraceMoeSceneSearch>,
    pub translator: Arc<dyn Translator>,
    pub translation_health: Arc<dyn TranslationHealth>,
    pub http: Arc<dyn HttpClient>,
    pub response_cache: Option<Arc<ResponseCache>>,
    pub downloads: Arc<DownloadQueue<SqliteDownloadLedger>>,
    pub downloader: Arc<EpisodeDownloader>,
}

impl<C: MetadataCatalog + 'static> AppState<C> {
    pub async fn assemble(
        catalog: Arc<C>,
        registry: SourceRegistry,
        data_dir: &Path,
        clock: Arc<dyn Clock>,
        scene: Arc<TraceMoeSceneSearch>,
        http: Arc<dyn HttpClient>,
    ) -> Result<Self, BridgeError> {
        let database = open_database(data_dir).await?;
        Self::assemble_in(database, catalog, registry, clock, scene, http).await
    }

    pub async fn assemble_in(
        database: Database,
        catalog: Arc<C>,
        registry: SourceRegistry,
        clock: Arc<dyn Clock>,
        scene: Arc<TraceMoeSceneSearch>,
        http: Arc<dyn HttpClient>,
    ) -> Result<Self, BridgeError> {
        let library = Arc::new(SqliteLibraryRepository::new(
            database.clone(),
            clock.clone(),
        ));
        let links = Arc::new(SqliteSourceLinkStore::new(database.clone()));
        let updates = Arc::new(SqliteUpdateLedger::new(database.clone()));
        let highlights = Arc::new(SqliteHighlightStore::new(database.clone()));
        let switches = SourceSwitches::load(library.as_ref()).await;
        let settings = AppSettingsStore::load(library.as_ref()).await;
        let directory =
            Arc::new(SourceDirectory::new(registry.all()).with_settings(settings.clone()));
        let health = Arc::new(SourceHealth::new(clock.clone()));
        let translation = translation_service(&database, &http, &clock);
        let downloader = Arc::new(EpisodeDownloader::new(
            http.clone(),
            Arc::new(ReqwestClient::for_files()?),
            translation.clone(),
            std::env::temp_dir().join("kolektaku-downloads"),
        ));
        let language = settings.clone();
        let downloads = DownloadQueue::load(
            Arc::new(SqliteDownloadLedger::new(database.clone())),
            downloader.clone(),
            clock.clone(),
            DownloadSettingsStore::load(library.as_ref()).await,
            Arc::new(move || language.get().translation),
        )
        .await;
        Ok(Self {
            catalog,
            registry,
            directory,
            library,
            links,
            updates,
            highlights,
            health,
            switches,
            settings,
            clock,
            scene,
            translator: translation.clone(),
            translation_health: translation,
            http,
            response_cache: None,
            downloads,
            downloader,
        })
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

    pub fn resolver(&self, kind: MediaKind) -> ResolveSources<SqliteSourceLinkStore> {
        ResolveSources::new(
            self.active_sources(kind),
            self.links.clone(),
            self.health.clone(),
            self.clock.clone(),
        )
        .with_settings(self.settings.clone())
    }
}

pub use crate::production::{build_production, global, install};
use crate::production::{open_database, translation_service};
