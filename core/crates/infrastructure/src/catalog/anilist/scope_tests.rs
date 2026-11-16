use domain::media::{Discover, MediaFormat, MediaKind, MediaListKind, MediaSummary};
use serde_json::json;

use super::catalog::media_type;
use super::discover::discover_variables;
use super::list_request::list_request;
use super::mapper::visible_summaries;
use super::queries::{discover_query, list_query, search_query};
use super::schema::RawSummary;
use super::search_request::search_variables;

const NOW: u64 = 1_768_478_400;

fn raw(json: &str) -> RawSummary {
    serde_json::from_str(json).unwrap()
}

fn map_summary(raw: RawSummary) -> MediaSummary {
    visible_summaries(vec![raw]).remove(0)
}

fn listed(kind: MediaKind) -> serde_json::Value {
    list_request(kind, MediaListKind::Popular, 1, NOW, media_type(kind)).variables
}

#[test]
fn novels_are_asked_of_the_catalog_as_manga() {
    assert_eq!(media_type(MediaKind::Novel), "MANGA");
    assert_eq!(media_type(MediaKind::Manga), "MANGA");
    assert_eq!(media_type(MediaKind::Anime), "ANIME");
}

#[test]
fn a_manga_entry_in_novel_format_is_a_novel() {
    let summary = map_summary(raw(
        r#"{"id":7,"type":"MANGA","title":{"romaji":"Mushoku Tensei"},"format":"NOVEL","chapters":null}"#,
    ));
    assert_eq!(summary.kind, MediaKind::Novel);
    assert_eq!(summary.format, Some(MediaFormat::Novel));
}

#[test]
fn a_novel_counts_its_chapters_like_a_comic() {
    let summary = map_summary(raw(
        r#"{"id":7,"type":"MANGA","title":{"romaji":"X"},"format":"NOVEL","chapters":120,"episodes":4}"#,
    ));
    assert_eq!(summary.unit_count, Some(120));
}

#[test]
fn comics_in_other_formats_stay_comics() {
    for format in ["MANGA", "ONE_SHOT"] {
        let json =
            format!(r#"{{"id":8,"type":"MANGA","title":{{"romaji":"X"}},"format":"{format}"}}"#);
        assert_eq!(map_summary(raw(&json)).kind, MediaKind::Manga, "{format}");
    }
    let unknown = map_summary(raw(r#"{"id":8,"type":"MANGA","title":{"romaji":"X"}}"#));
    assert_eq!(unknown.kind, MediaKind::Manga);
}

#[test]
fn an_anime_stays_an_anime_whatever_its_format() {
    let summary = map_summary(raw(
        r#"{"id":9,"type":"ANIME","title":{"romaji":"X"},"format":"TV"}"#,
    ));
    assert_eq!(summary.kind, MediaKind::Anime);
}

#[test]
fn comic_lists_leave_novels_out_and_novel_lists_ask_for_only_novels() {
    let manga = listed(MediaKind::Manga);
    assert_eq!(manga["notFormats"], json!(["NOVEL"]));
    assert!(manga.get("formats").is_none());
    let novel = listed(MediaKind::Novel);
    assert_eq!(novel["formats"], json!(["NOVEL"]));
    assert!(novel.get("notFormats").is_none());
    assert_eq!(novel["type"], "MANGA");
}

#[test]
fn anime_lists_carry_no_format_scope() {
    let anime = listed(MediaKind::Anime);
    assert!(anime.get("formats").is_none() && anime.get("notFormats").is_none());
}

#[test]
fn a_novel_list_has_no_country_filter() {
    assert!(listed(MediaKind::Novel).get("country").is_none());
}

#[test]
fn searches_are_scoped_the_same_way() {
    let manga = search_variables(MediaKind::Manga, " frieren ", 2, 20);
    assert_eq!(manga["search"], "frieren");
    assert_eq!(manga["page"], 2);
    assert_eq!(manga["notFormats"], json!(["NOVEL"]));
    let novel = search_variables(MediaKind::Novel, "frieren", 1, 20);
    assert_eq!(novel["formats"], json!(["NOVEL"]));
    assert_eq!(novel["type"], "MANGA");
    let anime = search_variables(MediaKind::Anime, "frieren", 1, 20);
    assert_eq!(anime["country"], "JP");
    assert!(anime.get("formats").is_none() && anime.get("notFormats").is_none());
}

#[test]
fn discovering_is_scoped_the_same_way() {
    let manga = discover_variables(MediaKind::Manga, &Discover::default(), 1, 20, None);
    assert_eq!(manga["notFormats"], json!(["NOVEL"]));
    assert!(manga.get("formats").is_none());
    let novel = discover_variables(MediaKind::Novel, &Discover::default(), 1, 20, None);
    assert_eq!(novel["formats"], json!(["NOVEL"]));
    assert_eq!(novel["type"], "MANGA");
}

#[test]
fn the_novel_scope_wins_over_chosen_formats() {
    let filter = Discover::searching("a").in_formats(vec![MediaFormat::Manga]);
    let novel = discover_variables(MediaKind::Novel, &filter, 1, 20, None);
    assert_eq!(novel["formats"], json!(["NOVEL"]));
    let manga = discover_variables(MediaKind::Manga, &filter, 1, 20, None);
    assert_eq!(manga["formats"], json!(["MANGA"]));
}

#[test]
fn every_query_that_scopes_formats_declares_the_variables() {
    for document in [list_query(false, false), search_query(), discover_query()] {
        assert!(document.contains("$notFormats: [MediaFormat]"));
        assert!(document.contains("format_not_in: $notFormats"));
        assert!(document.contains("$formats: [MediaFormat]"));
        assert!(document.contains("format_in: $formats"));
    }
}
