use domain::media::{Appearance, Profile};

use crate::catalog::anilist::sanitize::sanitize_description;
use crate::catalog::anilist::schema::{RawAppearanceEdge, RawProfile};

use super::profile_facts::profile_facts;
use super::profile_links::profile_links;
use super::summary::{is_visible, map_summary};

const NAMELESS: &str = "Tanpa nama";

fn merge(appearances: &mut Vec<Appearance>, edge: RawAppearanceEdge) {
    let Some(node) = edge.node.filter(is_visible) else {
        return;
    };
    let media = map_summary(node);
    let names: Vec<String> = edge
        .characters
        .unwrap_or_default()
        .into_iter()
        .filter_map(|character| character.name?.full)
        .collect();
    if let Some(existing) = appearances
        .iter_mut()
        .find(|appearance| appearance.media.id == media.id)
    {
        for name in names {
            if !existing.characters.contains(&name) {
                existing.characters.push(name);
            }
        }
        existing.role = existing.role.or(edge.role);
        return;
    }
    let mut appearance = Appearance::new(media);
    appearance.role = edge.role;
    appearance.characters = names;
    appearances.push(appearance);
}

fn merge_credit(appearances: &mut Vec<Appearance>, edge: RawAppearanceEdge) {
    let Some(node) = edge.node.filter(is_visible) else {
        return;
    };
    let credit = edge.staff_role.filter(|text| !text.trim().is_empty());
    let media = map_summary(node);
    if let Some(existing) = appearances
        .iter_mut()
        .find(|appearance| appearance.media.id == media.id)
    {
        existing.credit = existing.credit.take().or(credit);
        return;
    }
    let mut appearance = Appearance::new(media);
    appearance.credit = credit;
    appearances.push(appearance);
}

pub fn map_profile(raw: RawProfile) -> Profile {
    let facts = profile_facts(&raw);
    let description = raw.description.clone().unwrap_or_default();
    let links = profile_links(raw.site_url.as_deref(), &description);
    let mut profile = Profile::new(raw.id, raw.name.full.unwrap_or_else(|| NAMELESS.into()));
    profile.native_name = raw.name.native.filter(|name| !name.trim().is_empty());
    profile.image_url = raw
        .image
        .and_then(|image| image.large.or(image.extra_large));
    profile.description = sanitize_description(&description);
    profile.facts = facts;
    profile.links = links;
    for edge in raw.media.and_then(|media| media.edges).unwrap_or_default() {
        merge(&mut profile.appearances, edge);
    }
    for edge in raw
        .staff_media
        .and_then(|media| media.edges)
        .unwrap_or_default()
    {
        merge_credit(&mut profile.appearances, edge);
    }
    profile
}
