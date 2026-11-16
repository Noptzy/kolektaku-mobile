use std::sync::Arc;

use application::ports::{BoxFuture, VideoSource};
use domain::error::SourceError;
use domain::stream::{EpisodeServer, StreamPlan, StreamSet};

use super::api::parse_json;
use super::model::RawEpisodeResponse;
use super::payload::parse_stream_payload;
use super::script::stream_script;
use super::servers::{ServerChoice, server_choices};
use super::urls::HianimeUrls;
use crate::sources::support::PageFetcher;

pub struct HianimeVideo {
    urls: HianimeUrls,
    pages: Arc<PageFetcher>,
}

impl HianimeVideo {
    pub fn new(urls: HianimeUrls, pages: Arc<PageFetcher>) -> Self {
        Self { urls, pages }
    }

    async fn choices(&self, episode: &str) -> Result<Vec<ServerChoice>, SourceError> {
        let body = self.pages.fetch_live(&self.urls.episode(episode)?).await?;
        let response: RawEpisodeResponse = parse_json(&body, "episode")?;
        let links = response
            .episode
            .link
            .ok_or_else(|| SourceError::MarkupChanged("episode links were not found".into()))?;
        let choices = server_choices(links);
        if choices.is_empty() {
            return Err(SourceError::Unavailable(
                "this episode has no playable server".into(),
            ));
        }
        Ok(choices)
    }
}

impl VideoSource for HianimeVideo {
    fn servers(&self, episode: String) -> BoxFuture<'_, Result<Vec<EpisodeServer>, SourceError>> {
        Box::pin(async move {
            let choices = self.choices(&episode).await?;
            Ok(choices
                .into_iter()
                .map(|choice| {
                    EpisodeServer::new(choice.id, choice.label)
                        .with_variant(choice.variant)
                        .with_audio(choice.audio)
                })
                .collect())
        })
    }

    fn stream_plan(
        &self,
        episode: String,
        server: String,
    ) -> BoxFuture<'_, Result<StreamPlan, SourceError>> {
        Box::pin(async move {
            let choices = self.choices(&episode).await?;
            let choice = choices
                .into_iter()
                .find(|choice| choice.id == server)
                .ok_or_else(|| SourceError::NotFound(format!("stream server {server}")))?;
            Ok(StreamPlan::NeedsWebView {
                url: choice.url,
                script: stream_script().to_string(),
                allowed_host: choice.host,
            })
        })
    }

    fn parse_stream_payload(&self, payload: &str) -> Result<StreamSet, SourceError> {
        parse_stream_payload(payload)
    }
}
