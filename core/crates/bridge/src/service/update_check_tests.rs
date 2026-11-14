use super::update::check_for_update;
use super::update_support::{Scripted, URL, arm, manifest, offer_for};
use crate::dto::update::UpdateOfferDto;
use crate::error::BridgeErrorKind;

#[tokio::test]
async fn a_newer_release_becomes_an_offer_with_everything_the_download_needs() {
    let payload = vec![7u8; 100];
    let transport = Scripted::new(manifest("2.1.0", "2.0.0", &payload), payload.clone(), 1);
    let offer = check_for_update(&transport, URL, "2.0.0", &arm())
        .await
        .unwrap()
        .unwrap();
    assert_eq!(
        offer,
        UpdateOfferDto {
            notes: "catatan".into(),
            ..offer_for(&payload)
        }
    );
}

#[tokio::test]
async fn an_installed_version_below_the_minimum_is_marked_required() {
    let payload = vec![1u8; 10];
    let transport = Scripted::new(manifest("2.1.0", "2.0.5", &payload), payload, 1);
    let offer = check_for_update(&transport, URL, "2.0.0", &arm())
        .await
        .unwrap()
        .unwrap();
    assert!(offer.required);
}

#[tokio::test]
async fn being_current_means_no_offer() {
    let payload = vec![1u8; 10];
    let transport = Scripted::new(manifest("2.1.0", "2.0.0", &payload), payload, 1);
    assert_eq!(
        check_for_update(&transport, URL, "2.1.0", &arm()).await,
        Ok(None)
    );
}

#[tokio::test]
async fn a_device_without_a_build_gets_an_unsupported_error() {
    let payload = vec![1u8; 10];
    let transport = Scripted::new(manifest("2.1.0", "2.0.0", &payload), payload, 1);
    let error = check_for_update(&transport, URL, "2.0.0", &["x86".to_string()])
        .await
        .unwrap_err();
    assert_eq!(error.kind, BridgeErrorKind::Unsupported);
}

#[tokio::test]
async fn an_untrusted_manifest_address_is_unavailable() {
    let payload = vec![1u8; 10];
    let transport = Scripted::new(manifest("2.1.0", "2.0.0", &payload), payload, 1);
    let error = check_for_update(&transport, "https://evil.test/x.json", "2.0.0", &arm())
        .await
        .unwrap_err();
    assert_eq!(error.kind, BridgeErrorKind::Unavailable);
}
