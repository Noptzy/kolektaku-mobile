use domain::media::MediaKind;
use serde_json::{Value, json};

use super::catalog::media_type;
use super::format_scope::apply_format_scope;

const ANIME_COUNTRY: &str = "JP";

pub fn search_variables(kind: MediaKind, query: &str, page: u32, per_page: u32) -> Value {
    let mut variables = json!({
        "page": page,
        "perPage": per_page,
        "type": media_type(kind),
        "search": query.trim(),
    });
    if kind == MediaKind::Anime {
        variables["country"] = json!(ANIME_COUNTRY);
    }
    apply_format_scope(&mut variables, kind);
    variables
}
