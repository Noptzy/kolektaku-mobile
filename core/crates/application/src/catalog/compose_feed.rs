use domain::media::MediaSummary;

use super::MediaCard;
use super::compose::{SiteItems, catalog_card, fold_into_group, layout, linked_for, site_card};

pub fn compose_feed(
    media: Vec<MediaSummary>,
    sites: &[SiteItems],
    now_secs: u64,
) -> Vec<MediaCard> {
    let (flat, assignments) = layout(&media, sites);
    let mut candidates: Vec<Option<MediaSummary>> = media.into_iter().map(Some).collect();
    let mut cards: Vec<MediaCard> = Vec::new();
    for (index, entry) in flat.iter().enumerate() {
        let assignment = assignments.iter().find(|found| found.item_index == index);
        let Some(assignment) = assignment else {
            let site = &sites[entry.site];
            if !fold_into_group(&mut cards, site, entry.item, now_secs) {
                cards.push(site_card(site, entry.item, now_secs));
            }
            continue;
        };
        if let Some(summary) = candidates[assignment.media_index].take() {
            let linked = linked_for(assignment.media_index, &flat, &assignments, sites);
            cards.push(catalog_card(summary, linked, now_secs));
        }
    }
    cards
}

#[cfg(test)]
mod tests {
    use domain::media::{MediaId, MediaKind, MediaTitle};
    use domain::source::{ItemId, SourceId, SourceItem};

    use super::*;

    fn anime(id: u64, title: &str) -> MediaSummary {
        MediaSummary::new(
            MediaId::new(id).unwrap(),
            MediaKind::Anime,
            MediaTitle::new(title),
        )
    }

    fn site(id: &str, titles: &[&str]) -> SiteItems {
        SiteItems {
            source: SourceId::new(id),
            items: titles
                .iter()
                .enumerate()
                .map(|(index, title)| SourceItem::new(ItemId::new(format!("{id}-{index}")), *title))
                .collect(),
        }
    }

    #[test]
    fn cards_follow_the_order_of_the_site_not_of_the_catalog() {
        let candidates = vec![anime(1, "Alpha"), anime(2, "Beta"), anime(3, "Gamma")];
        let cards = compose_feed(candidates, &[site("a", &["Gamma", "Alpha", "Beta"])], 5);
        let titles: Vec<&str> = cards.iter().map(|card| card.title.as_str()).collect();
        assert_eq!(titles, vec!["Gamma", "Alpha", "Beta"]);
    }

    #[test]
    fn catalog_entries_nobody_listed_never_appear() {
        let candidates = vec![anime(1, "Alpha"), anime(2, "Unlisted Show")];
        let cards = compose_feed(candidates, &[site("a", &["Alpha"])], 5);
        assert_eq!(cards.len(), 1);
        assert!(cards[0].summary.is_some());
    }

    #[test]
    fn items_unknown_to_the_catalog_stay_as_site_cards_in_place() {
        let cards = compose_feed(
            vec![anime(1, "Alpha")],
            &[site("a", &["Mystery", "Alpha"])],
            5,
        );
        assert_eq!(cards[0].title, "Mystery");
        assert!(cards[0].summary.is_none());
        assert_eq!(cards[1].title, "Alpha");
    }

    #[test]
    fn two_sites_listing_the_same_title_share_one_card() {
        let candidates = vec![anime(1, "Alpha")];
        let cards = compose_feed(
            candidates,
            &[site("a", &["Alpha"]), site("b", &["Alpha"])],
            5,
        );
        assert_eq!(cards.len(), 1);
        assert_eq!(cards[0].links.len(), 2);
    }

    #[test]
    fn nothing_listed_means_no_cards() {
        assert!(compose_feed(vec![anime(1, "Alpha")], &[], 5).is_empty());
    }
}
