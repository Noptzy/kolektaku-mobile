use std::collections::HashSet;

use domain::error::SourceError;
use domain::source::Genre;
use scraper::Html;

use crate::sources::support::{collapse, selector, text_of};

const HIDDEN_GENRES: [&str; 2] = ["hentai", "erotica"];
const GENRE_PATH: &str = "/properties/genre/";

fn slug_of(href: &str) -> Option<String> {
    let start = href.find(GENRE_PATH)? + GENRE_PATH.len();
    let rest = &href[start..];
    let end = rest
        .find(|c: char| !(c.is_ascii_alphanumeric() || c == '-'))
        .unwrap_or(rest.len());
    (end > 0).then(|| rest[..end].to_lowercase())
}

fn is_hidden(genre: &Genre) -> bool {
    HIDDEN_GENRES.contains(&genre.slug.as_str())
        || HIDDEN_GENRES.contains(&genre.name.to_lowercase().as_str())
}

pub fn parse_genres(html: &str) -> Result<Vec<Genre>, SourceError> {
    let document = Html::parse_document(html);
    let mut seen = HashSet::new();
    let genres: Vec<Genre> = document
        .select(&selector(
            ".kuramanime__genres a[href*='/properties/genre/']",
        ))
        .filter_map(|anchor| {
            let slug = slug_of(anchor.value().attr("href")?)?;
            let name = collapse(&text_of(anchor));
            (!name.is_empty()).then(|| Genre::new(slug, name))
        })
        .filter(|genre| !is_hidden(genre))
        .filter(|genre| seen.insert(genre.slug.clone()))
        .collect();
    if genres.is_empty() {
        return Err(SourceError::MarkupChanged("genres were not found".into()));
    }
    Ok(genres)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::fixtures;

    #[test]
    fn parses_the_real_list_minus_the_adult_genres() {
        let genres = parse_genres(&fixtures::kuramanime("genres.html")).unwrap();
        let slugs: Vec<&str> = genres.iter().map(|genre| genre.slug.as_str()).collect();
        assert_eq!(genres.len(), 77);
        assert_eq!(genres[0], Genre::new("action", "Action"));
        assert_eq!(slugs.iter().collect::<HashSet<_>>().len(), 77);
        assert!(!slugs.contains(&"hentai") && !slugs.contains(&"erotica"));
        assert!(slugs.contains(&"ecchi"));
    }

    #[test]
    fn never_lists_adult_genres_by_slug_or_by_name() {
        let html = r#"<div class="kuramanime__genres"><ul>
          <li><a href="https://x.test/properties/genre/action?order_by=text">Action</a></li>
          <li><a href="https://x.test/properties/genre/hentai?order_by=text">Hentai</a></li>
          <li><a href="https://x.test/properties/genre/erotica?order_by=text">Erotica</a></li>
          <li><a href="https://x.test/properties/genre/dewasa?order_by=text">Hentai</a></li>
        </ul></div>"#;
        assert_eq!(
            parse_genres(html).unwrap(),
            vec![Genre::new("action", "Action")]
        );
    }

    #[test]
    fn a_page_without_genres_is_a_markup_change() {
        assert!(matches!(
            parse_genres("<main></main>"),
            Err(SourceError::MarkupChanged(_))
        ));
    }

    #[test]
    fn links_without_a_name_or_slug_are_skipped() {
        let html = r#"<div class="kuramanime__genres">
          <a href="/properties/genre/">Empty slug</a>
          <a href="/properties/genre/drama"> </a>
          <a href="/properties/genre/Slice-Of-Life">Slice of  Life</a></div>"#;
        assert_eq!(
            parse_genres(html).unwrap(),
            vec![Genre::new("slice-of-life", "Slice of Life")]
        );
    }
}
