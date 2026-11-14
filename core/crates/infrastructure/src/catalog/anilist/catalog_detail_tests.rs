use application::ports::MetadataCatalog;
use domain::error::SourceError;
use domain::media::{CharacterRole, MediaFormat, MediaId, MediaKind, RelationType, TrailerSite};
use serde_json::{Value, json};

use super::catalog_test_support::{catalog_replying, catalog_with_fixture, sent_variables};
use crate::fixtures;

const DEMON_SLAYER: u64 = 101_922;
const CHAINSAW_OR_MANGA: u64 = 87_216;

fn id(value: u64) -> MediaId {
    MediaId::new(value).unwrap()
}

#[tokio::test]
async fn maps_an_anime_detail_with_cast_trailer_relations_and_recommendations() {
    let (catalog, http) = catalog_with_fixture("detail-anime.json");
    let detail = catalog
        .detail(MediaKind::Anime, id(DEMON_SLAYER))
        .await
        .unwrap();
    let media = &detail.summary;

    assert_eq!(
        sent_variables(&http, 0),
        json!({"id": DEMON_SLAYER, "type": "ANIME"})
    );
    assert_eq!(media.kind, MediaKind::Anime);
    assert_eq!(media.title.romaji, "Kimetsu no Yaiba");
    assert_eq!(
        media.title.english.as_deref(),
        Some("Demon Slayer: Kimetsu no Yaiba")
    );
    assert_eq!(media.format, Some(MediaFormat::Tv));
    assert_eq!(media.year, Some(2019));
    assert_eq!(media.unit_count, Some(26));
    assert_eq!(detail.duration_minutes, Some(24));
    assert!((media.score.unwrap() - 8.2).abs() < 0.11);
    assert!(
        detail
            .studios
            .iter()
            .any(|studio| studio.name == "ufotable")
    );
    assert!(media.cover_url.as_deref().unwrap().starts_with("https:"));
    assert!(detail.banner_url.as_deref().unwrap().starts_with("https:"));
    let trailer = detail.trailer.as_ref().unwrap();
    assert_eq!(
        (trailer.site, trailer.video_id.as_str()),
        (TrailerSite::Youtube, "6vMuWuWlW4I")
    );
    assert!(!detail.description.contains("<p>") && !detail.description.contains("</p>"));

    let tanjiro = detail
        .characters
        .iter()
        .find(|character| character.name.contains("Tanjirou"))
        .unwrap();
    assert_eq!(tanjiro.role, CharacterRole::Main);
    assert!(
        tanjiro
            .voice_actors
            .iter()
            .any(|actor| actor.name == "Natsuki Hanae")
    );
    assert!(!detail.staff.is_empty());
    assert!(!detail.recommendations.is_empty());
    assert!(
        detail
            .relations
            .iter()
            .any(|relation| relation.relation_type == RelationType::Sequel)
    );
}

#[tokio::test]
async fn reads_the_manga_adaptation_relation_on_an_anime() {
    let (catalog, _) = catalog_with_fixture("detail-anime.json");
    let detail = catalog
        .detail(MediaKind::Anime, id(DEMON_SLAYER))
        .await
        .unwrap();
    let manga: Vec<_> = detail
        .relations
        .iter()
        .filter(|relation| {
            relation.media.kind == MediaKind::Manga
                && matches!(
                    relation.relation_type,
                    RelationType::Source | RelationType::Adaptation
                )
        })
        .collect();
    assert!(!manga.is_empty());
    assert_eq!(manga[0].media.format, Some(MediaFormat::Manga));
}

#[tokio::test]
async fn maps_a_manga_detail_with_its_anime_adaptation() {
    let (catalog, http) = catalog_with_fixture("detail-manga.json");
    let detail = catalog
        .detail(MediaKind::Manga, id(CHAINSAW_OR_MANGA))
        .await
        .unwrap();
    assert_eq!(sent_variables(&http, 0)["type"], "MANGA");
    assert_eq!(detail.summary.kind, MediaKind::Manga);
    assert!(detail.relations.iter().any(|relation| {
        relation.relation_type == RelationType::Adaptation
            && relation.media.kind == MediaKind::Anime
    }));
}

#[tokio::test]
async fn an_adult_detail_is_reported_as_not_found() {
    let mut body: Value = serde_json::from_str(&fixtures::anilist("detail-anime.json")).unwrap();
    body["data"]["Media"]["isAdult"] = json!(true);
    let (catalog, _) = catalog_replying(body.to_string());
    let error = catalog
        .detail(MediaKind::Anime, id(DEMON_SLAYER))
        .await
        .unwrap_err();
    assert_eq!(error, SourceError::NotFound(DEMON_SLAYER.to_string()));
}

#[tokio::test]
async fn adult_relations_and_recommendations_never_reach_the_detail() {
    let mut body: Value = serde_json::from_str(&fixtures::anilist("detail-anime.json")).unwrap();
    let media = &mut body["data"]["Media"];
    let relations = media["relations"]["edges"].as_array().unwrap().len();
    let recommendations = media["recommendations"]["nodes"].as_array().unwrap().len();
    media["relations"]["edges"][0]["node"]["isAdult"] = json!(true);
    media["recommendations"]["nodes"][0]["mediaRecommendation"]["isAdult"] = json!(true);
    let (catalog, _) = catalog_replying(body.to_string());
    let detail = catalog
        .detail(MediaKind::Anime, id(DEMON_SLAYER))
        .await
        .unwrap();
    assert_eq!(detail.relations.len(), relations - 1);
    assert_eq!(detail.recommendations.len(), recommendations - 1);
}

#[tokio::test]
async fn a_studio_keeps_its_catalog_id_when_the_reply_has_one() {
    let body = fixtures::anilist("detail-anime.json").replace(
        "\"name\": \"ufotable\"",
        "\"id\": 43, \"name\": \"ufotable\"",
    );
    let (catalog, _http) = catalog_replying(body);
    let detail = catalog
        .detail(MediaKind::Anime, id(DEMON_SLAYER))
        .await
        .unwrap();
    let studio = detail
        .studios
        .iter()
        .find(|studio| studio.name == "ufotable")
        .unwrap();
    assert_eq!(studio.id, Some(43));
}

#[tokio::test]
async fn a_studio_without_an_id_is_still_listed_by_name() {
    let (catalog, _http) = catalog_with_fixture("detail-anime.json");
    let detail = catalog
        .detail(MediaKind::Anime, id(DEMON_SLAYER))
        .await
        .unwrap();
    assert!(detail.studios.iter().all(|studio| studio.id.is_none()));
    assert!(!detail.studios.is_empty());
}

#[test]
fn the_detail_query_asks_for_the_studio_id() {
    assert!(super::queries::detail_query().contains("nodes { id name }"));
}
