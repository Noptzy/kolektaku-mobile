use domain::media::{MediaKind, MediaListKind};
use serde_json::{Value, json};

use super::season::{fuzzy_date_days_ago, season_of};

const PAGE_SIZE: u32 = 20;
const HERO_PAGE_SIZE: u32 = 8;
const ANIME_COUNTRY: &str = "JP";
const WEEK_DAYS: u64 = 7;
const NEWEST_DAYS: u64 = 30;
const COMEBACK_DAYS: u64 = 45;

#[derive(Debug, Clone, PartialEq)]
pub struct ListRequest {
    pub variables: Value,
    pub rich: bool,
    pub prequels: bool,
}

fn sorts(list: MediaListKind) -> Vec<&'static str> {
    match list {
        MediaListKind::Trending => vec!["TRENDING_DESC", "POPULARITY_DESC"],
        MediaListKind::TopRated => vec!["SCORE_DESC"],
        _ => vec!["POPULARITY_DESC"],
    }
}

fn is_hero(list: MediaListKind) -> bool {
    matches!(
        list,
        MediaListKind::TopRated
            | MediaListKind::NewThisWeek
            | MediaListKind::FinishedThisWeek
            | MediaListKind::Returning
    )
}

fn add_window(variables: &mut Value, list: MediaListKind, now_secs: u64) {
    match list {
        MediaListKind::TopRated => variables["status"] = json!("RELEASING"),
        MediaListKind::NewThisWeek => {
            variables["status"] = json!("RELEASING");
            variables["startFrom"] = json!(fuzzy_date_days_ago(now_secs, NEWEST_DAYS));
        }
        MediaListKind::FinishedThisWeek => {
            variables["status"] = json!("FINISHED");
            variables["endFrom"] = json!(fuzzy_date_days_ago(now_secs, WEEK_DAYS));
        }
        MediaListKind::Returning => {
            variables["status"] = json!("RELEASING");
            variables["startFrom"] = json!(fuzzy_date_days_ago(now_secs, COMEBACK_DAYS));
        }
        MediaListKind::Seasonal => {
            let season = season_of(now_secs);
            variables["season"] = json!(season.name);
            variables["year"] = json!(season.year);
        }
        MediaListKind::Trending | MediaListKind::Popular => {}
    }
}

pub fn list_request(
    kind: MediaKind,
    list: MediaListKind,
    page: u32,
    now_secs: u64,
    type_name: &str,
) -> ListRequest {
    let per_page = if is_hero(list) {
        HERO_PAGE_SIZE
    } else {
        PAGE_SIZE
    };
    let mut variables = json!({
        "page": page,
        "perPage": per_page,
        "type": type_name,
        "sort": sorts(list),
    });
    if kind == MediaKind::Anime {
        variables["country"] = json!(ANIME_COUNTRY);
    }
    add_window(&mut variables, list, now_secs);
    ListRequest {
        variables,
        rich: list == MediaListKind::Trending || is_hero(list),
        prequels: list == MediaListKind::Returning,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const NOW: u64 = 1_768_478_400;

    fn request(kind: MediaKind, list: MediaListKind) -> ListRequest {
        let name = if kind == MediaKind::Anime {
            "ANIME"
        } else {
            "MANGA"
        };
        list_request(kind, list, 1, NOW, name)
    }

    #[test]
    fn trending_keeps_its_old_shape_but_is_rich() {
        let request = request(MediaKind::Anime, MediaListKind::Trending);
        assert_eq!(request.variables["perPage"], 20);
        assert_eq!(
            request.variables["sort"],
            json!(["TRENDING_DESC", "POPULARITY_DESC"])
        );
        assert!(request.rich && !request.prequels);
    }

    #[test]
    fn popular_is_plain_and_has_no_window() {
        let request = request(MediaKind::Manga, MediaListKind::Popular);
        assert!(!request.rich);
        assert!(request.variables.get("status").is_none());
        assert!(request.variables.get("country").is_none());
    }

    #[test]
    fn the_seasonal_list_asks_for_the_current_season() {
        let request = request(MediaKind::Anime, MediaListKind::Seasonal);
        assert_eq!(request.variables["season"], "WINTER");
        assert_eq!(request.variables["year"], 2026);
        assert_eq!(request.variables["country"], "JP");
    }

    #[test]
    fn the_top_rated_list_sorts_by_score_among_what_is_airing() {
        let request = request(MediaKind::Anime, MediaListKind::TopRated);
        assert_eq!(request.variables["sort"], json!(["SCORE_DESC"]));
        assert_eq!(request.variables["status"], "RELEASING");
        assert_eq!(request.variables["perPage"], HERO_PAGE_SIZE);
        assert!(request.rich);
    }

    #[test]
    fn the_newest_list_looks_back_a_month_so_it_is_rarely_empty() {
        let request = request(MediaKind::Anime, MediaListKind::NewThisWeek);
        assert_eq!(request.variables["status"], "RELEASING");
        assert_eq!(request.variables["startFrom"], 20_251_216);
        assert!(request.variables.get("endFrom").is_none());
    }

    #[test]
    fn finished_this_week_looks_at_end_dates() {
        let request = request(MediaKind::Anime, MediaListKind::FinishedThisWeek);
        assert_eq!(request.variables["status"], "FINISHED");
        assert_eq!(request.variables["endFrom"], 20_260_108);
        assert!(request.variables.get("startFrom").is_none());
    }

    #[test]
    fn comebacks_look_back_further_and_want_the_prequel_links() {
        let request = request(MediaKind::Anime, MediaListKind::Returning);
        assert_eq!(request.variables["startFrom"], 20_251_201);
        assert!(request.prequels && request.rich);
    }

    #[test]
    fn manga_lists_never_carry_the_japanese_country_filter() {
        let request = request(MediaKind::Manga, MediaListKind::TopRated);
        assert!(request.variables.get("country").is_none());
        assert_eq!(request.variables["type"], "MANGA");
    }
}
