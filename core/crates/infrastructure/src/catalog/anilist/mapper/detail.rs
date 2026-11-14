use domain::media::{
    MediaDate, MediaDetail, MediaSummary, NextAiring, StudioRef, Trailer, TrailerSite,
};

use super::credits::{map_characters, map_staff};
use super::episodes::map_episodes;
use super::links::map_links;
use super::related::{map_recommendations, map_relations};
use super::summary::map_summary;
use crate::catalog::anilist::sanitize::sanitize_description;
use crate::catalog::anilist::schema::{RawDate, RawDetail, RawTrailer};

fn map_date(raw: Option<RawDate>) -> MediaDate {
    let date = raw.unwrap_or_default();
    MediaDate {
        year: date.year,
        month: date.month,
        day: date.day,
    }
}

fn map_trailer(raw: Option<RawTrailer>) -> Option<Trailer> {
    let trailer = raw?;
    let video_id = trailer.id.filter(|id| !id.is_empty())?;
    let site = match trailer.site?.as_str() {
        "youtube" => TrailerSite::Youtube,
        "dailymotion" => TrailerSite::Dailymotion,
        _ => return None,
    };
    Some(Trailer {
        site,
        video_id,
        thumbnail_url: trailer.thumbnail,
    })
}

pub fn map_detail(raw: RawDetail) -> MediaDetail {
    let total_episodes = raw.summary.episodes;
    let mal_id = raw.id_mal;
    MediaDetail {
        banner_url: raw.banner_image,
        description: sanitize_description(&raw.description.unwrap_or_default()),
        studios: raw
            .studios
            .and_then(|studios| studios.nodes)
            .unwrap_or_default()
            .into_iter()
            .map(|studio| StudioRef {
                id: studio.id,
                name: studio.name,
            })
            .collect(),
        source: raw.source,
        season: raw.season,
        start_date: map_date(raw.summary.start_date),
        end_date: map_date(raw.end_date),
        duration_minutes: raw.duration,
        site_url: raw.site_url,
        characters: map_characters(raw.characters),
        staff: map_staff(raw.staff),
        trailer: map_trailer(raw.trailer),
        relations: map_relations(raw.relations),
        recommendations: map_recommendations(raw.recommendations),
        next_airing: raw.next_airing_episode.map(|airing| NextAiring {
            episode: airing.episode,
            airing_at_secs: airing.airing_at,
        }),
        episodes: map_episodes(raw.streaming_episodes, total_episodes),
        mal_id,
        links: map_links(raw.external_links),
        summary: sharp_cover(map_summary(raw.summary)),
    }
}

fn sharp_cover(mut summary: MediaSummary) -> MediaSummary {
    if let Some(sharp) = summary.cover_hd_url.clone() {
        summary.cover_url = Some(sharp);
    }
    summary
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn streaming_episodes_in_the_reply_become_episode_titles_and_thumbnails() {
        let json = r#"{"id":5,"type":"ANIME","title":{"romaji":"X"},
            "streamingEpisodes":[
              {"title":"Episode 2 - Trainer Sakonji Urokodaki","thumbnail":"https://img.test/2.jpg","url":"u","site":"Crunchyroll"},
              {"title":"Episode 1 - Cruelty","thumbnail":"https://img.test/1.jpg"}]}"#;
        let detail = map_detail(serde_json::from_str(json).unwrap());
        assert_eq!(detail.episodes.len(), 2);
        assert_eq!(detail.episodes[0].number, 1.0);
        assert_eq!(detail.episodes[0].title, "Cruelty");
        assert_eq!(
            detail.episodes[1].thumbnail_url.as_deref(),
            Some("https://img.test/2.jpg")
        );
    }

    #[test]
    fn a_reply_without_streaming_episodes_has_an_empty_list() {
        let json = r#"{"id":5,"type":"MANGA","title":{"romaji":"X"},"streamingEpisodes":null}"#;
        let detail = map_detail(serde_json::from_str(json).unwrap());
        assert!(detail.episodes.is_empty());
    }
}
