use crate::download::{Progress, download};
use crate::error::UpdateError;
use crate::manifest::Asset;
use crate::testing::{FakeTransport, OK_URL, Served, bytes, scratch, sha_of, whole};

pub fn asset_for(body: &[u8]) -> Asset {
    Asset {
        url: OK_URL.into(),
        size: body.len() as u64,
        sha256: sha_of(body),
    }
}

#[tokio::test]
async fn a_download_is_written_verified_and_named() {
    let body = bytes(10_000);
    let folder = scratch("plain");
    let target = folder.join("update.apk");
    let transport = FakeTransport::serving(vec![whole(&body, 4)]);
    let path = download(&transport, &asset_for(&body), &target, |_| {})
        .await
        .unwrap();
    assert_eq!(path, target);
    assert_eq!(std::fs::read(&target).unwrap(), body);
    assert!(!folder.join("update.apk.part").exists());
    assert_eq!(transport.asked(), vec![(OK_URL.to_string(), 0)]);
}

#[tokio::test]
async fn progress_climbs_to_the_whole_size() {
    let body = bytes(9_000);
    let mut seen: Vec<Progress> = Vec::new();
    let folder = scratch("progress");
    let transport = FakeTransport::serving(vec![whole(&body, 3)]);
    let target = folder.join("update.apk");
    download(&transport, &asset_for(&body), &target, |step: Progress| {
        seen.push(step)
    })
    .await
    .unwrap();
    assert_eq!(seen.len(), 3);
    assert!(
        seen.windows(2)
            .all(|pair| pair[0].received < pair[1].received)
    );
    assert_eq!(seen.last().unwrap().received, 9_000);
    assert!(seen.iter().all(|step| step.total == 9_000));
}

#[tokio::test]
async fn a_wrong_hash_is_refused_and_nothing_is_left_behind() {
    let body = bytes(2_000);
    let mut asset = asset_for(&body);
    asset.sha256 = sha_of(b"something else");
    let folder = scratch("hash");
    let target = folder.join("update.apk");
    let transport = FakeTransport::serving(vec![whole(&body, 2)]);
    let result = download(&transport, &asset, &target, |_| {}).await;
    assert_eq!(result, Err(UpdateError::HashMismatch));
    assert!(!target.exists());
    assert!(!folder.join("update.apk.part").exists());
}

#[tokio::test]
async fn a_tampered_body_of_the_right_size_is_refused() {
    let body = bytes(2_000);
    let mut forged = body.clone();
    forged[100] ^= 0xFF;
    let folder = scratch("forged");
    let target = folder.join("update.apk");
    let transport = FakeTransport::serving(vec![whole(&forged, 2)]);
    let result = download(&transport, &asset_for(&body), &target, |_| {}).await;
    assert_eq!(result, Err(UpdateError::HashMismatch));
    assert!(!target.exists());
}

#[tokio::test]
async fn a_body_of_the_wrong_size_is_refused() {
    let body = bytes(2_000);
    let folder = scratch("size");
    let target = folder.join("update.apk");
    let transport = FakeTransport::serving(vec![whole(&body[..1_500], 1)]);
    let result = download(&transport, &asset_for(&body), &target, |_| {}).await;
    assert_eq!(
        result,
        Err(UpdateError::SizeMismatch {
            expected: 2_000,
            got: 1_500
        })
    );
    assert!(!target.exists());
}

#[tokio::test]
async fn an_address_outside_the_release_hosts_is_never_requested() {
    let body = bytes(100);
    let mut asset = asset_for(&body);
    asset.url = "https://evil.example.com/a.apk".into();
    let folder = scratch("host");
    let transport = FakeTransport::serving(vec![whole(&body, 1)]);
    let result = download(&transport, &asset, &folder.join("a.apk"), |_| {}).await;
    assert!(matches!(result, Err(UpdateError::Untrusted(_))));
    assert!(transport.asked().is_empty());
}

#[tokio::test]
async fn a_redirect_to_an_untrusted_host_is_refused() {
    let body = bytes(100);
    let folder = scratch("redirect");
    let mut served = whole(&body, 1);
    served.url = "https://evil.example.com/a.apk".into();
    let transport = FakeTransport::serving(vec![served]);
    let result = download(&transport, &asset_for(&body), &folder.join("a.apk"), |_| {}).await;
    assert!(matches!(result, Err(UpdateError::Untrusted(_))));
    assert!(!folder.join("a.apk").exists());
}

#[tokio::test]
async fn a_server_error_is_a_network_error() {
    let body = bytes(100);
    let folder = scratch("status");
    let served = Served {
        status: 503,
        url: OK_URL.into(),
        chunks: vec![],
    };
    let transport = FakeTransport::serving(vec![served]);
    let result = download(&transport, &asset_for(&body), &folder.join("a.apk"), |_| {}).await;
    assert!(matches!(result, Err(UpdateError::Network(_))));
}
