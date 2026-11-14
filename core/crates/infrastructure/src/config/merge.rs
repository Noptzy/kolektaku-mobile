use super::hosts::host_allowed;
use super::model::{RemoteConfig, RemoteSource, SourceSettings};

#[derive(Debug, Clone, Copy)]
pub struct Defaults {
    pub id: &'static str,
    pub base_url: &'static str,
    pub api_url: Option<&'static str>,
    pub priority: u8,
    pub allowed_hosts: &'static [&'static str],
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Rejection {
    UnknownSource(String),
    AddressNotAllowed { id: String, address: String },
    AddressNotNeeded { id: String },
}

pub struct Merged {
    pub settings: Vec<SourceSettings>,
    pub rejected: Vec<Rejection>,
}

impl Defaults {
    pub fn settings(&self) -> SourceSettings {
        SourceSettings {
            id: self.id.to_string(),
            base_url: self.base_url.to_string(),
            api_url: self.api_url.map(str::to_string),
            enabled: true,
            priority: self.priority,
        }
    }
}

fn accepted_address(
    defaults: &Defaults,
    candidate: &Option<String>,
    rejected: &mut Vec<Rejection>,
) -> Option<String> {
    let address = candidate.as_ref()?;
    if host_allowed(defaults.allowed_hosts, address) {
        return Some(address.clone());
    }
    rejected.push(Rejection::AddressNotAllowed {
        id: defaults.id.to_string(),
        address: address.clone(),
    });
    None
}

fn apply(
    settings: &mut SourceSettings,
    defaults: &Defaults,
    remote: &RemoteSource,
    rejected: &mut Vec<Rejection>,
) {
    settings.enabled = remote.enabled.unwrap_or(settings.enabled);
    settings.priority = remote.priority.unwrap_or(settings.priority);
    if let Some(address) = accepted_address(defaults, &remote.base_url, rejected) {
        settings.base_url = address;
    }
    if remote.api_url.is_some() && defaults.api_url.is_none() {
        rejected.push(Rejection::AddressNotNeeded {
            id: defaults.id.to_string(),
        });
    } else if let Some(address) = accepted_address(defaults, &remote.api_url, rejected) {
        settings.api_url = Some(address);
    }
}

pub fn merge(defaults: &[Defaults], remote: Option<&RemoteConfig>) -> Merged {
    let mut settings: Vec<SourceSettings> = defaults.iter().map(Defaults::settings).collect();
    let mut rejected = Vec::new();
    let mut applied: Vec<&str> = Vec::new();
    for entry in remote
        .map(|config| config.sources.as_slice())
        .unwrap_or_default()
    {
        let known = defaults.iter().position(|item| item.id == entry.id);
        match known {
            None => rejected.push(Rejection::UnknownSource(entry.id.clone())),
            Some(_) if applied.contains(&entry.id.as_str()) => {}
            Some(index) => {
                applied.push(&entry.id);
                apply(&mut settings[index], &defaults[index], entry, &mut rejected);
            }
        }
    }
    Merged { settings, rejected }
}
