use domain::error::SourceError;
use domain::source::{ItemId, SourceItem};
use serde_json::Value;

pub fn parse_categories(json: &str) -> Result<Vec<String>, SourceError> {
    let value: Value = serde_json::from_str(json)
        .map_err(|_| SourceError::MarkupChanged("the series list was not readable".into()))?;
    let members = value["query"]["categorymembers"]
        .as_array()
        .ok_or_else(|| SourceError::MarkupChanged("the series list was not found".into()))?;
    Ok(members
        .iter()
        .filter_map(|member| member["title"].as_str())
        .filter(|title| !title.contains(':'))
        .map(str::to_string)
        .collect())
}

pub fn item_of(title: &str) -> SourceItem {
    SourceItem::new(ItemId::new(title.replace(' ', "_")), title)
}

fn compact(text: &str) -> String {
    text.chars()
        .filter(|symbol| symbol.is_alphanumeric())
        .flat_map(char::to_lowercase)
        .collect()
}

fn words(text: &str) -> Vec<String> {
    text.split(|symbol: char| !symbol.is_alphanumeric())
        .map(compact)
        .filter(|word| !word.is_empty())
        .collect()
}

pub fn matching_titles(titles: &[String], query: &str) -> Vec<SourceItem> {
    let wanted = words(query);
    if wanted.is_empty() {
        return Vec::new();
    }
    let mut found: Vec<&String> = titles
        .iter()
        .filter(|title| {
            let own = compact(title);
            wanted.iter().all(|word| own.contains(word.as_str()))
        })
        .collect();
    found.sort_by_key(|title| title.chars().count());
    found.into_iter().map(|title| item_of(title)).collect()
}

pub fn first_titles(titles: &[String], count: usize, page: u32) -> Vec<SourceItem> {
    let skip = (page.max(1) as usize - 1) * count;
    titles.iter().skip(skip).take(count).map(|title| item_of(title)).collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::fixtures;

    fn titles() -> Vec<String> {
        parse_categories(&fixtures::read("bakatsuki", "category.json")).unwrap()
    }

    #[test]
    fn the_series_list_holds_the_titles_without_subpages() {
        let all = titles();
        assert!(all.len() > 100);
        assert!(all.iter().any(|title| title == "Hyouka"));
        assert!(all.iter().all(|title| !title.contains(':')));
    }

    #[test]
    fn a_search_finds_a_series_whatever_the_case_or_punctuation() {
        let all = titles();
        for query in ["hyouka", "HYOUKA", "Hyouka!"] {
            let items = matching_titles(&all, query);
            assert_eq!(items[0].item_id.as_str(), "Hyouka", "{query}");
        }
    }

    #[test]
    fn every_word_of_the_query_must_be_in_the_title() {
        let all = titles();
        assert!(matching_titles(&all, "hyouka nonsense").is_empty());
        assert!(matching_titles(&all, "   ").is_empty());
    }

    #[test]
    fn spaces_become_underscores_in_the_item_id_but_not_in_the_title() {
        let item = item_of("Baka to Test");
        assert_eq!(item.item_id.as_str(), "Baka_to_Test");
        assert_eq!(item.title, "Baka to Test");
    }

    #[test]
    fn a_page_of_the_listing_is_a_slice_of_the_series() {
        let all = titles();
        assert_eq!(first_titles(&all, 5, 1).len(), 5);
        assert_eq!(first_titles(&all, 5, 2)[0].title, all[5]);
        assert!(first_titles(&all, 5, 999).is_empty());
    }

    #[test]
    fn a_broken_answer_is_a_markup_change() {
        assert!(parse_categories("<html>").is_err());
        assert!(parse_categories("{}").is_err());
    }
}
