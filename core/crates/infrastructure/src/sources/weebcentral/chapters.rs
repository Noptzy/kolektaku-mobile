use domain::source::Unit;
use scraper::Html;

use super::urls::is_series_code;
use crate::sources::support::{collapse, first_number, selector, text_of};

fn number_in(label: &str) -> Option<f64> {
    let lower = label.to_lowercase();
    let after = lower
        .find("chapter")
        .map(|at| &label[at + "chapter".len()..])
        .and_then(first_number);
    after.or_else(|| first_number(label))
}

pub fn parse_chapter_list(html: &str) -> Vec<Unit> {
    let document = Html::parse_document(html);
    let mut found: Vec<Unit> = Vec::new();
    for anchor in document.select(&selector("a[href^='/chapters/']")) {
        let href = anchor.value().attr("href").unwrap_or_default();
        let Some(id) = href.strip_prefix("/chapters/").filter(|id| is_series_code(id)) else {
            continue;
        };
        let label = anchor
            .select(&selector("span.grow > span"))
            .next()
            .map(|node| collapse(&text_of(node)))
            .unwrap_or_default();
        let Some(number) = number_in(&label) else {
            continue;
        };
        if found.iter().any(|known| known.id == id) {
            continue;
        }
        found.push(Unit::new(id, number, label));
    }
    found.sort_by(|left, right| left.number.total_cmp(&right.number));
    found
}
