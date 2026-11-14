use std::collections::HashMap;

use domain::error::SourceError;
use domain::stream::{EpisodeServer, StreamKind, StreamPlan, StreamSet, StreamSource};

use super::CallRecorder;
use crate::ports::{BoxFuture, VideoSource};

#[derive(Default)]
pub struct FakeVideo {
    servers: HashMap<String, Vec<EpisodeServer>>,
    plans: HashMap<(String, String), StreamPlan>,
    recorder: CallRecorder,
}

impl FakeVideo {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_servers(mut self, episode: &str, servers: Vec<EpisodeServer>) -> Self {
        self.servers.insert(episode.to_string(), servers);
        self
    }

    pub fn with_plan(mut self, episode: &str, server: &str, plan: StreamPlan) -> Self {
        self.plans
            .insert((episode.to_string(), server.to_string()), plan);
        self
    }

    pub fn set_failure(&self, error: Option<SourceError>) {
        self.recorder.set_failure(error);
    }

    pub fn calls(&self) -> Vec<String> {
        self.recorder.calls()
    }

    fn enter(&self, call: String) -> Result<(), SourceError> {
        self.recorder.enter(call)
    }
}

impl VideoSource for FakeVideo {
    fn servers(&self, episode: String) -> BoxFuture<'_, Result<Vec<EpisodeServer>, SourceError>> {
        Box::pin(async move {
            self.enter(format!("servers {episode}"))?;
            self.servers
                .get(&episode)
                .cloned()
                .ok_or(SourceError::NotFound(episode))
        })
    }

    fn stream_plan(
        &self,
        episode: String,
        server: String,
    ) -> BoxFuture<'_, Result<StreamPlan, SourceError>> {
        Box::pin(async move {
            self.enter(format!("plan {episode} {server}"))?;
            self.plans
                .get(&(episode.clone(), server))
                .cloned()
                .ok_or(SourceError::NotFound(episode))
        })
    }

    fn parse_stream_payload(&self, payload: &str) -> Result<StreamSet, SourceError> {
        let sources: Vec<StreamSource> = payload
            .split(';')
            .filter_map(|entry| entry.split_once('@'))
            .filter_map(|(url, quality)| Some((url, quality.parse::<u32>().ok()?)))
            .map(|(url, quality)| StreamSource {
                url: url.to_string(),
                kind: StreamKind::Mp4,
                quality,
                label: format!("{quality}p"),
                is_default: false,
            })
            .collect();
        StreamSet::from_sources(sources, None)
            .ok_or_else(|| SourceError::MarkupChanged("no playable sources".into()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn servers_and_plans_are_looked_up_by_episode() {
        let plan = StreamPlan::Direct {
            sources: Vec::new(),
            headers: Vec::new(),
        };
        let video = FakeVideo::new()
            .with_servers("ep1", vec![EpisodeServer::new("s1", "Server 1")])
            .with_plan("ep1", "s1", plan.clone());
        assert_eq!(video.servers("ep1".into()).await.unwrap().len(), 1);
        assert_eq!(
            video.stream_plan("ep1".into(), "s1".into()).await.unwrap(),
            plan
        );
        assert!(matches!(
            video.servers("ep9".into()).await,
            Err(SourceError::NotFound(_))
        ));
    }

    #[tokio::test]
    async fn failure_is_returned_and_calls_are_recorded() {
        let video = FakeVideo::new();
        video.set_failure(Some(SourceError::Network("down".into())));
        assert!(video.servers("ep1".into()).await.is_err());
        assert_eq!(video.calls(), vec!["servers ep1".to_string()]);
    }

    #[test]
    fn payload_parses_url_at_quality_entries_best_first() {
        let video = FakeVideo::new();
        let set = video
            .parse_stream_payload("https://a/360.mp4@360;https://a/720.mp4@720")
            .unwrap();
        assert_eq!(set.default_source().quality, 720);
    }

    #[test]
    fn empty_payload_means_the_markup_changed() {
        let video = FakeVideo::new();
        assert!(matches!(
            video.parse_stream_payload(""),
            Err(SourceError::MarkupChanged(_))
        ));
    }
}
