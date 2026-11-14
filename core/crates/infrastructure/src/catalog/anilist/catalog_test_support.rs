use std::sync::Arc;

use application::testing::FakeClock;
use serde_json::Value;

use super::AniListCatalog;
use crate::fixtures;
use crate::http::{FakeHttp, HttpResponse};

pub const OCTOBER_2026: u64 = 1_791_201_600;

pub fn catalog_over(http: Arc<FakeHttp>, now_secs: u64) -> AniListCatalog {
    AniListCatalog::new(http, Arc::new(FakeClock::at(now_secs)))
}

pub fn catalog_replying(body: String) -> (AniListCatalog, Arc<FakeHttp>) {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(200, body)));
    (catalog_over(http.clone(), OCTOBER_2026), http)
}

pub fn catalog_with_fixture(name: &str) -> (AniListCatalog, Arc<FakeHttp>) {
    catalog_replying(fixtures::anilist(name))
}

pub fn catalog_failing_with(response: HttpResponse) -> AniListCatalog {
    catalog_over(Arc::new(FakeHttp::always(response)), OCTOBER_2026)
}

pub fn sent(http: &FakeHttp, index: usize) -> Value {
    let request = &http.requests()[index];
    serde_json::from_str(request.body.as_deref().unwrap()).unwrap()
}

pub fn sent_variables(http: &FakeHttp, index: usize) -> Value {
    sent(http, index)["variables"].clone()
}

pub fn sent_query(http: &FakeHttp, index: usize) -> String {
    sent(http, index)["query"].as_str().unwrap().to_string()
}
