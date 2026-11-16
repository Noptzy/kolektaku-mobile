use domain::source::{LinkVariant, SourceItem};

use super::MediaCard;
use super::compose::SiteItems;
use crate::matching::{audio_variant_of, title_similarity, without_audio_marker};

const SAME_WORK: f64 = 0.95;

pub(super) fn is_twin(item: &SourceItem) -> bool {
    audio_variant_of(&item.title).is_some()
}

pub(super) fn attach_variant(cards: &mut [MediaCard], site: &SiteItems, twin: &SourceItem) -> bool {
    let Some(audio) = audio_variant_of(&twin.title) else {
        return false;
    };
    let wanted = [without_audio_marker(&twin.title)];
    for card in cards.iter_mut() {
        for link in card
            .links
            .iter_mut()
            .filter(|link| link.source == site.source)
        {
            let Some(primary) = site.items.iter().find(|item| item.item_id == link.item) else {
                continue;
            };
            if title_similarity(&wanted, &without_audio_marker(&primary.title)) < SAME_WORK {
                continue;
            }
            if link.variants.iter().all(|known| known.audio != audio) {
                link.variants
                    .push(LinkVariant::new(twin.item_id.clone(), audio));
            }
            return true;
        }
    }
    false
}

#[cfg(test)]
mod tests {
    use domain::matching::Confidence;
    use domain::media::MediaRef;
    use domain::source::{ItemId, SourceId, SourceLink};

    use super::*;

    fn site(items: Vec<SourceItem>) -> SiteItems {
        SiteItems {
            source: SourceId::new("a"),
            items,
        }
    }

    fn card_linking(item: &str) -> MediaCard {
        MediaCard {
            reference: MediaRef::source(SourceId::new("a"), ItemId::new(item)),
            title: "Kimetsu no Yaiba".into(),
            cover_url: None,
            latest_label: None,
            summary: None,
            links: vec![SourceLink::matched(
                SourceId::new("a"),
                ItemId::new(item),
                Confidence::new(1.0),
                0,
            )],
        }
    }

    #[test]
    fn a_dub_twin_joins_the_link_of_its_plain_entry() {
        let plain = SourceItem::new(ItemId::new("280"), "Kimetsu no Yaiba");
        let twin = SourceItem::new(ItemId::new("2120"), "Kimetsu no Yaiba (Dub ID)");
        let found = site(vec![plain, twin.clone()]);
        let mut cards = vec![card_linking("280")];
        assert!(attach_variant(&mut cards, &found, &twin));
        assert_eq!(cards[0].links[0].variants.len(), 1);
        assert_eq!(cards[0].links[0].variants[0].audio, "Dub Indonesia");
        assert!(attach_variant(&mut cards, &found, &twin));
        assert_eq!(cards[0].links[0].variants.len(), 1);
    }

    #[test]
    fn a_twin_of_another_work_is_left_alone() {
        let plain = SourceItem::new(ItemId::new("280"), "Kimetsu no Yaiba");
        let twin = SourceItem::new(
            ItemId::new("2123"),
            "Kimetsu no Yaiba: Yuukaku-hen (Dub ID)",
        );
        let found = site(vec![plain, twin.clone()]);
        let mut cards = vec![card_linking("280")];
        assert!(!attach_variant(&mut cards, &found, &twin));
        assert!(cards[0].links[0].variants.is_empty());
    }

    #[test]
    fn only_dub_entries_count_as_twins() {
        let plain = SourceItem::new(ItemId::new("280"), "Kimetsu no Yaiba");
        assert!(!is_twin(&plain));
        assert!(is_twin(&SourceItem::new(
            ItemId::new("1"),
            "Show (Dub Indo)"
        )));
    }
}
