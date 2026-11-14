use super::service_support::Folder;
use super::update::{apk_name, download_update};
use super::update_support::{Scripted, offer_for};
use crate::dto::update::UpdateOfferDto;
use crate::error::BridgeErrorKind;

#[tokio::test]
async fn the_download_reports_whole_percents_and_ends_with_the_path() {
    let payload: Vec<u8> = (0..4_000).map(|i| (i % 200) as u8).collect();
    let transport = Scripted::new(String::new(), payload.clone(), 40);
    let folder = Folder::new();
    let mut events = Vec::new();
    let path = download_update(&transport, &offer_for(&payload), &folder.0, |event| {
        events.push(event)
    })
    .await
    .unwrap();
    assert!(path.ends_with("kolektaku-2.1.0-arm64-v8a.apk"));
    assert_eq!(std::fs::read(&path).unwrap(), payload);
    let last = events.last().unwrap();
    assert_eq!(last.path.as_deref(), Some(path.as_str()));
    assert_eq!((last.received, last.total), (4_000, 4_000));
    assert!(
        events[..events.len() - 1]
            .iter()
            .all(|event| event.path.is_none())
    );
    let percents: Vec<u64> = events.iter().map(|e| e.received * 100 / e.total).collect();
    assert!(percents.windows(2).all(|pair| pair[0] <= pair[1]));
    assert!(events.len() <= 102);
}

#[tokio::test]
async fn a_tampered_download_is_refused_with_an_unavailable_error() {
    let payload = vec![5u8; 500];
    let mut served = payload.clone();
    served[10] = 6;
    let transport = Scripted::new(String::new(), served, 2);
    let folder = Folder::new();
    let error = download_update(&transport, &offer_for(&payload), &folder.0, |_| {})
        .await
        .unwrap_err();
    assert_eq!(error.kind, BridgeErrorKind::Unavailable);
    assert!(!folder.0.join(apk_name(&offer_for(&payload))).exists());
}

#[tokio::test]
async fn an_offer_without_a_size_is_refused_before_any_request() {
    let transport = Scripted::new(String::new(), vec![1], 1);
    let folder = Folder::new();
    let offer = UpdateOfferDto {
        size: 0,
        ..offer_for(&[1])
    };
    let error = download_update(&transport, &offer, &folder.0, |_| {})
        .await
        .unwrap_err();
    assert_eq!(error.kind, BridgeErrorKind::Unavailable);
    assert!(transport.asked.lock().unwrap().is_empty());
}

#[tokio::test]
async fn older_downloads_are_cleared_but_other_files_stay() {
    let payload = vec![3u8; 300];
    let transport = Scripted::new(String::new(), payload.clone(), 3);
    let folder = Folder::new();
    std::fs::write(folder.0.join("kolektaku-1.0.0-arm64-v8a.apk"), b"old").unwrap();
    std::fs::write(folder.0.join("kolektaku-1.5.0-arm64-v8a.apk.part"), b"half").unwrap();
    std::fs::write(folder.0.join("notes.txt"), b"keep").unwrap();
    download_update(&transport, &offer_for(&payload), &folder.0, |_| {})
        .await
        .unwrap();
    assert!(!folder.0.join("kolektaku-1.0.0-arm64-v8a.apk").exists());
    assert!(!folder.0.join("kolektaku-1.5.0-arm64-v8a.apk.part").exists());
    assert!(folder.0.join("notes.txt").exists());
}

#[tokio::test]
async fn a_partial_file_of_the_same_update_is_kept_to_resume() {
    let payload = vec![9u8; 1_000];
    let transport = Scripted::new(String::new(), payload.clone(), 1);
    let folder = Folder::new();
    std::fs::write(
        folder.0.join("kolektaku-2.1.0-arm64-v8a.apk.part"),
        &payload[..400],
    )
    .unwrap();
    download_update(&transport, &offer_for(&payload), &folder.0, |_| {})
        .await
        .unwrap();
    assert_eq!(transport.asked.lock().unwrap().as_slice(), &[400]);
}

#[test]
fn the_file_name_cannot_escape_the_folder() {
    let offer = UpdateOfferDto {
        version: "../../x".into(),
        abi: "a/b\\c".into(),
        ..offer_for(&[1])
    };
    let name = apk_name(&offer);
    assert!(!name.contains('/') && !name.contains('\\'));
    assert!(name.starts_with("kolektaku-") && name.ends_with(".apk"));
}
