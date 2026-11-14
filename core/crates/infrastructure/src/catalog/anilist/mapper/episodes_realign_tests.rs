use super::episodes::map_episodes;
use crate::catalog::anilist::schema::RawStreamingEpisode;

fn numbered(list: &[u32], total: Option<u32>) -> Vec<f64> {
    let raw = list
        .iter()
        .map(|number| raw(Some(&format!("Episode {number} - T{number}")), None))
        .collect();
    map_episodes(Some(raw), total)
        .iter()
        .map(|item| item.number)
        .collect()
}

fn raw(title: Option<&str>, thumbnail: Option<&str>) -> RawStreamingEpisode {
    RawStreamingEpisode {
        title: title.map(str::to_string),
        thumbnail: thumbnail.map(str::to_string),
    }
}

#[test]
fn a_season_that_continues_the_numbering_starts_again_at_one() {
    assert_eq!(
        numbered(&[13, 14, 15, 16], Some(4)),
        vec![1.0, 2.0, 3.0, 4.0]
    );
}

#[test]
fn a_continued_season_keeps_its_titles_with_the_new_numbers() {
    let raw = vec![
        raw(Some("Episode 25 - Last"), Some("https://img.test/l.jpg")),
        raw(Some("Episode 24 - Prior"), None),
    ];
    let episodes = map_episodes(Some(raw), Some(2));
    assert_eq!(episodes[0].number, 1.0);
    assert_eq!(episodes[0].title, "Prior");
    assert_eq!(episodes[1].title, "Last");
    assert!(episodes[1].thumbnail_url.is_some());
}

#[test]
fn a_partial_list_inside_the_season_is_never_shifted() {
    assert_eq!(numbered(&[3, 4], Some(13)), vec![3.0, 4.0]);
}

#[test]
fn a_list_with_gaps_is_never_shifted() {
    assert_eq!(numbered(&[2, 4, 5], Some(12)), vec![2.0, 4.0, 5.0]);
}

#[test]
fn an_unknown_total_never_shifts_anything() {
    assert_eq!(numbered(&[13, 14, 15], None), vec![13.0, 14.0, 15.0]);
}

#[test]
fn a_list_that_already_starts_at_one_stays() {
    assert_eq!(numbered(&[1, 2, 3], Some(3)), vec![1.0, 2.0, 3.0]);
}

#[test]
fn half_episodes_stop_the_shift() {
    let raw = vec![
        raw(Some("Episode 13 - A"), None),
        raw(Some("Episode 13.5 - B"), None),
    ];
    let numbers: Vec<f64> = map_episodes(Some(raw), Some(14))
        .iter()
        .map(|item| item.number)
        .collect();
    assert_eq!(numbers, vec![13.0, 13.5]);
}

#[test]
fn the_list_of_a_longer_season_is_not_used_for_a_shorter_one() {
    let all: Vec<u32> = (1..=26).collect();
    assert!(numbered(&all, Some(11)).is_empty());
}

#[test]
fn a_list_beyond_the_total_that_cannot_be_realigned_is_dropped() {
    assert!(numbered(&[13, 14], Some(13)).is_empty());
    assert!(numbered(&[13, 15, 16], Some(3)).is_empty());
}

#[test]
fn a_list_within_the_total_is_kept_whole() {
    assert_eq!(numbered(&[1, 2, 3], Some(11)), vec![1.0, 2.0, 3.0]);
}

#[test]
fn an_airing_season_without_a_total_keeps_whatever_is_listed() {
    let all: Vec<u32> = (1..=26).collect();
    assert_eq!(numbered(&all, None).len(), 26);
}
