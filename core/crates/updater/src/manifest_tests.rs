use semver::Version;

use crate::error::UpdateError;
use crate::manifest::{host_allowed, parse_manifest};

const HASH: &str = "ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12";
const URL: &str = "https://github.com/Noptzy/kolektaku-mobile/releases/download/v2.1.0/a.apk";

fn manifest(assets: &str) -> String {
    format!(
        r#"{{"version":"2.1.0","minSupported":"2.0.0","notes":"  Perbaikan  ","assets":{assets}}}"#
    )
}

fn good_asset() -> String {
    format!(r#"{{"url":"{URL}","size":1234,"sha256":"{HASH}"}}"#)
}

#[test]
fn a_complete_manifest_is_read() {
    let parsed =
        parse_manifest(&manifest(&format!(r#"{{"arm64-v8a":{}}}"#, good_asset()))).unwrap();
    assert_eq!(parsed.version, Version::new(2, 1, 0));
    assert_eq!(parsed.min_supported, Version::new(2, 0, 0));
    assert_eq!(parsed.notes, "Perbaikan");
    let asset = &parsed.assets["arm64-v8a"];
    assert_eq!((asset.url.as_str(), asset.size), (URL, 1234));
    assert_eq!(asset.sha256, HASH);
}

#[test]
fn a_leading_v_and_a_missing_minimum_are_tolerated() {
    let parsed = parse_manifest(r#"{"version":"v3.0.0-rc1","assets":{}}"#).unwrap();
    assert_eq!(parsed.version, Version::parse("3.0.0-rc1").unwrap());
    assert_eq!(parsed.min_supported, Version::new(0, 0, 0));
    assert!(parsed.notes.is_empty());
}

#[test]
fn empty_asset_objects_are_skipped_not_errors() {
    let parsed = parse_manifest(&manifest(&format!(
        r#"{{"arm64-v8a":{},"armeabi-v7a":{{}},"x86_64":{{}}}}"#,
        good_asset()
    )))
    .unwrap();
    assert_eq!(parsed.assets.len(), 1);
}

#[test]
fn assets_from_other_hosts_or_without_https_are_dropped() {
    for url in [
        "http://github.com/a.apk",
        "https://evil.example.com/a.apk",
        "https://github.com.evil.test/a.apk",
        "ftp://github.com/a.apk",
        "not a url",
    ] {
        let asset = format!(r#"{{"url":"{url}","size":1,"sha256":"{HASH}"}}"#);
        let parsed = parse_manifest(&manifest(&format!(r#"{{"a":{asset}}}"#))).unwrap();
        assert!(parsed.assets.is_empty(), "{url}");
    }
}

#[test]
fn a_broken_hash_or_size_drops_the_asset() {
    for asset in [
        format!(r#"{{"url":"{URL}","size":1,"sha256":"short"}}"#),
        format!(
            r#"{{"url":"{URL}","size":1,"sha256":"{}"}}"#,
            "z".repeat(64)
        ),
        format!(r#"{{"url":"{URL}","size":0,"sha256":"{HASH}"}}"#),
        format!(r#"{{"url":"{URL}","sha256":"{HASH}"}}"#),
    ] {
        let parsed = parse_manifest(&manifest(&format!(r#"{{"a":{asset}}}"#))).unwrap();
        assert!(parsed.assets.is_empty(), "{asset}");
    }
}

#[test]
fn an_uppercase_hash_is_lowered() {
    let asset = format!(
        r#"{{"url":"{URL}","size":9,"sha256":"{}"}}"#,
        HASH.to_uppercase()
    );
    let parsed = parse_manifest(&manifest(&format!(r#"{{"a":{asset}}}"#))).unwrap();
    assert_eq!(parsed.assets["a"].sha256, HASH);
}

#[test]
fn a_manifest_that_is_not_one_is_refused() {
    for text in [
        "",
        "nope",
        "[]",
        r#"{"assets":{}}"#,
        r#"{"version":"x.y","assets":{}}"#,
    ] {
        assert!(matches!(
            parse_manifest(text),
            Err(UpdateError::BadManifest(_))
        ));
    }
    let bad_minimum = r#"{"version":"2.0.0","minSupported":"soon","assets":{}}"#;
    assert!(matches!(
        parse_manifest(bad_minimum),
        Err(UpdateError::BadManifest(_))
    ));
}

#[test]
fn only_the_release_hosts_are_trusted() {
    assert!(host_allowed("https://github.com/a/b"));
    assert!(host_allowed("https://objects.githubusercontent.com/x"));
    assert!(host_allowed(
        "https://release-assets.githubusercontent.com/x"
    ));
    assert!(!host_allowed("http://github.com/a"));
    assert!(!host_allowed("https://githubusercontent.com/a"));
    assert!(!host_allowed("https://github.com.evil.test/a"));
    assert!(!host_allowed(""));
}

#[test]
fn the_crate_does_not_depend_on_any_project_crate() {
    let manifest = include_str!("../Cargo.toml");
    for crate_name in ["domain", "application", "infrastructure", "bridge"] {
        assert!(!manifest.contains(crate_name), "{crate_name}");
    }
}
