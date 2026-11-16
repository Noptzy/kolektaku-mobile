use domain::media::{MediaFormat, MediaStatus};

use super::novel_title::{is_novel_target, is_novel_title_of};
use super::score::{MatchDecision, decide_match, score_candidate, score_title};
use super::target::{CandidateFacts, MatchTarget};

fn names(titles: &[&str]) -> Vec<String> {
    titles.iter().map(|title| title.to_string()).collect()
}

fn novel(titles: &[&str]) -> MatchTarget {
    MatchTarget {
        titles: names(titles),
        format: Some(MediaFormat::Novel),
        year: None,
        unit_count: Some(12),
        status: Some(MediaStatus::Finished),
    }
}

fn facts(title: &str, type_text: &str) -> CandidateFacts {
    CandidateFacts {
        titles: vec![title.to_string()],
        type_text: Some(type_text.to_string()),
        year: None,
        unit_count: Some(450),
    }
}

#[test]
fn a_site_title_equal_to_a_catalog_title_is_the_same_novel() {
    let targets = names(&[
        "Re:Zero kara Hajimeru Isekai Seikatsu",
        "Re:ZERO -Starting Life-",
    ]);
    assert!(is_novel_title_of(
        &targets,
        "Re:Zero Kara Hajimeru Isekai Seikatsu"
    ));
    assert!(is_novel_title_of(
        &targets,
        "Re:Zero Kara Hajimeru Isekai Seikatsu LN"
    ));
}

#[test]
fn the_main_title_before_a_subtitle_is_the_same_novel() {
    let targets = names(&["Mushoku Tensei: Isekai Ittara Honki Dasu"]);
    assert!(is_novel_title_of(&targets, "Mushoku Tensei"));
    assert!(is_novel_title_of(&targets, "Mushoku Tensei (Light Novel)"));
}

#[test]
fn a_title_with_extra_words_is_fan_fiction_and_is_refused() {
    let targets = names(&["Overlord"]);
    assert!(is_novel_title_of(&targets, "Overlord WN"));
    for fan in [
        "Overlord Tamer: All My Pet Monsters Have God Potential",
        "Mystic Overlord: Reading Gives Strength",
        "The Multiverse Overlord",
        "Overlord: The Dungeon",
    ] {
        assert!(!is_novel_title_of(&targets, fan), "{fan}");
    }
}

#[test]
fn a_short_main_title_is_trusted_when_the_catalog_title_continues_after_a_colon() {
    let targets = names(&["86: Eighty Six"]);
    assert!(is_novel_title_of(&targets, "86 LN"));
    assert!(!is_novel_title_of(&names(&["86 Eighty Six Extra"]), "86"));
    assert!(!is_novel_title_of(&names(&["Re:Zero kara Hajimeru"]), "Re"));
}

#[test]
fn the_wo_and_o_spellings_of_a_japanese_title_are_the_same() {
    let targets = names(&["Kono Subarashii Sekai ni Shukufuku wo!"]);
    assert!(is_novel_title_of(
        &targets,
        "Kono Subarashii Sekai ni Shukufuku o! LN"
    ));
}

#[test]
fn a_title_too_short_to_trust_is_refused() {
    let targets = names(&["Re:Zero kara Hajimeru Isekai Seikatsu"]);
    assert!(!is_novel_title_of(&targets, "Re"));
    assert!(!is_novel_title_of(&targets, "LN"));
    assert!(!is_novel_title_of(&targets, ""));
}

#[test]
fn a_different_season_or_part_of_the_same_title_does_not_pass_as_the_novel() {
    let targets = names(&["Sword Art Online"]);
    assert!(!is_novel_title_of(
        &targets,
        "Sword Art Online Progressive Aria"
    ));
}

#[test]
fn only_novels_use_the_strict_rule() {
    assert!(is_novel_target(&novel(&["A title"])));
    let mut comic = novel(&["A title"]);
    comic.format = Some(MediaFormat::Manga);
    assert!(!is_novel_target(&comic));
    assert!(score_title(&comic, "A title with extra words") > 0.0);
}

#[test]
fn a_fan_fiction_title_scores_nothing_for_a_novel() {
    let target = novel(&["Overlord"]);
    assert_eq!(
        score_title(&target, "Mystic Overlord: Reading Gives Strength"),
        0.0
    );
    assert!(score_title(&target, "Overlord LN") > 0.9);
    let fan = facts(
        "Overlord Tamer: All My Pet Monsters Have God Potential",
        "Web Novel",
    );
    assert_eq!(
        decide_match(score_candidate(&target, &fan)),
        MatchDecision::None
    );
}

#[test]
fn a_chapter_count_that_differs_does_not_lower_a_novel() {
    let target = novel(&["Mushoku Tensei: Isekai Ittara Honki Dasu"]);
    let found = facts("Mushoku Tensei", "Light Novel Jepang");
    assert_eq!(
        decide_match(score_candidate(&target, &found)),
        MatchDecision::Auto
    );
    assert!(score_candidate(&target, &found) >= 1.0 - f64::EPSILON);
}

#[test]
fn the_light_novel_beats_a_web_novel_of_the_same_title() {
    let target = novel(&["No Game No Life"]);
    let light = score_candidate(&target, &facts("No Game No Life", "Light Novel Jepang"));
    let web = score_candidate(&target, &facts("No Game No Life", "Web Novel"));
    assert!(light > web, "{light} vs {web}");
    assert_eq!(decide_match(web), MatchDecision::Auto);
}

#[test]
fn an_alternative_title_that_matches_is_enough() {
    let target = novel(&["Jobless Reincarnation"]);
    let found = CandidateFacts {
        titles: vec![
            "Judul Lokal".into(),
            "Jobless Reincarnation ~ Another World ~".into(),
        ],
        type_text: Some("Light Novel Jepang".into()),
        year: None,
        unit_count: None,
    };
    assert_eq!(
        decide_match(score_candidate(&target, &found)),
        MatchDecision::None
    );
    let exact = CandidateFacts {
        titles: vec!["Judul Lokal".into(), "Jobless Reincarnation".into()],
        ..found
    };
    assert!(score_candidate(&target, &exact) >= 0.95);
}
