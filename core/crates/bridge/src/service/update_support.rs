use std::collections::VecDeque;
use std::sync::Mutex;

use sha2::{Digest, Sha256};
use updater::{Body, BoxFuture, Fetched, Transport, UpdateError};

use crate::dto::update::UpdateOfferDto;

pub const URL: &str = "https://github.com/Noptzy/kolektaku-mobile/releases/download/v2.1.0/a.apk";

pub fn sha_of(bytes: &[u8]) -> String {
    Sha256::digest(bytes)
        .iter()
        .map(|byte| format!("{byte:02x}"))
        .collect()
}

struct Chunks(VecDeque<Vec<u8>>);

impl Body for Chunks {
    fn next(&mut self) -> BoxFuture<'_, Result<Option<Vec<u8>>, UpdateError>> {
        Box::pin(async move { Ok(self.0.pop_front()) })
    }
}

pub struct Scripted {
    manifest: String,
    payload: Vec<u8>,
    pieces: usize,
    pub asked: Mutex<Vec<u64>>,
}

impl Scripted {
    pub fn new(manifest: String, payload: Vec<u8>, pieces: usize) -> Self {
        Self {
            manifest,
            payload,
            pieces,
            asked: Mutex::new(Vec::new()),
        }
    }
}

impl Transport for Scripted {
    fn text(&self, _url: &str) -> BoxFuture<'_, Result<String, UpdateError>> {
        let text = self.manifest.clone();
        Box::pin(async move { Ok(text) })
    }

    fn fetch(&self, _url: &str, from: u64) -> BoxFuture<'_, Result<Fetched, UpdateError>> {
        self.asked.lock().unwrap().push(from);
        let size = self.payload.len().div_ceil(self.pieces).max(1);
        let chunks: VecDeque<Vec<u8>> = self.payload.chunks(size).map(<[u8]>::to_vec).collect();
        Box::pin(async move {
            Ok(Fetched {
                status: 200,
                url: URL.into(),
                body: Box::new(Chunks(chunks)),
            })
        })
    }
}

pub fn manifest(version: &str, minimum: &str, payload: &[u8]) -> String {
    format!(
        r#"{{"version":"{version}","minSupported":"{minimum}","notes":"catatan","assets":{{"arm64-v8a":{{"url":"{URL}","size":{},"sha256":"{}"}}}}}}"#,
        payload.len(),
        sha_of(payload)
    )
}

pub fn arm() -> Vec<String> {
    vec!["arm64-v8a".to_string()]
}

pub fn offer_for(payload: &[u8]) -> UpdateOfferDto {
    UpdateOfferDto {
        version: "2.1.0".into(),
        notes: String::new(),
        abi: "arm64-v8a".into(),
        url: URL.into(),
        size: payload.len() as u64,
        sha256: sha_of(payload),
        required: false,
    }
}
