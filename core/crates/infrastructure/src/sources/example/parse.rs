use domain::error::SourceError;
use domain::source::{ItemId, SourceItem, Unit};
use scraper::Html;

use crate::sources::support::{collapse, first_number, selector, slug_in, text_of};

pub fn parse_items(html: &str) -> Result<Vec<SourceItem>, SourceError> {
    let document = Html::parse_document(html);
    if document.select(&selector(".items")).next().is_none() {
        return Err(SourceError::MarkupChanged("the item list was not found".into()));
    }
    Ok(document
        .select(&selector(".items li a"))
        .filter_map(|anchor| {
            let href = anchor.value().attr("href")?;
            let slug = slug_in(href.strip_prefix("/title/")?, &[])?;
            Some(SourceItem::new(ItemId::new(slug), collapse(&text_of(anchor))))
        })
        .collect())
}

pub fn parse_title(html: &str) -> Result<String, SourceError> {
    Html::parse_document(html)
        .select(&selector("h1"))
        .next()
        .map(|heading| collapse(&text_of(heading)))
        .filter(|title| !title.is_empty())
        .ok_or_else(|| SourceError::MarkupChanged("the title was not found".into()))
}

pub fn parse_episodes(html: &str) -> Result<Vec<Unit>, SourceError> {
    let document = Html::parse_document(html);
    let mut episodes: Vec<Unit> = document
        .select(&selector(".episodes li a"))
        .filter_map(|anchor| {
            let id = slug_in(anchor.value().attr("href")?.strip_prefix("/watch/")?, &[])?;
            let label = collapse(&text_of(anchor));
            Some(Unit::new(id, first_number(&label)?, label))
        })
        .collect();
    if episodes.is_empty() {
        return Err(SourceError::MarkupChanged("the episode list was not found".into()));
    }
    episodes.sort_by(|left, right| left.number.total_cmp(&right.number));
    Ok(episodes)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::fixtures;

    #[test]
    fn reads_items_title_and_episodes_from_the_fixtures() {
        let items = parse_items(&fixtures::read("example", "list.html")).unwrap();
        assert_eq!(items.len(), 2);
        assert_eq!(items[0].item_id.as_str(), "alpha");
        let detail = fixtures::read("example", "detail.html");
        assert_eq!(parse_title(&detail).unwrap(), "Alpha");
        let numbers: Vec<f64> = parse_episodes(&detail).unwrap().iter().map(|unit| unit.number).collect();
        assert_eq!(numbers, vec![1.0, 2.0]);
    }

    #[test]
    fn changed_markup_is_reported() {
        assert!(parse_items("<main></main>").is_err());
        assert!(parse_title("<main></main>").is_err());
        assert!(parse_episodes("<main></main>").is_err());
    }
}
