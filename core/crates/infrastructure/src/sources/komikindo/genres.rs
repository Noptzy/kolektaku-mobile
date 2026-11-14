use std::collections::HashSet;

use domain::error::SourceError;
use domain::source::Genre;
use scraper::{ElementRef, Html};

use crate::sources::support::{collapse, is_adult_label, selector, text_of};

fn label_after(input: ElementRef) -> String {
    input
        .next_siblings()
        .filter_map(ElementRef::wrap)
        .next()
        .filter(|sibling| sibling.value().name() == "label")
        .map(|label| collapse(&text_of(label)))
        .unwrap_or_default()
}

pub fn parse_genres(html: &str) -> Result<Vec<Genre>, SourceError> {
    let document = Html::parse_document(html);
    let mut seen = HashSet::new();
    let genres: Vec<Genre> = document
        .select(&selector("input[name='genre[]']"))
        .filter_map(|input| {
            let slug = input.value().attr("value")?.trim().to_lowercase();
            let name = label_after(input);
            (!slug.is_empty() && !name.is_empty()).then(|| Genre::new(slug, name))
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
    fn reads_the_filter_form_without_adult_genres() {
        let genres = parse_genres(&fixtures::komikindo("filter.html")).unwrap();
        assert_eq!(
            genres,
            vec![
                Genre::new("action", "Action"),
                Genre::new("comedy", "Comedy"),
                Genre::new("drama", "Drama"),
            ]
        );
    }

    #[test]
    fn a_page_without_the_form_is_a_markup_change() {
        assert!(matches!(
            parse_genres("<main></main>"),
            Err(SourceError::MarkupChanged(_))
        ));
    }

    #[test]
    fn duplicates_and_inputs_without_a_label_are_skipped() {
        let html = r#"<input name="genre[]" value="a"><label>A</label><input name="genre[]" value="a"><label>Again</label>
            <input name="genre[]" value="b"><span>no label</span>"#;
        assert_eq!(parse_genres(html).unwrap(), vec![Genre::new("a", "A")]);
    }
}
