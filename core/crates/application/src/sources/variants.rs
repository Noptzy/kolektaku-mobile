use domain::source::{ItemId, LinkVariant};

use crate::matching::{ListedCandidate, audio_variant_of, title_similarity, without_audio_marker};

const SAME_WORK: f64 = 0.95;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Split {
    pub primaries: Vec<ListedCandidate>,
    pub variants: Vec<ListedCandidate>,
}

pub fn split_variants(listed: Vec<ListedCandidate>) -> Split {
    let (variants, primaries): (Vec<_>, Vec<_>) = listed
        .into_iter()
        .partition(|candidate| audio_variant_of(&candidate.title).is_some());
    if primaries.is_empty() {
        return Split {
            primaries: variants,
            variants: Vec::new(),
        };
    }
    Split {
        primaries,
        variants,
    }
}

pub fn variants_of(primary_title: &str, variants: &[ListedCandidate]) -> Vec<LinkVariant> {
    let wanted = [without_audio_marker(primary_title)];
    let mut found: Vec<LinkVariant> = Vec::new();
    for candidate in variants {
        let Some(audio) = audio_variant_of(&candidate.title) else {
            continue;
        };
        let base = without_audio_marker(&candidate.title);
        let same_work = title_similarity(&wanted, &base) >= SAME_WORK;
        if same_work && found.iter().all(|known| known.audio != audio) {
            found.push(LinkVariant::new(ItemId::new(candidate.key.clone()), audio));
        }
    }
    found
}

#[cfg(test)]
mod tests {
    use super::*;

    fn listed(key: &str, title: &str) -> ListedCandidate {
        ListedCandidate {
            key: key.into(),
            title: title.into(),
        }
    }

    #[test]
    fn dub_twins_are_set_apart_from_the_primary_entries() {
        let split = split_variants(vec![
            listed("2120", "Kimetsu no Yaiba (Dub ID)"),
            listed("280", "Kimetsu no Yaiba"),
        ]);
        assert_eq!(split.primaries, vec![listed("280", "Kimetsu no Yaiba")]);
        assert_eq!(split.variants.len(), 1);
    }

    #[test]
    fn a_site_with_only_a_dub_entry_keeps_it_as_the_primary() {
        let split = split_variants(vec![listed("9", "Show (Dub Indo)")]);
        assert_eq!(split.primaries.len(), 1);
        assert!(split.variants.is_empty());
    }

    #[test]
    fn only_twins_of_the_same_work_become_variants_of_the_primary() {
        let twins = [
            listed("2120", "Kimetsu no Yaiba (Dub ID)"),
            listed("2123", "Kimetsu no Yaiba: Yuukaku-hen (Dub ID)"),
        ];
        let found = variants_of("Kimetsu no Yaiba", &twins);
        assert_eq!(found.len(), 1);
        assert_eq!(found[0].item.as_str(), "2120");
        assert_eq!(found[0].audio, "Dub Indonesia");
    }

    #[test]
    fn each_audio_language_appears_once() {
        let twins = [
            listed("1", "Show (Dub ID)"),
            listed("2", "Show Dub Indo"),
            listed("3", "Show (English Dub)"),
        ];
        let audios: Vec<String> = variants_of("Show", &twins)
            .into_iter()
            .map(|variant| variant.audio)
            .collect();
        assert_eq!(audios, vec!["Dub Indonesia", "Dub Inggris"]);
    }
}
