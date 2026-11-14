use domain::error::SourceError;
use domain::media::{EpisodeInfo, MediaDetail};

use super::merge::merge_titles;
use super::parse::parse_episode_titles;
use crate::http::{HttpClient, HttpRequest};

const PAGE_SIZE: u32 = 100;
const MAX_PAGES: u32 = 3;
const BASE: &str = "https://myanimelist.net/anime";

pub fn page_url(mal_id: u64, page: u32) -> String {
    let offset = page * PAGE_SIZE;
    if offset == 0 {
        format!("{BASE}/{mal_id}/x/episode")
    } else {
        format!("{BASE}/{mal_id}/x/episode?offset={offset}")
    }
}

pub fn pages_for(total: Option<u32>) -> u32 {
    total.map_or(1, |count| count.div_ceil(PAGE_SIZE).clamp(1, MAX_PAGES))
}

async fn fetch_page(
    http: &dyn HttpClient,
    mal_id: u64,
    page: u32,
) -> Result<Vec<EpisodeInfo>, SourceError> {
    let response = http.send(HttpRequest::get(page_url(mal_id, page))).await?;
    if !response.is_success() {
        return Err(SourceError::Unavailable(format!(
            "episode titles answered {}",
            response.status
        )));
    }
    Ok(parse_episode_titles(&response.body))
}

pub async fn titled_episodes(http: &dyn HttpClient, detail: &MediaDetail) -> Vec<EpisodeInfo> {
    let Some(mal_id) = detail.mal_id else {
        return detail.episodes.clone();
    };
    let mut titled: Vec<EpisodeInfo> = Vec::new();
    for page in 0..pages_for(detail.summary.unit_count) {
        let Ok(found) = fetch_page(http, mal_id, page).await else {
            break;
        };
        let short = found.len() < PAGE_SIZE as usize;
        titled.extend(found);
        if short {
            break;
        }
    }
    merge_titles(detail.episodes.clone(), titled)
}

#[cfg(test)]
mod tests {
    use std::sync::Arc;

    use domain::media::{MediaId, MediaKind, MediaSummary, MediaTitle};

    use super::*;
    use crate::http::{FakeHttp, HttpResponse};

    fn detail(mal_id: Option<u64>, units: Option<u32>) -> MediaDetail {
        let mut summary = MediaSummary::new(
            MediaId::new(1).unwrap(),
            MediaKind::Anime,
            MediaTitle::new("X"),
        );
        summary.unit_count = units;
        let mut detail = MediaDetail::new(summary);
        detail.mal_id = mal_id;
        detail
    }

    fn page_with(count: u32, first: u32) -> String {
        let rows: String = (first..first + count)
            .map(|number| {
                format!(
                    r#"<tr><td class="episode-number">{number}</td><td class="episode-title"><a><span>Name {number}</span></a></td></tr>"#
                )
            })
            .collect();
        format!(r#"<table class="anime-episode-list">{rows}</table>"#)
    }

    #[test]
    fn the_first_page_has_no_offset_and_later_ones_step_by_a_hundred() {
        assert_eq!(page_url(7, 0), "https://myanimelist.net/anime/7/x/episode");
        assert_eq!(
            page_url(7, 2),
            "https://myanimelist.net/anime/7/x/episode?offset=200"
        );
    }

    #[test]
    fn the_page_count_follows_the_season_and_stays_bounded() {
        assert_eq!(pages_for(None), 1);
        assert_eq!(pages_for(Some(12)), 1);
        assert_eq!(pages_for(Some(100)), 1);
        assert_eq!(pages_for(Some(101)), 2);
        assert_eq!(pages_for(Some(1100)), MAX_PAGES);
        assert_eq!(pages_for(Some(0)), 1);
    }

    #[tokio::test]
    async fn without_a_catalog_id_nothing_is_asked() {
        let http = FakeHttp::always(HttpResponse::new(200, page_with(3, 1)));
        let mut item = detail(None, Some(3));
        item.episodes = vec![EpisodeInfo::new(1.0, "Mine")];
        let merged = titled_episodes(&http, &item).await;
        assert_eq!(merged, item.episodes);
        assert!(http.requests().is_empty());
    }

    #[tokio::test]
    async fn titles_join_the_episodes_the_catalog_already_lists() {
        let http = FakeHttp::always(HttpResponse::new(200, page_with(3, 1)));
        let mut item = detail(Some(59741), Some(3));
        let mut with_picture = EpisodeInfo::new(2.0, "");
        with_picture.thumbnail_url = Some("https://img.test/2.jpg".into());
        item.episodes = vec![with_picture];
        let merged = titled_episodes(&http, &item).await;
        assert_eq!(merged.len(), 3);
        assert_eq!(merged[1].title, "Name 2");
        assert!(merged[1].thumbnail_url.is_some());
        assert_eq!(
            http.requests()[0].url,
            "https://myanimelist.net/anime/59741/x/episode"
        );
    }

    #[tokio::test]
    async fn a_long_series_reads_one_more_page_only_when_the_first_was_full() {
        let http = Arc::new(FakeHttp::scripted(vec![
            Ok(HttpResponse::new(200, page_with(100, 1))),
            Ok(HttpResponse::new(200, page_with(20, 101))),
        ]));
        let merged = titled_episodes(http.as_ref(), &detail(Some(1), Some(500))).await;
        assert_eq!(merged.len(), 120);
        assert_eq!(http.requests().len(), 2);
    }

    #[tokio::test]
    async fn a_short_first_page_stops_the_reading() {
        let http = FakeHttp::always(HttpResponse::new(200, page_with(12, 1)));
        titled_episodes(&http, &detail(Some(1), Some(500))).await;
        assert_eq!(http.requests().len(), 1);
    }

    #[tokio::test]
    async fn a_failing_page_leaves_the_catalog_episodes_untouched() {
        let http = FakeHttp::always(HttpResponse::new(503, "busy"));
        let mut item = detail(Some(1), Some(12));
        item.episodes = vec![EpisodeInfo::new(1.0, "Mine")];
        assert_eq!(titled_episodes(&http, &item).await, item.episodes);
    }

    #[tokio::test]
    async fn a_network_failure_is_not_an_error_for_the_caller() {
        let http = FakeHttp::scripted(vec![Err(SourceError::Network("down".into()))]);
        assert!(
            titled_episodes(&http, &detail(Some(1), Some(12)))
                .await
                .is_empty()
        );
    }
}
