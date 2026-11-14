use domain::media::MediaId;
use domain::scene::{SceneMatch, SceneReply};

use super::schema::{RawAnilist, RawEpisode, RawReply, RawResult, RawTitle};

pub fn to_reply(reply: RawReply) -> SceneReply {
    let quota_left = SceneReply::quota_from(reply.quota, reply.quota_used);
    SceneReply {
        matches: reply.result.into_iter().filter_map(to_match).collect(),
        quota_left,
    }
}

fn to_match(raw: RawResult) -> Option<SceneMatch> {
    let (id, title, is_adult) = match raw.anilist {
        RawAnilist::Info(info) => (info.id, info.title.and_then(best_title), info.is_adult),
        RawAnilist::Id(id) => (id, None, false),
    };
    Some(SceneMatch {
        media_id: MediaId::new(id)?,
        episode: raw.episode.and_then(episode_number),
        from_secs: raw.from,
        at_secs: raw.at.unwrap_or((raw.from + raw.to) / 2.0),
        to_secs: raw.to,
        similarity: raw.similarity as f32,
        preview_image_url: raw.image,
        title,
        is_adult,
        duration_secs: raw.duration,
    })
}

fn episode_number(episode: RawEpisode) -> Option<f64> {
    match episode {
        RawEpisode::Number(number) => Some(number),
        RawEpisode::Text(text) => text.trim().parse().ok(),
        RawEpisode::Other(value) => value
            .as_array()
            .and_then(|list| list.first())
            .and_then(|first| first.as_f64()),
    }
}

fn best_title(title: RawTitle) -> Option<String> {
    [title.english, title.romaji, title.native]
        .into_iter()
        .flatten()
        .map(|text| text.trim().to_string())
        .find(|text| !text.is_empty())
}
