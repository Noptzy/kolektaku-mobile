use std::sync::Arc;

use application::ports::SourceProvider;
use application::testing::FakeClock;

use super::registry::{Registration, SourceEnv};
use crate::http::{FakeHttp, HttpClient, HttpRequest, HttpResponse};

pub struct ContractSite {
    pub route: fn(&str) -> Option<String>,
    pub search_query: &'static str,
    pub item_id: &'static str,
    pub min_units: usize,
}

pub fn source_over(
    registration: &Registration,
    http: Arc<dyn HttpClient>,
) -> Arc<dyn SourceProvider> {
    let env = SourceEnv {
        http,
        clock: Arc::new(FakeClock::at(0)),
    };
    (registration.build)(&env, &registration.defaults.settings())
        .unwrap_or_else(|error| panic!("{} did not build: {error}", registration.defaults.id))
}

pub fn serving(site: &ContractSite) -> Arc<FakeHttp> {
    let route = site.route;
    Arc::new(FakeHttp::replying(move |request: &HttpRequest| {
        Ok(match route(&request.url) {
            Some(body) => HttpResponse::new(200, body),
            None => HttpResponse::new(404, ""),
        })
    }))
}

pub fn always(status: u16, body: &str) -> Arc<FakeHttp> {
    Arc::new(FakeHttp::always(HttpResponse::new(status, body)))
}

pub fn each_site() -> impl Iterator<Item = (&'static Registration, ContractSite)> {
    super::registry::REGISTRATIONS
        .iter()
        .map(|registration| (*registration, (registration.contract)()))
}
