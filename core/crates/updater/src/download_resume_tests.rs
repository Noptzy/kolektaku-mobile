use crate::download::download;
use crate::download_tests::asset_for;
use crate::error::UpdateError;
use crate::testing::{FakeTransport, OK_URL, Served, bytes, from_offset, scratch, whole};

#[tokio::test]
async fn a_partial_file_is_continued_from_where_it_stopped() {
    let body = bytes(10_000);
    let folder = scratch("resume");
    let target = folder.join("update.apk");
    std::fs::write(folder.join("update.apk.part"), &body[..4_000]).unwrap();
    let transport = FakeTransport::serving(vec![from_offset(&body, 4_000)]);
    download(&transport, &asset_for(&body), &target, |_| {})
        .await
        .unwrap();
    assert_eq!(std::fs::read(&target).unwrap(), body);
    assert_eq!(transport.asked(), vec![(OK_URL.to_string(), 4_000)]);
}

#[tokio::test]
async fn progress_starts_from_what_was_already_there() {
    let body = bytes(10_000);
    let folder = scratch("resume-progress");
    std::fs::write(folder.join("update.apk.part"), &body[..6_000]).unwrap();
    let transport = FakeTransport::serving(vec![from_offset(&body, 6_000)]);
    let mut first = None;
    download(
        &transport,
        &asset_for(&body),
        &folder.join("update.apk"),
        |step| {
            first.get_or_insert(step.received);
        },
    )
    .await
    .unwrap();
    assert_eq!(first, Some(10_000));
}

#[tokio::test]
async fn a_server_that_ignores_the_range_restarts_the_file() {
    let body = bytes(5_000);
    let folder = scratch("ignored-range");
    std::fs::write(folder.join("update.apk.part"), &body[..2_000]).unwrap();
    let transport = FakeTransport::serving(vec![whole(&body, 2)]);
    download(
        &transport,
        &asset_for(&body),
        &folder.join("update.apk"),
        |_| {},
    )
    .await
    .unwrap();
    assert_eq!(std::fs::read(folder.join("update.apk")).unwrap(), body);
}

#[tokio::test]
async fn a_range_the_server_refuses_restarts_from_the_beginning() {
    let body = bytes(5_000);
    let folder = scratch("range-416");
    std::fs::write(folder.join("update.apk.part"), &body[..2_000]).unwrap();
    let refused = Served {
        status: 416,
        url: OK_URL.into(),
        chunks: vec![],
    };
    let transport = FakeTransport::serving(vec![refused, whole(&body, 1)]);
    download(
        &transport,
        &asset_for(&body),
        &folder.join("update.apk"),
        |_| {},
    )
    .await
    .unwrap();
    assert_eq!(
        transport.asked(),
        vec![(OK_URL.to_string(), 2_000), (OK_URL.to_string(), 0)]
    );
    assert_eq!(std::fs::read(folder.join("update.apk")).unwrap(), body);
}

#[tokio::test]
async fn a_partial_file_that_is_too_big_is_thrown_away() {
    let body = bytes(1_000);
    let folder = scratch("too-big");
    std::fs::write(folder.join("update.apk.part"), bytes(5_000)).unwrap();
    let transport = FakeTransport::serving(vec![whole(&body, 1)]);
    download(
        &transport,
        &asset_for(&body),
        &folder.join("update.apk"),
        |_| {},
    )
    .await
    .unwrap();
    assert_eq!(transport.asked(), vec![(OK_URL.to_string(), 0)]);
}

#[tokio::test]
async fn a_complete_partial_file_is_verified_without_any_request() {
    let body = bytes(3_000);
    let folder = scratch("complete");
    std::fs::write(folder.join("update.apk.part"), &body).unwrap();
    let transport = FakeTransport::serving(Vec::new());
    download(
        &transport,
        &asset_for(&body),
        &folder.join("update.apk"),
        |_| {},
    )
    .await
    .unwrap();
    assert!(transport.asked().is_empty());
    assert_eq!(std::fs::read(folder.join("update.apk")).unwrap(), body);
}

#[tokio::test]
async fn a_corrupt_partial_file_is_refused_and_removed() {
    let body = bytes(3_000);
    let folder = scratch("corrupt");
    std::fs::write(
        folder.join("update.apk.part"),
        bytes(3_000).iter().map(|b| b ^ 1).collect::<Vec<u8>>(),
    )
    .unwrap();
    let transport = FakeTransport::serving(Vec::new());
    let result = download(
        &transport,
        &asset_for(&body),
        &folder.join("update.apk"),
        |_| {},
    )
    .await;
    assert_eq!(result, Err(UpdateError::HashMismatch));
    assert!(!folder.join("update.apk.part").exists());
}

#[tokio::test]
async fn losing_the_connection_keeps_what_arrived_for_the_next_try() {
    let body = bytes(6_000);
    let folder = scratch("dropped");
    let served = Served {
        status: 200,
        url: OK_URL.into(),
        chunks: vec![
            Ok(body[..2_500].to_vec()),
            Err(UpdateError::Network("reset".into())),
        ],
    };
    let transport = FakeTransport::serving(vec![served]);
    let result = download(
        &transport,
        &asset_for(&body),
        &folder.join("update.apk"),
        |_| {},
    )
    .await;
    assert_eq!(result, Err(UpdateError::Network("reset".into())));
    assert_eq!(
        std::fs::metadata(folder.join("update.apk.part"))
            .unwrap()
            .len(),
        2_500
    );
    assert!(!folder.join("update.apk").exists());
    let again = FakeTransport::serving(vec![from_offset(&body, 2_500)]);
    download(
        &again,
        &asset_for(&body),
        &folder.join("update.apk"),
        |_| {},
    )
    .await
    .unwrap();
    assert_eq!(std::fs::read(folder.join("update.apk")).unwrap(), body);
}

#[tokio::test]
async fn an_old_download_is_replaced_by_the_new_one() {
    let body = bytes(1_000);
    let folder = scratch("replace");
    std::fs::write(folder.join("update.apk"), b"old build").unwrap();
    let transport = FakeTransport::serving(vec![whole(&body, 1)]);
    download(
        &transport,
        &asset_for(&body),
        &folder.join("update.apk"),
        |_| {},
    )
    .await
    .unwrap();
    assert_eq!(std::fs::read(folder.join("update.apk")).unwrap(), body);
}
