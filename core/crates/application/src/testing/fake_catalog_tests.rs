use domain::error::SourceError;
use domain::media::{MediaDetail, MediaId, MediaKind, MediaSummary};

use super::FakeCatalog;
use crate::ports::MetadataCatalog;
use domain::media::MediaTitle;

fn summary(id: u64, title: &str) -> MediaSummary {
    MediaSummary::new(
        MediaId::new(id).unwrap(),
        MediaKind::Anime,
        MediaTitle::new(title),
    )
}

#[tokio::test]
async fn detail_returns_the_registered_title_or_not_found() {
    let catalog = FakeCatalog::new().with_detail(MediaDetail::new(summary(1, "A")));
    assert!(
        catalog
            .detail(MediaKind::Anime, MediaId::new(1).unwrap())
            .await
            .is_ok()
    );
    let missing = catalog
        .detail(MediaKind::Anime, MediaId::new(2).unwrap())
        .await;
    assert!(matches!(missing, Err(SourceError::NotFound(_))));
}

#[tokio::test]
async fn match_titles_keeps_one_candidate_list_per_title() {
    let catalog = FakeCatalog::new().with_candidates(MediaKind::Anime, "A", vec![summary(1, "A")]);
    let titles = vec!["A".to_string(), "B".to_string()];
    let result = catalog
        .match_titles(MediaKind::Anime, &titles)
        .await
        .unwrap();
    assert_eq!(result.len(), 2);
    assert_eq!(result[0].len(), 1);
    assert!(result[1].is_empty());
}

#[tokio::test]
async fn failure_applies_to_every_call_and_calls_are_recorded() {
    let catalog = FakeCatalog::new().failing_with(SourceError::RateLimited {
        retry_after_secs: None,
    });
    let result = catalog.search(MediaKind::Anime, "x", 1).await;
    assert!(matches!(result, Err(SourceError::RateLimited { .. })));
    assert_eq!(catalog.calls(), vec!["search anime x".to_string()]);
}

#[tokio::test]
async fn a_registered_profile_is_returned_and_an_unknown_one_is_not_found() {
    use domain::media::{Profile, ProfileKind};

    let catalog =
        FakeCatalog::new().with_profile(ProfileKind::Character, Profile::new(3, "Nezuko"));
    let found = catalog.profile(ProfileKind::Character, 3).await.unwrap();
    assert_eq!(found.name, "Nezuko");
    let other_kind = catalog.profile(ProfileKind::Staff, 3).await;
    assert!(matches!(other_kind, Err(SourceError::NotFound(_))));
    assert_eq!(
        catalog.calls(),
        vec![
            "profile Character 3".to_string(),
            "profile Staff 3".to_string()
        ]
    );
}
