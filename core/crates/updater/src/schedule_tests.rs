use crate::schedule::{CHECK_INTERVAL_SECS, due};

#[test]
fn the_first_run_always_checks() {
    assert!(due(None, 1_000, false));
}

#[test]
fn a_recent_check_is_not_repeated() {
    assert!(!due(Some(1_000), 1_000, false));
    assert!(!due(Some(1_000), 1_000 + CHECK_INTERVAL_SECS - 1, false));
}

#[test]
fn after_twelve_hours_it_checks_again() {
    assert!(due(Some(1_000), 1_000 + CHECK_INTERVAL_SECS, false));
    assert!(due(Some(1_000), 1_000 + 3 * CHECK_INTERVAL_SECS, false));
}

#[test]
fn a_manual_check_ignores_the_schedule() {
    assert!(due(Some(1_000), 1_001, true));
}

#[test]
fn a_clock_set_back_does_not_block_checking_forever() {
    assert!(due(Some(5_000_000), 1_000, false));
}

#[test]
fn the_interval_is_twelve_hours() {
    assert_eq!(CHECK_INTERVAL_SECS, 43_200);
}
