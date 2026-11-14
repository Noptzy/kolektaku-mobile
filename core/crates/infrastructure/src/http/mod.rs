mod client;
mod pause;
mod rate_limit;
mod request;
mod reqwest_client;
mod response;

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

pub use client::HttpClient;
pub use pause::{Pause, SystemPause};
pub use rate_limit::{RateLimitSettings, RateLimitedClient};
pub use request::{HttpMethod, HttpRequest};
pub use reqwest_client::ReqwestClient;
pub use response::HttpResponse;

#[cfg(test)]
pub use fake_http::FakeHttp;
#[cfg(test)]
pub use fake_pause::FakePause;
