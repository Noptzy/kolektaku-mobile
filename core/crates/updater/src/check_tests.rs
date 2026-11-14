use crate::check::{RELEASE_REPO, check, manifest_url};
use crate::decision::Decision;
use crate::error::UpdateError;
use crate::testing::FakeTransport;

const HASH: &str = "ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12";

fn latest() -> String {
    format!(
        r#"{{"version":"2.1.0","minSupported":"2.0.0","notes":"baru","assets":{{"arm64-v8a":{{"url":"https://github.com/Noptzy/kolektaku-mobile/releases/download/v2.1.0/a.apk","size":10,"sha256":"{HASH}"}}}}}}"#
    )
}

fn arm() -> Vec<String> {
    vec!["arm64-v8a".to_string()]
}

#[test]
fn the_manifest_lives_in_the_public_release_repo() {
    assert_eq!(RELEASE_REPO, "Noptzy/kolektaku-mobile");
    assert_eq!(
        manifest_url(),
        "https://github.com/Noptzy/kolektaku-mobile/releases/latest/download/latest.json"
    );
}

#[tokio::test]
async fn a_newer_release_is_offered() {
    let transport = FakeTransport::with_text(&latest());
    let decision = check(&transport, &manifest_url(), "2.0.0", &arm())
        .await
        .unwrap();
    assert!(matches!(decision, Decision::Available(_)));
}

#[tokio::test]
async fn the_same_release_is_up_to_date() {
    let transport = FakeTransport::with_text(&latest());
    let decision = check(&transport, &manifest_url(), "2.1.0", &arm())
        .await
        .unwrap();
    assert_eq!(decision, Decision::UpToDate);
}

#[tokio::test]
async fn an_untrusted_manifest_address_is_never_fetched() {
    let transport = FakeTransport::with_text(&latest());
    let result = check(
        &transport,
        "https://evil.example.com/latest.json",
        "2.0.0",
        &arm(),
    )
    .await;
    assert!(matches!(result, Err(UpdateError::Untrusted(_))));
}

#[tokio::test]
async fn offline_is_an_error_the_caller_can_ignore() {
    let transport = FakeTransport::failing(UpdateError::Network("down".into()));
    let result = check(&transport, &manifest_url(), "2.0.0", &arm()).await;
    assert_eq!(result, Err(UpdateError::Network("down".into())));
}

#[tokio::test]
async fn a_garbled_manifest_is_a_typed_error() {
    let transport = FakeTransport::with_text("<html>oops</html>");
    let result = check(&transport, &manifest_url(), "2.0.0", &arm()).await;
    assert!(matches!(result, Err(UpdateError::BadManifest(_))));
}

#[tokio::test]
async fn a_broken_installed_version_is_reported() {
    let transport = FakeTransport::with_text(&latest());
    let result = check(&transport, &manifest_url(), "banana", &arm()).await;
    assert!(matches!(result, Err(UpdateError::BadManifest(_))));
}

#[tokio::test]
async fn the_installed_version_may_carry_a_build_number() {
    let transport = FakeTransport::with_text(&latest());
    let decision = check(&transport, &manifest_url(), "2.0.0+20000", &arm())
        .await
        .unwrap();
    assert!(matches!(decision, Decision::Available(_)));
}
