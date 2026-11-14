use std::collections::HashMap;

use domain::source::Unit;
use scraper::Html;

use super::ids::provider_path;
use crate::sources::support::{collapse, first_number, selector, text_of};

pub struct EpisodePage {
    pub episodes: Vec<Unit>,
    pub has_next_page: bool,
}

fn without_ordering_note(label: &str) -> String {
    for (index, _) in label.char_indices().filter(|(_, c)| *c == '(') {
        let tail = &label[index..];
        let noted = ["(terlama)", "(terbaru)"].iter().any(|note| {
            tail.get(..note.len())
                .is_some_and(|head| head.eq_ignore_ascii_case(note))
        });
        if noted {
            let before = label[..index].trim_end();
            return format!("{before}{}", &tail["(terlama)".len()..]);
        }
    }
    label.to_string()
}

fn popover_of(document: &Html) -> String {
    document
        .select(&selector("#episodeLists"))
        .next()
        .and_then(|element| element.value().attr("data-content"))
        .unwrap_or_default()
        .to_string()
}

pub fn parse_episode_page(html: &str) -> EpisodePage {
    let popover = popover_of(&Html::parse_document(html));
    let combined = Html::parse_document(&format!("{html}{popover}"));
    let episodes = combined
        .select(&selector("a[href*='/episode/']"))
        .filter_map(|anchor| {
            let label = without_ordering_note(&collapse(&text_of(anchor)));
            let id = provider_path(anchor.value().attr("href")?)?;
            let number = first_number(&label)?;
            Some(Unit::new(id, number, label))
        })
        .collect();
    let popover_document = Html::parse_fragment(&popover);
    let has_next_page = popover_document
        .select(&selector("a.page__link__episode"))
        .any(|link| link.select(&selector(".fa-forward")).next().is_some());
    EpisodePage {
        episodes,
        has_next_page,
    }
}

pub fn merge_episodes(episodes: Vec<Unit>) -> Vec<Unit> {
    let mut positions: HashMap<String, usize> = HashMap::new();
    let mut merged: Vec<Unit> = Vec::new();
    for episode in episodes {
        match positions.get(&episode.id) {
            Some(index) => merged[*index] = episode,
            None => {
                positions.insert(episode.id.clone(), merged.len());
                merged.push(episode);
            }
        }
    }
    merged.sort_by(|left, right| left.number.total_cmp(&right.number));
    merged
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::fixtures;

    #[test]
    fn lists_episodes_and_deduplicates_by_id_lowest_first() {
        let html = fixtures::kuramanime("detail-small.html");
        let page = parse_episode_page(&format!("{html}{html}"));
        let numbers: Vec<f64> = merge_episodes(page.episodes)
            .iter()
            .map(|unit| unit.number)
            .collect();
        assert_eq!(numbers, vec![1144.0, 1145.0]);
        assert!(!page.has_next_page);
    }

    #[test]
    fn reads_the_episodes_of_a_real_page_without_ordering_notes() {
        let page = parse_episode_page(&fixtures::kuramanime("detail-live.html"));
        assert!(page.episodes.len() > 5);
        let lower = |unit: &Unit| unit.label.to_lowercase();
        assert!(
            page.episodes
                .iter()
                .all(|unit| !lower(unit).contains("terlama") && !lower(unit).contains("terbaru"))
        );
        assert!(
            page.episodes
                .iter()
                .all(|unit| unit.id.contains("/episode/"))
        );
    }

    #[test]
    fn the_popover_inside_the_attribute_is_read_and_its_forward_arrow_means_more_pages() {
        let popover = r#"<a href="/anime/7/x/episode/2">Episode 2 (Terlama)</a><a class="page__link__episode" href="?page=2"><i class="fa fa-forward"></i></a>"#;
        let html = format!(r#"<a id="episodeLists" data-content='{popover}'>Daftar</a>"#);
        let page = parse_episode_page(&html);
        assert_eq!(page.episodes.len(), 1);
        assert_eq!(page.episodes[0].label, "Episode 2");
        assert_eq!(page.episodes[0].id, "7/x/episode/2");
        assert!(page.has_next_page);
    }

    #[test]
    fn a_backward_arrow_alone_is_not_a_next_page() {
        let popover =
            r#"<a class="page__link__episode" href="?page=1"><i class="fa fa-backward"></i></a>"#;
        let html = format!(r#"<a id="episodeLists" data-content='{popover}'>Daftar</a>"#);
        assert!(!parse_episode_page(&html).has_next_page);
    }

    #[test]
    fn links_without_a_number_or_a_path_are_skipped() {
        let html = r#"<a href="/anime/1/x/episode/3">Special</a><a href="/elsewhere/episode/4">Episode 4</a>"#;
        assert!(parse_episode_page(html).episodes.is_empty());
    }

    #[test]
    fn merging_keeps_the_last_duplicate_and_sorts_by_number() {
        let merged = merge_episodes(vec![
            Unit::new("a/b/episode/2", 2.0, "old"),
            Unit::new("a/b/episode/1", 1.0, "one"),
            Unit::new("a/b/episode/2", 2.0, "new"),
        ]);
        assert_eq!(merged.len(), 2);
        assert_eq!(merged[1].label, "new");
        assert_eq!(merged[0].number, 1.0);
    }
}
