use domain::source::Unit;
use scraper::{ElementRef, Html};

use crate::sources::support::{first_number, selector, text_of};
use super::urls::valid_slug;

fn slug_of(href: &str) -> Option<String> {
    let path = href.split(['?', '#']).next()?;
    let slug = path.trim_end_matches('/').rsplit('/').next()?;
    valid_slug(slug).then(|| slug.to_string())
}

fn read_row(row: ElementRef) -> Option<Unit> {
    let anchor = row.select(&selector("a[href]")).next()?;
    let slug = slug_of(anchor.value().attr("href")?)?;
    let number = row
        .select(&selector(".epl-num"))
        .next()
        .and_then(|cell| first_number(&text_of(cell)))
        .or_else(|| {
            row.select(&selector(".epl-title"))
                .next()
                .and_then(|title| first_number(&text_of(title)))
        })?;
    let label = if number.fract() == 0.0 {
        format!("Episode {}", number as u64)
    } else {
        format!("Episode {number}")
    };
    Some(Unit::new(slug, number, label))
}

pub fn parse_units(html: &str) -> Vec<Unit> {
    let document = Html::parse_document(html);
    let mut units: Vec<Unit> = document
        .select(&selector(".eplister ul li"))
        .filter_map(read_row)
        .collect();
    units.sort_by(|left, right| left.number.total_cmp(&right.number));
    units.dedup_by(|later, earlier| later.id == earlier.id);
    units
}
