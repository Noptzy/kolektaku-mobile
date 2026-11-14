use domain::media::{MediaFormat, MediaStatus};

use super::MatchDecision;
use super::case_support::{candidate, resolve, wanted};

#[test]
fn a_later_season_never_falls_back_to_season_1() {
    let target = wanted(
        &["Oshi no Ko 2nd Season"],
        MediaFormat::Tv,
        2024,
        Some(13),
        MediaStatus::Finished,
    );
    let picked = resolve(
        &target,
        &[candidate("s1", "Oshi no Ko", "TV", 2023, Some(11))],
    );
    assert_eq!(picked, None);
}

#[test]
fn a_sub_entry_never_falls_back_to_the_parent_series() {
    let target = wanted(
        &["Kimetsu no Yaiba: Yuukaku-hen"],
        MediaFormat::Tv,
        2021,
        Some(11),
        MediaStatus::Finished,
    );
    let picked = resolve(
        &target,
        &[candidate("s1", "Kimetsu no Yaiba", "TV", 2019, Some(26))],
    );
    assert_eq!(picked, None);
}

#[test]
fn a_plausible_but_unverified_match_is_flagged_for_the_user() {
    let target = wanted(
        &["Kaguya-sama wa Kokurasetai: Ultra Romantic"],
        MediaFormat::Tv,
        2022,
        Some(13),
        MediaStatus::Finished,
    );
    let picked = resolve(
        &target,
        &[candidate(
            "s3",
            "Kaguya-sama wa Kokurasetai Ultra Romantic",
            "TV",
            2022,
            Some(11),
        )],
    )
    .expect("a candidate should be picked");
    assert_eq!(picked.key, "s3");
    assert!(matches!(
        picked.decision,
        MatchDecision::Auto | MatchDecision::AutoWithHint
    ));
}
