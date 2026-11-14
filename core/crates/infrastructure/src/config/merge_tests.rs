use super::merge::{Defaults, Rejection, merge};
use super::model::{RemoteConfig, RemoteSource};

const ANIME: Defaults = Defaults {
    id: "anime-site",
    base_url: "https://v20.anime.example",
    api_url: None,
    priority: 1,
    allowed_hosts: &["*.anime.example"],
};

const MANGA: Defaults = Defaults {
    id: "manga-site",
    base_url: "https://manga.example",
    api_url: Some("https://api.manga.example"),
    priority: 5,
    allowed_hosts: &["manga.example", "api.manga.example"],
};

fn entry(id: &str) -> RemoteSource {
    RemoteSource {
        id: id.into(),
        base_url: None,
        api_url: None,
        enabled: None,
        priority: None,
    }
}

fn config(sources: Vec<RemoteSource>) -> RemoteConfig {
    RemoteConfig {
        version: 1,
        sources,
    }
}

#[test]
fn without_a_remote_file_the_defaults_apply() {
    let merged = merge(&[ANIME, MANGA], None);
    assert_eq!(merged.settings.len(), 2);
    assert_eq!(merged.settings[0].base_url, "https://v20.anime.example");
    assert!(merged.settings.iter().all(|settings| settings.enabled));
    assert_eq!(
        merged.settings[1].api_url.as_deref(),
        Some("https://api.manga.example")
    );
    assert!(merged.rejected.is_empty());
}

#[test]
fn a_remote_file_can_move_a_site_to_an_allowed_address_and_change_its_priority() {
    let mut moved = entry("anime-site");
    moved.base_url = Some("https://v21.anime.example".into());
    moved.priority = Some(9);
    let merged = merge(&[ANIME], Some(&config(vec![moved])));
    assert_eq!(merged.settings[0].base_url, "https://v21.anime.example");
    assert_eq!(merged.settings[0].priority, 9);
    assert!(merged.rejected.is_empty());
}

#[test]
fn a_remote_file_can_switch_a_broken_site_off() {
    let mut off = entry("manga-site");
    off.enabled = Some(false);
    let merged = merge(&[ANIME, MANGA], Some(&config(vec![off])));
    assert!(merged.settings[0].enabled);
    assert!(!merged.settings[1].enabled);
}

#[test]
fn an_address_outside_the_allowed_hosts_is_ignored_and_reported() {
    let mut hijack = entry("anime-site");
    hijack.base_url = Some("https://evil.example".into());
    let mut insecure = entry("manga-site");
    insecure.base_url = Some("http://manga.example".into());
    let merged = merge(&[ANIME, MANGA], Some(&config(vec![hijack, insecure])));
    assert_eq!(merged.settings[0].base_url, "https://v20.anime.example");
    assert_eq!(merged.settings[1].base_url, "https://manga.example");
    assert_eq!(
        merged.rejected,
        vec![
            Rejection::AddressNotAllowed {
                id: "anime-site".into(),
                address: "https://evil.example".into()
            },
            Rejection::AddressNotAllowed {
                id: "manga-site".into(),
                address: "http://manga.example".into()
            },
        ]
    );
}

#[test]
fn an_api_address_is_only_taken_for_sites_that_have_one() {
    let mut api = entry("anime-site");
    api.api_url = Some("https://api.anime.example".into());
    let mut moved = entry("manga-site");
    moved.api_url = Some("https://api.manga.example".into());
    let merged = merge(&[ANIME, MANGA], Some(&config(vec![api, moved])));
    assert_eq!(merged.settings[0].api_url, None);
    assert_eq!(
        merged.rejected,
        vec![Rejection::AddressNotNeeded {
            id: "anime-site".into()
        }]
    );
    assert_eq!(
        merged.settings[1].api_url.as_deref(),
        Some("https://api.manga.example")
    );
}

#[test]
fn unknown_and_repeated_entries_never_add_or_override_anything() {
    let mut first = entry("anime-site");
    first.priority = Some(2);
    let mut again = entry("anime-site");
    again.priority = Some(7);
    let merged = merge(
        &[ANIME],
        Some(&config(vec![first, again, entry("ghost-site")])),
    );
    assert_eq!(merged.settings.len(), 1);
    assert_eq!(merged.settings[0].priority, 2);
    assert_eq!(
        merged.rejected,
        vec![Rejection::UnknownSource("ghost-site".into())]
    );
}
