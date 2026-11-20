mod cached_http;
mod client;
mod pause;
mod rate_limit;
mod request;
mod reqwest_client;
mod response;
mod response_cache;

#[cfg(test)]
mod fake_http;
#[cfg(test)]
mod fake_pause;
#[cfg(test)]
mod local_server;
#[cfg(test)]
mod rate_limit_tests;
#[cfg(test)]
mod reqwest_client_tests;

pub use cached_http::{CachedHttp, TtlPolicy};
pub use client::HttpClient;
pub use pause::{Pause, SystemPause};
pub use rate_limit::{RateLimitSettings, RateLimitedClient};
pub use request::{HttpMethod, HttpRequest};
pub use reqwest_client::ReqwestClient;
pub(crate) use reqwest_client::network_error;
pub use response::HttpResponse;
pub use response_cache::{CacheHit, ResponseCache};

#[cfg(test)]
pub use fake_http::FakeHttp;
#[cfg(test)]
pub use fake_pause::FakePause;
