use super::title::{clean_title, is_adult_genre};

#[test]
fn the_light_and_web_novel_marks_are_removed_from_the_end() {
    assert_eq!(clean_title("Mushoku Tensei LN"), "Mushoku Tensei");
    assert_eq!(clean_title("Overlord WN"), "Overlord");
    assert_eq!(clean_title("Overlord (LN)"), "Overlord");
    assert_eq!(clean_title("Overlord [WN]"), "Overlord");
    assert_eq!(clean_title("  Overlord   LN  "), "Overlord");
}

#[test]
fn a_title_without_a_mark_stays_the_same() {
    assert_eq!(clean_title("No Game No Life"), "No Game No Life");
    assert_eq!(
        clean_title("No Game No Life: Practical War Game"),
        "No Game No Life: Practical War Game"
    );
}

#[test]
fn letters_that_only_look_like_a_mark_are_kept() {
    assert_eq!(clean_title("Kaleidoscope LNA"), "Kaleidoscope LNA");
    assert_eq!(clean_title("Hell LNx"), "Hell LNx");
    assert_eq!(clean_title("Rain WNW"), "Rain WNW");
}

#[test]
fn a_title_that_is_only_a_mark_is_not_emptied() {
    assert_eq!(clean_title("LN"), "LN");
}

#[test]
fn a_mark_in_the_middle_is_not_touched() {
    assert_eq!(clean_title("LN Stories Today"), "LN Stories Today");
}

#[test]
fn the_shared_adult_labels_apply_but_mature_alone_does_not() {
    assert!(is_adult_genre("Adult"));
    assert!(is_adult_genre("Smut"));
    assert!(is_adult_genre("Hentai"));
    assert!(!is_adult_genre("Mature"));
    assert!(!is_adult_genre("Ecchi"));
    assert!(!is_adult_genre("Romance"));
}
