use std::collections::HashSet;

use domain::error::SourceError;
use domain::source::Genre;
use scraper::Html;

use crate::sources::support::{collapse, is_adult_label, selector, slug_in, text_of};

const GENRE_PATH: &str = "/genre/";

fn slug_of(href: &str) -> Option<String> {
    let start = href.find(GENRE_PATH)? + GENRE_PATH.len();
    slug_in(&href[start..], &[]).map(|slug| slug.to_lowercase())
}

pub fn parse_genres(html: &str) -> Result<Vec<Genre>, SourceError> {
    let document = Html::parse_document(html);
    let mut seen = HashSet::new();
    let genres: Vec<Genre> = document
        .select(&selector("ul.genre li a[href*='/genre/']"))
        .filter_map(|anchor| {
            let slug = slug_of(anchor.value().attr("href")?)?;
            let name = collapse(&text_of(anchor));
            (!name.is_empty()).then(|| Genre::new(slug, name))
        })
        .filter(|genre| !is_adult_label(&genre.slug) && !is_adult_label(&genre.name))
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
    fn parses_the_menu_without_adult_genres_or_duplicates() {
        let genres = parse_genres(&fixtures::komiku("genre-list.html")).unwrap();
        let slugs: Vec<&str> = genres.iter().map(|genre| genre.slug.as_str()).collect();
        assert!(genres.len() > 90);
        assert!(genres.contains(&Genre::new("action", "Action")));
        for hidden in ["hentai", "adult", "smut", "shotacon", "sexual-violence"] {
            assert!(!slugs.contains(&hidden), "{hidden}");
        }
        assert_eq!(slugs.iter().collect::<HashSet<_>>().len(), slugs.len());
    }

    #[test]
    fn a_page_without_a_menu_is_a_markup_change() {
        assert!(matches!(
            parse_genres("<main></main>"),
            Err(SourceError::MarkupChanged(_))
        ));
    }

    #[test]
    fn absolute_and_relative_links_both_yield_a_slug() {
        let html = r#"<ul class="genre"><li><a href="/genre/Action/">Action</a></li>
            <li><a href="https://komiku.org/genre/drama/">Drama</a></li><li><a href="/genre/">Empty</a></li></ul>"#;
        let slugs: Vec<String> = parse_genres(html)
            .unwrap()
            .into_iter()
            .map(|genre| genre.slug)
            .collect();
        assert_eq!(slugs, vec!["action", "drama"]);
    }
}
