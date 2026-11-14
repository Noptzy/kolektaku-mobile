use domain::media::EpisodeInfo;

use crate::catalog::anilist::schema::RawStreamingEpisode;

const PREFIXES: [&str; 3] = ["episode ", "ep. ", "ep "];
const SEPARATORS: [char; 4] = ['-', ':', '\u{2013}', '\u{2014}'];

pub fn parse_episode_title(raw: &str) -> Option<(f64, String)> {
    let text = raw.trim();
    let lowered = text.to_lowercase();
    let prefix = PREFIXES
        .iter()
        .find(|prefix| lowered.starts_with(**prefix))?;
    let rest = text[prefix.len()..].trim_start();
    let end = rest
        .find(|letter: char| !(letter.is_ascii_digit() || letter == '.'))
        .unwrap_or(rest.len());
    let number: f64 = rest[..end].trim_end_matches('.').parse().ok()?;
    let title = rest[end..].trim().trim_start_matches(SEPARATORS).trim();
    Some((number, title.to_string()))
}

fn continues_from_earlier_seasons(episodes: &[EpisodeInfo], total: Option<u32>) -> Option<f64> {
    let total = total? as usize;
    let first = episodes.first()?.number;
    let whole = episodes.iter().all(|item| item.number.fract() == 0.0);
    let steady = episodes
        .windows(2)
        .all(|pair| pair[1].number - pair[0].number == 1.0);
    (first > 1.0 && whole && steady && episodes.len() == total).then_some(first - 1.0)
}

fn belongs_to_another_season(episodes: &[EpisodeInfo], total: Option<u32>) -> bool {
    let Some(total) = total else {
        return false;
    };
    episodes.iter().any(|item| item.number > f64::from(total))
}

pub fn map_episodes(raw: Option<Vec<RawStreamingEpisode>>, total: Option<u32>) -> Vec<EpisodeInfo> {
    let mut episodes: Vec<EpisodeInfo> = Vec::new();
    for item in raw.unwrap_or_default() {
        let Some((number, title)) = item.title.as_deref().and_then(parse_episode_title) else {
            continue;
        };
        let thumbnail = item.thumbnail.filter(|url| !url.is_empty());
        if title.is_empty() && thumbnail.is_none() {
            continue;
        }
        if episodes.iter().any(|known| known.number == number) {
            continue;
        }
        episodes.push(EpisodeInfo {
            number,
            title,
            thumbnail_url: thumbnail,
        });
    }
    episodes.sort_by(|a, b| a.number.total_cmp(&b.number));
    if let Some(offset) = continues_from_earlier_seasons(&episodes, total) {
        for item in &mut episodes {
            item.number -= offset;
        }
    }
    if belongs_to_another_season(&episodes, total) {
        episodes.clear();
    }
    episodes
}
