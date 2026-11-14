use std::collections::HashMap;

use domain::error::SourceError;
use domain::media::MediaKind;
use serde_json::json;

use super::catalog::{media_type, parse};
use super::graphql::GraphQl;
use super::queries::genre_covers_query;
use super::schema::RawCoverPage;

const COVER_CHUNK: usize = 24;

const ALIASES: [(&str, &str); 29] = [
    ("Anthropomorphic", "Anthropomorphism"),
    ("Boys Love", "Boys' Love"),
    ("CGDCT", "Cute Girls Doing Cute Things"),
    ("Childcare", "Parenthood"),
    ("Combat Sports", "Boxing"),
    ("Gag Humor", "Slapstick"),
    ("Girls Love", "Yuri"),
    ("Gourmet", "Food"),
    ("Harem", "Female Harem"),
    ("High Stakes Game", "Gambling"),
    ("Idols (Female)", "Idol"),
    ("Love Polygon", "Love Triangle"),
    ("Magical Sex Shift", "Gender Bending"),
    ("Medical", "Medicine"),
    ("Organized Crime", "Yakuza"),
    ("Performing Arts", "Acting"),
    ("Pets", "Animals"),
    ("Racing", "Cars"),
    ("Reverse Harem", "Male Harem"),
    ("Strategy Game", "Board Game"),
    ("Suspense", "Thriller"),
    ("Team Sports", "Volleyball"),
    ("Time Travel", "Time Manipulation"),
    ("Video Game", "Video Games"),
    ("Visual Arts", "Drawing"),
    ("Workplace", "Work"),
    ("Game", "Video Games"),
    ("Isekai", "Isekai"),
    ("Mahou Shoujo", "Mahou Shoujo"),
];

pub fn anilist_name(genre: &str) -> &str {
    ALIASES
        .iter()
        .find(|(name, _)| *name == genre)
        .map_or(genre, |(_, renamed)| renamed)
}

fn urls(pages: &HashMap<String, RawCoverPage>, alias: &str) -> Vec<String> {
    pages
        .get(alias)
        .map(|page| {
            page.media
                .iter()
                .filter_map(|media| media.cover_image.as_ref()?.large.clone())
                .filter(|url| !url.is_empty())
                .collect()
        })
        .unwrap_or_default()
}

pub fn candidates(pages: &HashMap<String, RawCoverPage>, count: usize) -> Vec<Vec<String>> {
    (0..count)
        .map(|index| {
            let mut found = urls(pages, &format!("g{index}"));
            for url in urls(pages, &format!("t{index}")) {
                if !found.contains(&url) {
                    found.push(url);
                }
            }
            found
        })
        .collect()
}

async fn cover_chunk(
    graphql: &GraphQl,
    kind: MediaKind,
    genres: &[String],
) -> Result<Vec<Vec<String>>, SourceError> {
    let mut variables = json!({ "type": media_type(kind) });
    for (index, genre) in genres.iter().enumerate() {
        variables[format!("n{index}")] = json!(anilist_name(genre));
    }
    let data = graphql
        .run(&genre_covers_query(genres.len()), variables)
        .await?;
    let pages: HashMap<String, RawCoverPage> = parse(data, "covers")?;
    Ok(candidates(&pages, genres.len()))
}

pub async fn fetch_covers(
    graphql: &GraphQl,
    kind: MediaKind,
    genres: &[String],
) -> Result<Vec<Vec<String>>, SourceError> {
    let mut found: Vec<Vec<String>> = Vec::with_capacity(genres.len());
    let mut failure: Option<SourceError> = None;
    let mut served = 0usize;
    for chunk in genres.chunks(COVER_CHUNK) {
        match cover_chunk(graphql, kind, chunk).await {
            Ok(part) => {
                served += 1;
                found.extend(part);
            }
            Err(error) => {
                failure.get_or_insert(error);
                found.extend(chunk.iter().map(|_| Vec::new()));
            }
        }
    }
    match failure {
        Some(error) if served == 0 && !genres.is_empty() => Err(error),
        _ => Ok(found),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn pages(value: serde_json::Value) -> HashMap<String, RawCoverPage> {
        serde_json::from_value(value).unwrap()
    }

    #[test]
    fn site_names_are_translated_to_the_catalog_vocabulary() {
        assert_eq!(anilist_name("Gourmet"), "Food");
        assert_eq!(anilist_name("Boys Love"), "Boys' Love");
        assert_eq!(anilist_name("Girls Love"), "Yuri");
        assert_eq!(anilist_name("CGDCT"), "Cute Girls Doing Cute Things");
        assert_eq!(anilist_name("Combat Sports"), "Boxing");
        assert_eq!(anilist_name("Action"), "Action");
    }

    #[test]
    fn every_alias_is_unique_per_site_name() {
        let mut names: Vec<&str> = ALIASES.iter().map(|(name, _)| *name).collect();
        names.sort_unstable();
        names.dedup();
        assert_eq!(names.len(), ALIASES.len());
    }

    #[test]
    fn genre_covers_come_before_tag_covers_without_repeats() {
        let found = pages(json!({
            "g0": { "media": [{ "coverImage": { "large": "a" } }] },
            "t0": { "media": [
                { "coverImage": { "large": "a" } },
                { "coverImage": { "large": "b" } }
            ] },
        }));
        assert_eq!(candidates(&found, 1), vec![vec!["a", "b"]]);
    }

    #[test]
    fn missing_pages_and_empty_covers_yield_no_candidates() {
        let found = pages(json!({
            "g0": { "media": [{ "coverImage": { "large": "" } }, { "coverImage": null }] },
        }));
        assert_eq!(candidates(&found, 2), vec![Vec::<String>::new(); 2]);
    }
}
