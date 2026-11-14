use std::sync::Arc;

use application::testing::FakeClock;
use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::{SourceId, SourceSearch};

use super::registry::{REGISTRATIONS, SourceEnv, SourceRegistry, all_defaults};
use crate::config::{RemoteConfig, RemoteSource, SourceSettings, merge};
use crate::http::{FakeHttp, HttpResponse};

fn env(http: Arc<FakeHttp>) -> SourceEnv {
    SourceEnv {
        http,
        clock: Arc::new(FakeClock::at(0)),
    }
}

fn quiet_env() -> SourceEnv {
    env(Arc::new(FakeHttp::always(HttpResponse::new(200, ""))))
}

fn default_settings() -> Vec<SourceSettings> {
    all_defaults()
        .iter()
        .map(|defaults| defaults.settings())
        .collect()
}

#[test]
fn every_registered_site_builds_from_its_defaults() {
    let registry = SourceRegistry::build(&quiet_env(), &default_settings());
    assert!(registry.problems().is_empty(), "{:?}", registry.problems());
    for registration in REGISTRATIONS {
        let id = SourceId::new(registration.defaults.id);
        assert!(registry.get(&id).is_some(), "{id}");
    }
}

#[test]
fn a_site_switched_off_is_not_built() {
    let mut settings = default_settings();
    settings
        .iter_mut()
        .find(|entry| entry.id == "komiku")
        .unwrap()
        .enabled = false;
    let registry = SourceRegistry::build(&quiet_env(), &settings);
    assert!(registry.get(&SourceId::new("komiku")).is_none());
    assert!(registry.get(&SourceId::new("komikindo")).is_some());
    assert!(registry.problems().is_empty());
}

#[test]
fn unknown_sites_and_bad_addresses_become_problems_not_panics() {
    let mut settings = default_settings();
    settings
        .iter_mut()
        .find(|entry| entry.id == "kuramanime")
        .unwrap()
        .base_url = "nonsense".into();
    settings.push(SourceSettings {
        id: "ghost".into(),
        base_url: "https://ghost.example".into(),
        api_url: None,
        enabled: true,
        priority: 1,
    });
    let registry = SourceRegistry::build(&quiet_env(), &settings);
    let problems: Vec<&str> = registry
        .problems()
        .iter()
        .map(|problem| problem.id.as_str())
        .collect();
    assert_eq!(problems, vec!["kuramanime", "ghost"]);
    assert!(matches!(
        registry.problems()[0].error,
        SourceError::Unsupported(_)
    ));
    assert!(registry.get(&SourceId::new("komiku")).is_some());
}

const REAL_SITES: [&str; 3] = ["kuramanime", "komiku", "komikindo"];

fn real_ids(registry: &SourceRegistry, kind: MediaKind) -> Vec<String> {
    registry
        .for_kind(kind)
        .iter()
        .map(|source| source.info().id.to_string())
        .filter(|id| REAL_SITES.contains(&id.as_str()))
        .collect()
}

#[test]
fn sources_are_listed_by_kind_and_preference() {
    let registry = SourceRegistry::build(&quiet_env(), &default_settings());
    assert_eq!(
        real_ids(&registry, MediaKind::Manga),
        vec!["komiku", "komikindo"]
    );
    assert_eq!(real_ids(&registry, MediaKind::Anime), vec!["kuramanime"]);
    let priorities: Vec<u8> = registry
        .for_kind(MediaKind::Anime)
        .iter()
        .map(|source| source.info().priority)
        .collect();
    assert!(priorities.windows(2).all(|pair| pair[0] <= pair[1]));
}

#[test]
fn a_remote_priority_change_reorders_the_sources() {
    let remote = RemoteConfig {
        version: 1,
        sources: vec![RemoteSource {
            id: "komikindo".into(),
            base_url: None,
            api_url: None,
            enabled: None,
            priority: Some(1),
        }],
    };
    let settings = merge(&all_defaults(), Some(&remote)).settings;
    let registry = SourceRegistry::build(&quiet_env(), &settings);
    assert_eq!(
        real_ids(&registry, MediaKind::Manga),
        vec!["komikindo", "komiku"]
    );
}

#[tokio::test]
async fn a_remote_address_change_is_what_the_source_actually_calls() {
    let remote = RemoteConfig {
        version: 1,
        sources: vec![RemoteSource {
            id: "kuramanime".into(),
            base_url: Some("https://v99.kuramanime.ing".into()),
            api_url: None,
            enabled: None,
            priority: None,
        }],
    };
    let http = Arc::new(FakeHttp::always(HttpResponse::new(200, "")));
    let settings = merge(&all_defaults(), Some(&remote)).settings;
    let registry = SourceRegistry::build(&env(http.clone()), &settings);
    let source = registry.get(&SourceId::new("kuramanime")).unwrap();
    let _ = source.search(SourceSearch::new("x")).await;
    assert!(
        http.requests()[0]
            .url
            .starts_with("https://v99.kuramanime.ing/anime?")
    );
}

#[test]
fn a_registry_can_also_be_assembled_from_ready_made_sources() {
    let built = SourceRegistry::build(&quiet_env(), &default_settings());
    let again = SourceRegistry::from_providers(built.for_kind(MediaKind::Manga));
    assert_eq!(
        again.for_kind(MediaKind::Manga).len(),
        built.for_kind(MediaKind::Manga).len()
    );
    assert!(again.for_kind(MediaKind::Anime).is_empty());
}
