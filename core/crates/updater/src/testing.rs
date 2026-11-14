use std::collections::VecDeque;
use std::path::PathBuf;
use std::sync::Mutex;

use sha2::{Digest, Sha256};

use crate::error::UpdateError;
use crate::transport::{Body, BoxFuture, Fetched, Transport};

pub const OK_URL: &str =
    "https://github.com/Noptzy/kolektaku-mobile/releases/download/v2.1.0/app-arm64-v8a-release.apk";

pub fn sha_of(bytes: &[u8]) -> String {
    Sha256::digest(bytes)
        .iter()
        .map(|byte| format!("{byte:02x}"))
        .collect()
}

pub fn bytes(count: usize) -> Vec<u8> {
    (0..count).map(|index| (index % 251) as u8).collect()
}

pub fn scratch(name: &str) -> PathBuf {
    let folder = std::env::temp_dir().join(format!("updater-test-{}-{name}", std::process::id()));
    let _ = std::fs::remove_dir_all(&folder);
    std::fs::create_dir_all(&folder).unwrap();
    folder
}

struct Chunks(VecDeque<Result<Vec<u8>, UpdateError>>);

impl Body for Chunks {
    fn next(&mut self) -> BoxFuture<'_, Result<Option<Vec<u8>>, UpdateError>> {
        Box::pin(async move { self.0.pop_front().transpose() })
    }
}

pub struct Served {
    pub status: u16,
    pub url: String,
    pub chunks: Vec<Result<Vec<u8>, UpdateError>>,
}

pub struct FakeTransport {
    pub text: Result<String, UpdateError>,
    served: Mutex<VecDeque<Served>>,
    pub requests: Mutex<Vec<(String, u64)>>,
}

impl FakeTransport {
    pub fn serving(served: Vec<Served>) -> Self {
        Self {
            text: Ok(String::new()),
            served: Mutex::new(served.into()),
            requests: Mutex::new(Vec::new()),
        }
    }

    pub fn with_text(text: &str) -> Self {
        let mut fake = Self::serving(Vec::new());
        fake.text = Ok(text.to_string());
        fake
    }

    pub fn failing(error: UpdateError) -> Self {
        let mut fake = Self::serving(Vec::new());
        fake.text = Err(error);
        fake
    }

    pub fn asked(&self) -> Vec<(String, u64)> {
        self.requests.lock().unwrap().clone()
    }
}

pub fn whole(body: &[u8], pieces: usize) -> Served {
    Served {
        status: 200,
        url: OK_URL.into(),
        chunks: body
            .chunks(body.len().div_ceil(pieces).max(1))
            .map(|piece| Ok(piece.to_vec()))
            .collect(),
    }
}

pub fn from_offset(body: &[u8], from: usize) -> Served {
    Served {
        status: 206,
        url: OK_URL.into(),
        chunks: vec![Ok(body[from..].to_vec())],
    }
}

impl Transport for FakeTransport {
    fn text(&self, _url: &str) -> BoxFuture<'_, Result<String, UpdateError>> {
        let answer = self.text.clone();
        Box::pin(async move { answer })
    }

    fn fetch(&self, url: &str, from: u64) -> BoxFuture<'_, Result<Fetched, UpdateError>> {
        self.requests.lock().unwrap().push((url.to_string(), from));
        let next = self.served.lock().unwrap().pop_front();
        Box::pin(async move {
            let served = next.ok_or_else(|| UpdateError::Network("nothing left".into()))?;
            Ok(Fetched {
                status: served.status,
                url: served.url,
                body: Box::new(Chunks(served.chunks.into())),
            })
        })
    }
}
