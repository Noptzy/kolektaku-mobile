use domain::media::MediaKind;
use serde_json::{Value, json};

const NOVEL_FORMAT: &str = "NOVEL";

pub fn apply_format_scope(variables: &mut Value, kind: MediaKind) {
    match kind {
        MediaKind::Anime => {}
        MediaKind::Manga => variables["notFormats"] = json!([NOVEL_FORMAT]),
        MediaKind::Novel => variables["formats"] = json!([NOVEL_FORMAT]),
    }
}
