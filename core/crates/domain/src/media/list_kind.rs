use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum MediaListKind {
    Trending,
    Popular,
    Seasonal,
    TopRated,
    NewThisWeek,
    FinishedThisWeek,
    Returning,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn uses_snake_case_in_json() {
        assert_eq!(
            serde_json::to_string(&MediaListKind::Trending).unwrap(),
            "\"trending\""
        );
    }

    #[test]
    fn the_weekly_kinds_use_snake_case_too() {
        let names: Vec<String> = [
            MediaListKind::TopRated,
            MediaListKind::NewThisWeek,
            MediaListKind::FinishedThisWeek,
            MediaListKind::Returning,
        ]
        .iter()
        .map(|kind| serde_json::to_string(kind).unwrap())
        .collect();
        assert_eq!(
            names,
            vec![
                "\"top_rated\"",
                "\"new_this_week\"",
                "\"finished_this_week\"",
                "\"returning\""
            ]
        );
    }
}
