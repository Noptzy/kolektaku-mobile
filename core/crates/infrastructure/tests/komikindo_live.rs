use std::sync::Arc;

use application::ports::SourceProvider;
use domain::error::SourceError;
use domain::source::{ItemId, SourceSearch};
use infrastructure::clock::SystemClock;
use infrastructure::http::ReqwestClient;
use infrastructure::sources::komikindo::KomikindoSource;

fn source() -> KomikindoSource {
    let http = Arc::new(ReqwestClient::standard().unwrap());
    KomikindoSource::new(http, Arc::new(SystemClock), "https://komikindo.ch", 8).unwrap()
}

fn is_expected_downtime(error: &SourceError) -> bool {
    matches!(
        error,
        SourceError::Unavailable(_)
            | SourceError::Network(_)
            | SourceError::NotFound(_)
            | SourceError::ChallengeRequired(_)
    )
}

#[tokio::test]
#[ignore = "live network"]
async fn komikindo_lists_the_newest_chapters_or_reports_a_typed_error() {
    match source().latest(1).await {
        Ok(page) => assert!(page.items.len() >= 10),
        Err(error) => assert!(is_expected_downtime(&error), "{error}"),
    }
}

#[tokio::test]
#[ignore = "live network"]
async fn komikindo_either_works_or_fails_with_a_typed_human_mappable_error() {
    let source = source();
    let search = source.search(SourceSearch::new("chainsaw man")).await;
    let genres = source.genres().await.map(|_| ());
    let detail = source.detail(ItemId::new("chainsaw-man")).await.map(|_| ());
    for error in [search.map(|_| ()).err(), genres.err(), detail.err()]
        .into_iter()
        .flatten()
    {
        assert!(is_expected_downtime(&error), "{error}");
    }
}
