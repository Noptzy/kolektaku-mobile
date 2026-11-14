use semver::Version;

use crate::decision::{Decision, decide};
use crate::error::UpdateError;
use crate::manifest::parse_manifest;

const HASH: &str = "ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12";

fn asset(name: &str) -> String {
    format!(
        r#""{name}":{{"url":"https://github.com/Noptzy/kolektaku-mobile/releases/download/v/{name}.apk","size":10,"sha256":"{HASH}"}}"#
    )
}

fn manifest(version: &str, minimum: &str, abis: &[&str]) -> crate::manifest::Manifest {
    let assets: Vec<String> = abis.iter().map(|abi| asset(abi)).collect();
    parse_manifest(&format!(
        r#"{{"version":"{version}","minSupported":"{minimum}","notes":"catatan","assets":{{{}}}}}"#,
        assets.join(",")
    ))
    .unwrap()
}

fn abis(list: &[&str]) -> Vec<String> {
    list.iter().map(ToString::to_string).collect()
}

fn installed(text: &str) -> Version {
    Version::parse(text).unwrap()
}

#[test]
fn the_same_or_a_newer_version_needs_nothing() {
    let remote = manifest("2.1.0", "2.0.0", &["arm64-v8a"]);
    assert_eq!(
        decide(&installed("2.1.0"), &remote, &abis(&["arm64-v8a"])),
        Ok(Decision::UpToDate)
    );
    assert_eq!(
        decide(&installed("2.2.0"), &remote, &abis(&["arm64-v8a"])),
        Ok(Decision::UpToDate)
    );
}

#[test]
fn an_older_version_is_offered_the_new_one() {
    let remote = manifest("2.1.0", "2.0.0", &["arm64-v8a"]);
    let decision = decide(&installed("2.0.0"), &remote, &abis(&["arm64-v8a"])).unwrap();
    let Decision::Available(update) = decision else {
        panic!("expected an offer");
    };
    assert_eq!(update.version, Version::new(2, 1, 0));
    assert_eq!(update.notes, "catatan");
    assert_eq!(update.abi, "arm64-v8a");
}

#[test]
fn below_the_minimum_the_update_is_required() {
    let remote = manifest("2.1.0", "2.0.5", &["arm64-v8a"]);
    let decision = decide(&installed("2.0.0"), &remote, &abis(&["arm64-v8a"])).unwrap();
    assert!(matches!(decision, Decision::Required(_)));
}

#[test]
fn exactly_the_minimum_is_still_only_an_offer() {
    let remote = manifest("2.1.0", "2.0.0", &["arm64-v8a"]);
    let decision = decide(&installed("2.0.0"), &remote, &abis(&["arm64-v8a"])).unwrap();
    assert!(matches!(decision, Decision::Available(_)));
}

#[test]
fn a_release_candidate_is_older_than_its_final_version() {
    let remote = manifest("2.0.0", "1.0.0", &["arm64-v8a"]);
    let decision = decide(&installed("2.0.0-rc1"), &remote, &abis(&["arm64-v8a"])).unwrap();
    assert!(matches!(decision, Decision::Available(_)));
    let rc2 = manifest("2.0.0-rc2", "1.0.0", &["arm64-v8a"]);
    assert!(matches!(
        decide(&installed("2.0.0-rc1"), &rc2, &abis(&["arm64-v8a"])),
        Ok(Decision::Available(_))
    ));
    assert_eq!(
        decide(&installed("2.0.0-rc2"), &rc2, &abis(&["arm64-v8a"])),
        Ok(Decision::UpToDate)
    );
}

#[test]
fn the_first_supported_abi_of_the_device_wins() {
    let remote = manifest("2.1.0", "2.0.0", &["armeabi-v7a", "arm64-v8a"]);
    let both = abis(&["arm64-v8a", "armeabi-v7a"]);
    let Decision::Available(update) = decide(&installed("2.0.0"), &remote, &both).unwrap() else {
        panic!();
    };
    assert_eq!(update.abi, "arm64-v8a");
    let older = abis(&["x86_64", "armeabi-v7a"]);
    let Decision::Available(update) = decide(&installed("2.0.0"), &remote, &older).unwrap() else {
        panic!();
    };
    assert_eq!(update.abi, "armeabi-v7a");
}

#[test]
fn a_device_without_a_matching_build_is_told_so() {
    let remote = manifest("2.1.0", "2.0.0", &["arm64-v8a"]);
    assert_eq!(
        decide(&installed("2.0.0"), &remote, &abis(&["x86"])),
        Err(UpdateError::NoAsset)
    );
    assert_eq!(
        decide(&installed("2.0.0"), &remote, &[]),
        Err(UpdateError::NoAsset)
    );
}

#[test]
fn a_missing_build_does_not_matter_when_already_current() {
    let remote = manifest("2.1.0", "2.0.0", &[]);
    assert_eq!(
        decide(&installed("2.1.0"), &remote, &abis(&["arm64-v8a"])),
        Ok(Decision::UpToDate)
    );
}
