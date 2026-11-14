use std::collections::HashMap;

use domain::library::{Favorite, Progress, UnitOrder};
use domain::media::{MediaKind, MediaRef};

#[derive(Default)]
pub(super) struct State {
    pub(super) favorites: Vec<Favorite>,
    pub(super) history: Vec<Progress>,
    pub(super) orders: HashMap<(MediaKind, MediaRef), UnitOrder>,
    pub(super) preferences: HashMap<String, String>,
    pub(super) searches: HashMap<MediaKind, Vec<String>>,
}

pub(super) fn same_entry(
    progress: &Progress,
    kind: MediaKind,
    media: &MediaRef,
    unit: f64,
) -> bool {
    progress.entry.kind == kind
        && progress.entry.media == *media
        && (progress.entry.unit_number - unit).abs() < 1e-9
}
