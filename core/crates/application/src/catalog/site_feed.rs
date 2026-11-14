use domain::error::SourceError;
use domain::media::{MediaKind, MediaSummary};

use super::MediaCard;
use super::compose::SiteItems;
use super::compose_feed::compose_feed;
use crate::ports::MetadataCatalog;

const TITLES_PER_SITE: usize = 20;

fn unique_media(found: Vec<Vec<MediaSummary>>) -> Vec<MediaSummary> {
    let mut unique: Vec<MediaSummary> = Vec::new();
    for media in found.into_iter().flatten() {
        if !unique.iter().any(|known| known.id == media.id) {
            unique.push(media);
        }
    }
    unique
}

pub async fn cards_for_sites<C: MetadataCatalog>(
    catalog: &C,
    kind: MediaKind,
    mut sites: Vec<SiteItems>,
    now_secs: u64,
) -> (Vec<MediaCard>, Option<SourceError>) {
    for site in &mut sites {
        site.items.truncate(TITLES_PER_SITE);
    }
    let titles: Vec<String> = sites
        .iter()
        .flat_map(|site| site.items.iter().map(|item| item.title.clone()))
        .collect();
    let (candidates, failure) = match catalog.match_titles(kind, &titles).await {
        Ok(found) => (unique_media(found), None),
        Err(error) => (Vec::new(), Some(error)),
    };
    (compose_feed(candidates, &sites, now_secs), failure)
}
