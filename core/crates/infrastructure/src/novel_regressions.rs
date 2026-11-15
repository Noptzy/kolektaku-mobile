use std::sync::Arc;

use application::matching::{ListedCandidate, MatchTarget, shortlist_candidates};
use application::ports::SourceProvider;
use application::testing::FakeClock;
use domain::media::{MediaFormat, MediaStatus};
use domain::source::SourceSearch;

use crate::fixtures;
use crate::http::{FakeHttp, HttpRequest, HttpResponse};
use crate::sources::registry::novelphoenix::NovelPhoenixSource;

fn overlord() -> MatchTarget {
    MatchTarget {
        titles: vec!["Overlord".into(), "オーバーロード".into()],
        format: Some(MediaFormat::Novel),
        year: Some(2012),
        unit_count: None,
        status: Some(MediaStatus::Releasing),
    }
}

async fn listed_for_overlord() -> Vec<ListedCandidate> {
    let http = Arc::new(FakeHttp::replying(|_: &HttpRequest| {
        Ok(HttpResponse::new(
            200,
            fixtures::read("search", "novelphoenix-overlord.html"),
        ))
    }));
    let source = NovelPhoenixSource::new(
        http,
        Arc::new(FakeClock::at(0)),
        "https://novelphoenix.com",
        6,
    )
    .unwrap();
    let page = source.search(SourceSearch::new("overlord")).await.unwrap();
    page.items
        .into_iter()
        .map(|item| ListedCandidate {
            key: item.item_id.to_string(),
            title: item.title,
        })
        .collect()
}

#[tokio::test]
async fn a_search_full_of_fan_fiction_shortlists_only_the_novel_itself() {
    let listed = listed_for_overlord().await;
    assert!(listed.len() >= 18, "{} listed", listed.len());
    let shortlist = shortlist_candidates(&overlord(), &listed);
    let titles: Vec<&str> = shortlist
        .iter()
        .map(|candidate| candidate.title.as_str())
        .collect();
    assert!(!titles.is_empty());
    for title in &titles {
        assert!(title.starts_with("Overlord ("), "{title}");
    }
}

#[tokio::test]
async fn no_fan_fiction_title_scores_for_the_novel() {
    let listed = listed_for_overlord().await;
    let target = overlord();
    let accepted = listed
        .iter()
        .filter(|candidate| application::matching::score_title(&target, &candidate.title) > 0.0)
        .count();
    assert_eq!(accepted, 2);
}
