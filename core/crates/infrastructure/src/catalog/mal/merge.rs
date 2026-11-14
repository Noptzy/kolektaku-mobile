use domain::media::EpisodeInfo;

pub fn merge_titles(listed: Vec<EpisodeInfo>, titled: Vec<EpisodeInfo>) -> Vec<EpisodeInfo> {
    let mut merged = listed;
    for extra in titled {
        match merged.iter_mut().find(|known| known.number == extra.number) {
            Some(known) if known.title.trim().is_empty() => known.title = extra.title,
            Some(_) => {}
            None => merged.push(extra),
        }
    }
    merged.sort_by(|a, b| a.number.total_cmp(&b.number));
    merged
}

#[cfg(test)]
mod tests {
    use super::*;

    fn info(number: f64, title: &str, thumbnail: Option<&str>) -> EpisodeInfo {
        let mut item = EpisodeInfo::new(number, title);
        item.thumbnail_url = thumbnail.map(str::to_string);
        item
    }

    #[test]
    fn a_picture_only_entry_takes_the_title_from_the_other_list() {
        let merged = merge_titles(
            vec![info(1.0, "", Some("https://img.test/1.jpg"))],
            vec![info(1.0, "Title", None)],
        );
        assert_eq!(merged.len(), 1);
        assert_eq!(merged[0].title, "Title");
        assert_eq!(
            merged[0].thumbnail_url.as_deref(),
            Some("https://img.test/1.jpg")
        );
    }

    #[test]
    fn an_existing_title_is_never_replaced() {
        let merged = merge_titles(
            vec![info(1.0, "Mine", None)],
            vec![info(1.0, "Theirs", None)],
        );
        assert_eq!(merged[0].title, "Mine");
    }

    #[test]
    fn episodes_only_the_second_list_knows_are_added_in_order() {
        let merged = merge_titles(
            vec![info(2.0, "Two", Some("https://img.test/2.jpg"))],
            vec![info(3.0, "Three", None), info(1.0, "One", None)],
        );
        let numbers: Vec<f64> = merged.iter().map(|item| item.number).collect();
        assert_eq!(numbers, vec![1.0, 2.0, 3.0]);
        assert_eq!(merged[0].title, "One");
        assert!(merged[0].thumbnail_url.is_none());
        assert!(merged[1].thumbnail_url.is_some());
    }

    #[test]
    fn nothing_listed_means_the_titles_stand_alone() {
        let merged = merge_titles(Vec::new(), vec![info(1.0, "One", None)]);
        assert_eq!(merged.len(), 1);
    }

    #[test]
    fn nothing_to_add_leaves_the_list_as_it_was() {
        let merged = merge_titles(vec![info(1.0, "One", None)], Vec::new());
        assert_eq!(merged, vec![info(1.0, "One", None)]);
    }
}
