use domain::source::Unit;
use scraper::Html;

use crate::sources::support::{collapse, selector, text_of};

fn chapter_slug(href: &str, slug: &str) -> Option<String> {
    let prefix = format!("/novel/{slug}/");
    let start = href.find(&prefix)? + prefix.len();
    let rest = href[start..].trim_end_matches('/');
    let segment_ok = |segment: &str| {
        !segment.is_empty()
            && !segment.chars().all(|c| c == '.')
            && segment
                .chars()
                .all(|c| c.is_ascii_alphanumeric() || matches!(c, '-' | '.' | '_' | '%'))
    };
    rest.split('/')
        .all(segment_ok)
        .then(|| rest.to_string())
}

pub fn parse_chapter_list(html: &str, slug: &str) -> Vec<Unit> {
    let document = Html::parse_document(html);
    let mut newest_first: Vec<(String, String)> = Vec::new();
    for anchor in document.select(&selector("li.wp-manga-chapter a")) {
        let href = anchor.value().attr("href").unwrap_or_default();
        let Some(id) = chapter_slug(href, slug) else {
            continue;
        };
        let label = collapse(&text_of(anchor));
        if label.is_empty() || newest_first.iter().any(|(known, _)| *known == id) {
            continue;
        }
        newest_first.push((id, label));
    }
    newest_first
        .into_iter()
        .rev()
        .enumerate()
        .map(|(index, (id, label))| Unit::new(format!("{slug}/{id}"), (index + 1) as f64, label))
        .collect()
}
