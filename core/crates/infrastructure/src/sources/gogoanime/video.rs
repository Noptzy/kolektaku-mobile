use std::sync::Arc;

use application::ports::{BoxFuture, VideoSource};
use domain::error::SourceError;
use domain::stream::{EpisodeServer, StreamPlan, StreamSet};
use url::Url;

use super::payload::parse_stream_payload;
use super::script::stream_script;
use super::servers::{ServerChoice, embed_of, server_choices};
use super::urls::GogoanimeUrls;
use crate::sources::support::PageFetcher;

pub struct GogoanimeVideo {
    urls: GogoanimeUrls,
    pages: Arc<PageFetcher>,
}

impl GogoanimeVideo {
    pub fn new(urls: GogoanimeUrls, pages: Arc<PageFetcher>) -> Self {
        Self { urls, pages }
    }

    async fn choices(&self, episode: &str) -> Result<Vec<ServerChoice>, SourceError> {
        let body = self.pages.fetch_live(&self.urls.episode(episode)?).await?;
        let choices = server_choices(&body);
        if choices.is_empty() {
            return Err(SourceError::Unavailable(
                "this episode has no playable server".into(),
            ));
        }
        Ok(choices)
    }
}

fn origin_of(address: &str) -> Option<String> {
    let url = Url::parse(address).ok()?;
    Some(format!("{}/", url.origin().ascii_serialization()))
}

impl VideoSource for GogoanimeVideo {
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
            let wrapper = self.pages.fetch_live(&choice.wrapper).await?;
            let (url, host) = embed_of(&wrapper).ok_or_else(|| {
                SourceError::MarkupChanged("the player address was not found".into())
            })?;
            Ok(StreamPlan::NeedsWebView {
                url,
                script: stream_script().to_string(),
                allowed_host: host,
                referer: origin_of(&choice.wrapper),
            })
        })
    }

    fn parse_stream_payload(&self, payload: &str) -> Result<StreamSet, SourceError> {
        parse_stream_payload(payload)
    }
}
