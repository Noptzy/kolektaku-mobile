use domain::media::EpisodeInfo;
use scraper::Html;

use crate::sources::support::{collapse, selector, text_of};

fn is_placeholder(title: &str) -> bool {
    let lower = title.to_lowercase();
    let Some(rest) = lower.strip_prefix("episode ") else {
        return false;
    };
    !rest.is_empty()
        && rest
            .chars()
            .all(|letter| letter.is_ascii_digit() || letter == '.')
}

pub fn parse_episode_titles(html: &str) -> Vec<EpisodeInfo> {
    let document = Html::parse_document(html);
    let mut found: Vec<EpisodeInfo> = Vec::new();
    for row in document.select(&selector("table.anime-episode-list tr")) {
        let Some(number) = row
            .select(&selector("td.episode-number"))
            .next()
            .and_then(|cell| collapse(&text_of(cell)).parse::<f64>().ok())
        else {
            continue;
        };
        let title = row
            .select(&selector("td.episode-title a span"))
            .next()
            .map(|span| collapse(&text_of(span)))
            .unwrap_or_default();
        if title.is_empty() || is_placeholder(&title) {
            continue;
        }
        if found.iter().any(|known| known.number == number) {
            continue;
        }
        found.push(EpisodeInfo::new(number, title));
    }
    found
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::fixtures;

    fn table(rows: &str) -> String {
        format!(
            r#"<table class="anime-episode-list"><tr class="episode-list-header"><td class="episode-number ac">#</td>
            <td class="episode-title ac">Episode</td></tr>{rows}</table>"#
        )
    }

    fn row(number: &str, title: &str) -> String {
        format!(
            r#"<tr><td class="episode-number nowrap">{number}</td><td class="episode-title va-t">
            <a class="clearfix" href="x"><span class="fs16 lh18 fw-b">{title}</span><br></a></td></tr>"#
        )
    }

    #[test]
    fn a_real_page_gives_numbers_and_titles() {
        let episodes = parse_episode_titles(&fixtures::mal("episodes-59741.html"));
        assert!(episodes.len() >= 5);
        assert_eq!(episodes[0].number, 1.0);
        assert_eq!(episodes[0].title, "I'm Elymas the Heavy Knight");
        assert!(episodes.iter().all(|item| item.thumbnail_url.is_none()));
        assert!(
            episodes
                .windows(2)
                .all(|pair| pair[0].number < pair[1].number)
        );
    }

    #[test]
    fn entities_in_titles_are_decoded() {
        let html = table(&row("1", "Don&#039;t &amp; Go"));
        assert_eq!(parse_episode_titles(&html)[0].title, "Don't & Go");
    }

    #[test]
    fn placeholder_titles_are_not_titles() {
        let html = table(&format!(
            "{}{}{}",
            row("1", "Episode 1"),
            row("2", "episode 2.5"),
            row("3", "A Real Name")
        ));
        let episodes = parse_episode_titles(&html);
        assert_eq!(episodes.len(), 1);
        assert_eq!(episodes[0].number, 3.0);
    }

    #[test]
    fn a_name_that_merely_starts_with_episode_is_kept() {
        let html = table(&row("4", "Episode Zero Returns"));
        assert_eq!(parse_episode_titles(&html)[0].title, "Episode Zero Returns");
    }

    #[test]
    fn rows_without_a_number_or_a_title_are_skipped_and_duplicates_keep_the_first() {
        let html = table(&format!(
            "{}{}{}{}",
            row("", "No number"),
            row("1", ""),
            row("2", "Two"),
            row("2", "Two again")
        ));
        let episodes = parse_episode_titles(&html);
        assert_eq!(episodes.len(), 1);
        assert_eq!(episodes[0].title, "Two");
    }

    #[test]
    fn a_page_without_the_table_has_no_episodes() {
        assert!(parse_episode_titles("<html><body>nothing</body></html>").is_empty());
        assert!(parse_episode_titles("").is_empty());
        assert!(parse_episode_titles("{\"data\":{}}").is_empty());
    }

    #[test]
    fn a_half_episode_keeps_its_fraction() {
        let html = table(&row("6.5", "Recap"));
        assert_eq!(parse_episode_titles(&html)[0].number, 6.5);
    }
}
