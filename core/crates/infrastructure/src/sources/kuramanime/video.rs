use std::sync::Arc;

use application::ports::{BoxFuture, VideoSource};
use domain::error::SourceError;
use domain::stream::{EpisodeServer, StreamPlan, StreamSet};

use super::payload::parse_stream_payload;
use super::script::{is_valid_server_id, stream_script};
use super::servers::parse_episode_servers;
use super::urls::KuramanimeUrls;
use crate::sources::support::PageFetcher;

pub struct KuramanimeVideo {
    urls: KuramanimeUrls,
    pages: Arc<PageFetcher>,
}

impl KuramanimeVideo {
    pub fn new(urls: KuramanimeUrls, pages: Arc<PageFetcher>) -> Self {
        Self { urls, pages }
    }
}

impl VideoSource for KuramanimeVideo {
    fn servers(&self, episode: String) -> BoxFuture<'_, Result<Vec<EpisodeServer>, SourceError>> {
        Box::pin(async move {
            let url = self.urls.episode(&episode)?;
            parse_episode_servers(&self.pages.fetch_live(&url).await?)
        })
    }

    fn stream_plan(
        &self,
        episode: String,
        server: String,
    ) -> BoxFuture<'_, Result<StreamPlan, SourceError>> {
        Box::pin(async move {
            if !is_valid_server_id(&server) {
                return Err(SourceError::NotFound(format!("stream server {server}")));
            }
            Ok(StreamPlan::NeedsWebView {
                url: self.urls.episode(&episode)?,
                script: stream_script(&server),
                allowed_host: self.urls.host(),
                referer: None,
            })
        })
    }

    fn parse_stream_payload(&self, payload: &str) -> Result<StreamSet, SourceError> {
        parse_stream_payload(payload)
    }
}

#[cfg(test)]
mod tests {
    use application::testing::FakeClock;

    use super::*;
    use crate::fixtures;
    use crate::http::{FakeHttp, HttpResponse};

    fn video(page: &str) -> (KuramanimeVideo, Arc<FakeHttp>) {
        let http = Arc::new(FakeHttp::always(HttpResponse::new(200, page)));
        let pages = Arc::new(PageFetcher::new(http.clone(), Arc::new(FakeClock::at(0))));
        let urls = KuramanimeUrls::new("https://v20.kuramanime.example").unwrap();
        (KuramanimeVideo::new(urls, pages), http)
    }

    #[tokio::test]
    async fn lists_the_servers_of_an_episode_page() {
        let (video, http) = video(&fixtures::kuramanime("episode.html"));
        let servers = video
            .servers("50/one-piece/episode/3".into())
            .await
            .unwrap();
        assert_eq!(servers[0].id, "kuramadrive");
        assert_eq!(
            http.requests()[0].url,
            "https://v20.kuramanime.example/anime/50/one-piece/episode/3"
        );
    }

    #[tokio::test]
    async fn the_plan_needs_a_web_view_pinned_to_the_site_host() {
        let (video, http) = video("");
        let plan = video
            .stream_plan("50/one-piece/episode/3".into(), "kuramadrive".into())
            .await
            .unwrap();
        let StreamPlan::NeedsWebView {
            url,
            script,
            allowed_host,
            ..
        } = plan
        else {
            panic!("expected a web view plan");
        };
        assert_eq!(
            url,
            "https://v20.kuramanime.example/anime/50/one-piece/episode/3"
        );
        assert_eq!(allowed_host, "v20.kuramanime.example");
        assert!(script.contains("\"kuramadrive\""));
        assert!(http.requests().is_empty());
    }

    #[tokio::test]
    async fn bad_episode_ids_and_server_ids_are_refused_before_any_request() {
        let (video, http) = video("");
        let bad_episode = video.stream_plan("../admin".into(), "mega".into()).await;
        assert!(matches!(bad_episode, Err(SourceError::NotFound(_))));
        let bad_server = video
            .stream_plan("50/one-piece/episode/3".into(), "x\";alert(1)".into())
            .await;
        assert!(matches!(bad_server, Err(SourceError::NotFound(_))));
        assert!(matches!(
            video.servers("50/one-piece".into()).await,
            Err(SourceError::NotFound(_))
        ));
        assert!(http.requests().is_empty());
    }

    #[test]
    fn the_payload_is_parsed_into_a_stream_set() {
        let (video, _) = video("");
        let set = video
            .parse_stream_payload(&fixtures::kuramanime("stream-payload.json"))
            .unwrap();
        assert_eq!(set.default_source().quality, 720);
    }
}
