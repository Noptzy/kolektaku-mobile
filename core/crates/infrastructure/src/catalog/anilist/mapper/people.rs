use domain::media::{Appearance, FactKind, Profile, ProfileFact, ProfileKind, ProfileSummary};

use crate::catalog::anilist::schema::{RawPeoplePage, RawPerson, RawPersonName, RawStudio};

use super::profile_links::profile_links;
use super::summary::{is_visible, map_summary};

const NAMELESS: &str = "Tanpa nama";

fn name_of(name: RawPersonName) -> String {
    let text = match name {
        RawPersonName::Plain(text) => Some(text),
        RawPersonName::Full { full, native } => full.or(native),
    };
    text.filter(|text| !text.trim().is_empty())
        .unwrap_or_else(|| NAMELESS.into())
}

fn top_work_adult(person: &RawPerson) -> bool {
    person
        .media
        .as_ref()
        .and_then(|works| works.nodes.as_ref())
        .and_then(|nodes| nodes.first())
        .and_then(|work| work.is_adult)
        .unwrap_or(false)
}

fn top_work_title(person: &RawPerson) -> Option<String> {
    let title = person
        .media
        .as_ref()?
        .nodes
        .as_ref()?
        .first()?
        .title
        .as_ref()?;
    title
        .english
        .clone()
        .or_else(|| title.romaji.clone())
        .filter(|text| !text.trim().is_empty())
}

fn occupations(person: &RawPerson) -> Option<String> {
    let joined = person
        .occupations
        .as_ref()?
        .iter()
        .filter(|text| !text.trim().is_empty())
        .cloned()
        .collect::<Vec<_>>()
        .join(", ");
    (!joined.is_empty()).then_some(joined)
}

fn summarize(kind: ProfileKind, person: RawPerson) -> Option<ProfileSummary> {
    if kind == ProfileKind::Character && top_work_adult(&person) {
        return None;
    }
    let subtitle = match kind {
        ProfileKind::Staff => occupations(&person),
        _ => top_work_title(&person),
    };
    let image_url = person
        .image
        .as_ref()
        .and_then(|image| image.large.clone().or_else(|| image.extra_large.clone()));
    let mut summary = ProfileSummary::new(kind, person.id, name_of(person.name));
    summary.image_url = image_url;
    summary.subtitle = subtitle;
    Some(summary)
}

pub fn map_people(kind: ProfileKind, page: RawPeoplePage) -> Vec<ProfileSummary> {
    let found = match kind {
        ProfileKind::Character => page.characters,
        ProfileKind::Staff => page.staff,
        ProfileKind::Studio => page.studios,
    };
    found
        .unwrap_or_default()
        .into_iter()
        .filter_map(|person| summarize(kind, person))
        .collect()
}

fn studio_facts(raw: &RawStudio) -> Vec<ProfileFact> {
    let mut facts = Vec::new();
    if let Some(animation) = raw.is_animation_studio {
        let value = if animation { "animation" } else { "producer" };
        facts.push(ProfileFact {
            kind: FactKind::StudioType,
            value: value.into(),
        });
    }
    if let Some(count) = raw.favourites.filter(|count| *count > 0) {
        facts.push(ProfileFact {
            kind: FactKind::Favourites,
            value: count.to_string(),
        });
    }
    facts
}

pub fn map_studio(raw: RawStudio) -> Profile {
    let facts = studio_facts(&raw);
    let links = profile_links(raw.site_url.as_deref(), "");
    let mut profile = Profile::new(raw.id, raw.name);
    profile.facts = facts;
    profile.links = links;
    let nodes = raw.media.and_then(|works| works.nodes).unwrap_or_default();
    profile.appearances = nodes
        .into_iter()
        .filter(is_visible)
        .map(|node| Appearance::new(map_summary(node)))
        .collect();
    profile
}
