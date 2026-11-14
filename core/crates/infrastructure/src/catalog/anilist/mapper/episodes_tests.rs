use domain::media::EpisodeInfo;

use super::episodes::{map_episodes, parse_episode_title};
use crate::catalog::anilist::schema::RawStreamingEpisode;

fn map(raw: Option<Vec<RawStreamingEpisode>>) -> Vec<EpisodeInfo> {
    map_episodes(raw, None)
}

fn raw(title: Option<&str>, thumbnail: Option<&str>) -> RawStreamingEpisode {
    RawStreamingEpisode {
        title: title.map(str::to_string),
        thumbnail: thumbnail.map(str::to_string),
    }
}

#[test]
fn reads_the_number_and_the_title_after_a_dash() {
    assert_eq!(
        parse_episode_title("Episode 5 - Cruelty"),
        Some((5.0, "Cruelty".to_string()))
    );
}

#[test]
fn accepts_other_prefixes_separators_and_case() {
    assert_eq!(
        parse_episode_title("EPISODE 12: The Hunt"),
        Some((12.0, "The Hunt".to_string()))
    );
    assert_eq!(
        parse_episode_title("Ep. 3 \u{2013} Night"),
        Some((3.0, "Night".to_string()))
    );
    assert_eq!(
        parse_episode_title("ep 7 - Rain"),
        Some((7.0, "Rain".to_string()))
    );
}

#[test]
fn keeps_a_title_that_contains_dashes_and_numbers() {
    assert_eq!(
        parse_episode_title("Episode 9 - Re-Start 2"),
        Some((9.0, "Re-Start 2".to_string()))
    );
}

#[test]
fn a_half_episode_keeps_its_fraction() {
    assert_eq!(
        parse_episode_title("Episode 6.5 - Recap"),
        Some((6.5, "Recap".to_string()))
    );
}

#[test]
fn an_episode_with_no_title_has_an_empty_one() {
    assert_eq!(parse_episode_title("Episode 4"), Some((4.0, String::new())));
}

#[test]
fn titles_in_other_shapes_are_not_guessed() {
    assert_eq!(parse_episode_title("Season 2 Episode 3 - X"), None);
    assert_eq!(parse_episode_title("Cruelty"), None);
    assert_eq!(parse_episode_title("Episode - Cruelty"), None);
    assert_eq!(parse_episode_title(""), None);
}

#[test]
fn maps_sorted_with_thumbnails() {
    let episodes = map(Some(vec![
        raw(Some("Episode 2 - B"), Some("https://img.test/2.jpg")),
        raw(Some("Episode 1 - A"), Some("https://img.test/1.jpg")),
    ]));
    let numbers: Vec<f64> = episodes.iter().map(|item| item.number).collect();
    assert_eq!(numbers, vec![1.0, 2.0]);
    assert_eq!(episodes[0].title, "A");
    assert_eq!(
        episodes[0].thumbnail_url.as_deref(),
        Some("https://img.test/1.jpg")
    );
}

#[test]
fn the_first_entry_of_a_number_wins() {
    let episodes = map(Some(vec![
        raw(Some("Episode 1 - First"), None),
        raw(Some("Episode 1 - Second"), Some("https://img.test/x.jpg")),
    ]));
    assert_eq!(episodes.len(), 1);
    assert_eq!(episodes[0].title, "First");
}

#[test]
fn entries_without_a_number_or_anything_to_show_are_dropped() {
    let episodes = map(Some(vec![
        raw(None, Some("https://img.test/a.jpg")),
        raw(Some("Bonus clip"), None),
        raw(Some("Episode 3"), None),
        raw(Some("Episode 4"), Some("")),
        raw(Some("Episode 5"), Some("https://img.test/5.jpg")),
    ]));
    let numbers: Vec<f64> = episodes.iter().map(|item| item.number).collect();
    assert_eq!(numbers, vec![5.0]);
    assert_eq!(episodes[0].title, "");
}

#[test]
fn nothing_listed_is_an_empty_list() {
    assert!(map(None).is_empty());
    assert!(map(Some(Vec::new())).is_empty());
}

#[test]
fn an_empty_thumbnail_address_counts_as_none() {
    let episodes = map(Some(vec![raw(Some("Episode 1 - A"), Some(""))]));
    assert_eq!(episodes[0].thumbnail_url, None);
}
