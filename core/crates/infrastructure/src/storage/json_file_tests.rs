use std::sync::Arc;

use serde::{Deserialize, Serialize};

use super::json_file::JsonFile;
use super::temp_folder::TempFolder;

#[derive(Debug, Default, PartialEq, Serialize, Deserialize)]
struct Counter {
    value: u32,
    names: Vec<String>,
}

#[tokio::test]
async fn a_missing_file_reads_as_the_default() {
    let folder = TempFolder::new("json-missing");
    let file = JsonFile::new(folder.file("data.json"));
    assert_eq!(file.read::<Counter>().await, Counter::default());
}

#[tokio::test]
async fn updates_are_written_and_read_back_without_leftovers() {
    let folder = TempFolder::new("json-roundtrip");
    let file = JsonFile::new(folder.file("nested").join("data.json"));
    let doubled = file
        .update(|data: &mut Counter| {
            data.value = 21;
            data.names.push("a".into());
            data.value * 2
        })
        .await
        .unwrap();
    assert_eq!(doubled, 42);
    assert_eq!(
        file.read::<Counter>().await,
        Counter {
            value: 21,
            names: vec!["a".into()]
        }
    );
    assert!(!folder.file("nested").join("data.json.tmp").exists());
}

#[tokio::test]
async fn overlapping_updates_never_lose_a_write() {
    let folder = TempFolder::new("json-overlap");
    let file = Arc::new(JsonFile::new(folder.file("data.json")));
    let mut tasks = tokio::task::JoinSet::new();
    for index in 0..25 {
        let file = Arc::clone(&file);
        tasks.spawn(async move {
            file.update(|data: &mut Counter| {
                data.value += 1;
                data.names.push(index.to_string());
            })
            .await
            .unwrap();
        });
    }
    while tasks.join_next().await.is_some() {}
    let data = file.read::<Counter>().await;
    assert_eq!(data.value, 25);
    assert_eq!(data.names.len(), 25);
}

#[tokio::test]
async fn a_corrupt_file_starts_empty_and_is_kept_aside() {
    let folder = TempFolder::new("json-corrupt");
    std::fs::write(folder.file("data.json"), "{not json").unwrap();
    let file = JsonFile::new(folder.file("data.json"));
    assert_eq!(file.read::<Counter>().await, Counter::default());
    assert_eq!(
        std::fs::read_to_string(folder.file("data.json.corrupt")).unwrap(),
        "{not json"
    );
    file.update(|data: &mut Counter| data.value = 3)
        .await
        .unwrap();
    assert_eq!(file.read::<Counter>().await.value, 3);
}

#[tokio::test]
async fn a_failed_write_is_reported_instead_of_ignored() {
    let folder = TempFolder::new("json-failure");
    std::fs::write(folder.file("blocker"), "a file, not a folder").unwrap();
    let file = JsonFile::new(folder.file("blocker").join("data.json"));
    let result = file.update(|data: &mut Counter| data.value = 1).await;
    assert!(result.is_err());
}
