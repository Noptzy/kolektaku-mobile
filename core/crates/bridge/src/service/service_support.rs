use std::path::PathBuf;
use std::sync::Arc;
use std::sync::atomic::{AtomicU32, Ordering};

use application::ports::{BoxFuture, SourceProvider};
use application::testing::{FakeCatalog, FakeClock, FakeSource, FakeVideo};
use domain::error::SourceError;
use domain::media::{
    Appearance, MediaDetail, MediaFormat, MediaId, MediaKind, MediaListKind, MediaStatus,
    MediaSummary, MediaTitle, Profile, ProfileKind, ProfileSummary,
};
use domain::source::{ItemId, SourceDetail, SourceItem, Unit};
use domain::stream::{EpisodeServer, StreamPlan};
use infrastructure::http::{HttpClient, HttpRequest, HttpResponse, SystemPause};
use infrastructure::scene::trace_moe::TraceMoeSceneSearch;
use infrastructure::sources::registry::SourceRegistry;

use crate::dto::media::MediaRefDto;
use crate::state::AppState;

static COUNTER: AtomicU32 = AtomicU32::new(0);

pub struct Folder(pub PathBuf);

impl Folder {
    pub fn new() -> Self {
        let unique = COUNTER.fetch_add(1, Ordering::SeqCst);
        let path =
            std::env::temp_dir().join(format!("kolektaku-bridge-{}-{unique}", std::process::id()));
        let _ = std::fs::remove_dir_all(&path);
        std::fs::create_dir_all(&path).unwrap();
        Self(path)
    }
}

impl Drop for Folder {
    fn drop(&mut self) {
        let _ = std::fs::remove_dir_all(&self.0);
    }
}

pub fn spy() -> MediaSummary {
    let mut media = MediaSummary::new(
        MediaId::new(140960).unwrap(),
        MediaKind::Anime,
        MediaTitle::new("Spy x Family"),
    );
    media.format = Some(MediaFormat::Tv);
    media.year = Some(2022);
    media.unit_count = Some(12);
    media.status = Some(MediaStatus::Finished);
    media
}

pub fn site() -> FakeSource {
    let mut detail = SourceDetail::new(SourceItem::new(ItemId::new("a-spy"), "Spy x Family"));
    detail.type_text = Some("TV".into());
    detail.year = Some(2022);
    detail.unit_count = Some(12);
    let video = FakeVideo::new()
        .with_servers("a-ep-1", vec![EpisodeServer::new("main", "Main")])
        .with_plan(
            "a-ep-1",
            "main",
            StreamPlan::NeedsWebView {
                url: "https://a.test/ep1".into(),
                script: "1".into(),
                allowed_host: "a.test".into(),
                referer: None,
            },
        );
    FakeSource::new("a", MediaKind::Anime)
        .with_latest(vec![SourceItem::new(ItemId::new("a-spy"), "Spy x Family")])
        .with_search(
            "spy x family",
            vec![SourceItem::new(ItemId::new("a-spy"), "Spy x Family")],
        )
        .with_search(
            "Spy x Family",
            vec![SourceItem::new(ItemId::new("a-spy"), "Spy x Family")],
        )
        .with_detail(detail)
        .with_units(
            "a-spy",
            vec![
                Unit::new("a-ep-1", 1.0, "Episode 1"),
                Unit::new("a-ep-2", 2.0, "Episode 2"),
            ],
        )
        .with_video(video)
}

pub fn catalog() -> FakeCatalog {
    FakeCatalog::new()
        .with_list(MediaKind::Anime, MediaListKind::Trending, vec![spy()])
        .with_search(MediaKind::Anime, "spy x family", vec![spy()])
        .with_detail(MediaDetail::new(spy()))
        .with_candidates(MediaKind::Anime, "Spy x Family", vec![spy()])
        .with_covers(MediaKind::Anime, "Action", &["https://img.test/action.jpg"])
        .with_profile(ProfileKind::Character, nezuko())
        .with_people(ProfileKind::Character, "nezuko", vec![nezuko_hit()])
        .with_people(ProfileKind::Studio, "wit", vec![studio_hit()])
        .with_discovered(vec![spy()])
}

pub fn nezuko_hit() -> ProfileSummary {
    let mut hit = ProfileSummary::new(ProfileKind::Character, 127518, "Nezuko Kamado");
    hit.subtitle = Some("Demon Slayer".into());
    hit
}

pub fn studio_hit() -> ProfileSummary {
    ProfileSummary::new(ProfileKind::Studio, 858, "Wit Studio")
}

pub fn nezuko() -> Profile {
    let mut profile = Profile::new(127518, "Nezuko Kamado");
    profile.appearances.push(Appearance::new(spy()));
    profile
}

pub struct ScriptedHttp(pub Result<HttpResponse, SourceError>);

impl HttpClient for ScriptedHttp {
    fn send(&self, _request: HttpRequest) -> BoxFuture<'_, Result<HttpResponse, SourceError>> {
        let reply = self.0.clone();
        Box::pin(async move { reply })
    }
}

pub fn offline() -> ScriptedHttp {
    ScriptedHttp(Err(SourceError::Network("offline".into())))
}

pub async fn state_with(
    folder: &Folder,
    sources: Vec<Arc<dyn SourceProvider>>,
    scene_http: ScriptedHttp,
) -> AppState<FakeCatalog> {
    let http: Arc<dyn HttpClient> = Arc::new(scene_http);
    let scene = Arc::new(TraceMoeSceneSearch::new(
        http.clone(),
        Arc::new(SystemPause),
    ));
    AppState::assemble(
        Arc::new(catalog()),
        SourceRegistry::from_providers(sources),
        &folder.0,
        Arc::new(FakeClock::at(1_000)),
        scene,
        http,
    )
    .await
    .unwrap()
}

pub async fn state_with_catalog(folder: &Folder, catalog: FakeCatalog) -> AppState<FakeCatalog> {
    let http: Arc<dyn HttpClient> = Arc::new(offline());
    let scene = Arc::new(TraceMoeSceneSearch::new(
        http.clone(),
        Arc::new(SystemPause),
    ));
    AppState::assemble(
        Arc::new(catalog),
        SourceRegistry::from_providers(Vec::new()),
        &folder.0,
        Arc::new(FakeClock::at(1_000)),
        scene,
        http,
    )
    .await
    .unwrap()
}

pub async fn state(folder: &Folder) -> AppState<FakeCatalog> {
    let providers: Vec<Arc<dyn SourceProvider>> = vec![Arc::new(site())];
    state_with(folder, providers, offline()).await
}

pub fn catalog_ref() -> MediaRefDto {
    MediaRefDto::catalog(140960)
}
