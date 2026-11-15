use domain::source::Unit;
use scraper::{ElementRef, Html};

use crate::sources::support::{collapse, selector, text_of};

pub fn page_count(html: &str) -> u32 {
    let document = Html::parse_document(html);
    document
        .select(&selector(".pagination a.page-link, select[aria-label='Chapter range'] option"))
        .filter_map(|link| link.value().attr("href").or(link.value().attr("value")))
        .filter_map(|href| href.split("page=").nth(1))
        .filter_map(|number| number.split('&').next()?.parse::<u32>().ok())
        .max()
        .unwrap_or(1)
}

fn chapter_slug(href: &str, slug: &str) -> Option<String> {
    let prefix = format!("/novel/{slug}/");
    let start = href.find(&prefix)? + prefix.len();
    let rest = &href[start..];
    let number = rest.strip_prefix("chapter-")?;
    let valid = !number.is_empty() && number.chars().all(|c| c.is_ascii_digit());
    valid.then(|| rest.to_string())
}

fn part_of(anchor: ElementRef, css: &str) -> String {
    anchor
        .select(&selector(css))
        .next()
        .map(|node| collapse(&text_of(node)))
        .unwrap_or_default()
}

fn label_of(anchor: ElementRef) -> String {
    let number = part_of(anchor, ".chapter-no");
    let title = part_of(anchor, ".chapter-title");
    match (number.is_empty(), title.is_empty()) {
        (false, false) => format!("{number} \u{b7} {title}"),
        (false, true) => number,
        _ => title,
    }
}

pub fn parse_chapter_pages(pages: &[String], slug: &str) -> Vec<Unit> {
    let mut found: Vec<(String, String)> = Vec::new();
    for html in pages {
        let document = Html::parse_document(html);
        for anchor in document.select(&selector("ul.chapter-list li a")) {
            let href = anchor.value().attr("href").unwrap_or_default();
            let Some(id) = chapter_slug(href, slug) else {
                continue;
            };
            if found.iter().any(|(known, _)| *known == id) {
                continue;
            }
            found.push((id, label_of(anchor)));
        }
    }
    found
        .into_iter()
        .enumerate()
        .map(|(index, (id, label))| Unit::new(format!("{slug}/{id}"), (index + 1) as f64, label))
        .collect()
}
