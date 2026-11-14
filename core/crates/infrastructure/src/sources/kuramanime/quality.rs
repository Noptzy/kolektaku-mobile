use url::Url;

const ULTRA_HD_UNIT: u32 = 540;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Quality {
    pub value: u32,
    pub label: String,
}

fn digit_runs(text: &str) -> Vec<(usize, &str)> {
    let mut runs = Vec::new();
    let mut start = None;
    for (index, character) in text.char_indices() {
        match (character.is_ascii_digit(), start) {
            (true, None) => start = Some(index),
            (false, Some(from)) => {
                runs.push((from, &text[from..index]));
                start = None;
            }
            _ => {}
        }
    }
    if let Some(from) = start {
        runs.push((from, &text[from..]));
    }
    runs
}

fn resolution_in(text: &str) -> Option<u32> {
    digit_runs(text)
        .into_iter()
        .find(|(_, digits)| (3..=4).contains(&digits.len()))
        .and_then(|(_, digits)| digits.parse().ok())
}

fn ultra_hd_in(text: &str) -> Option<u32> {
    digit_runs(text).into_iter().find_map(|(from, digits)| {
        let after = &text[from + digits.len()..];
        let rest = after.strip_prefix(['k', 'K'])?;
        let ends_cleanly = !rest.starts_with(|c: char| c.is_ascii_digit());
        ends_cleanly.then(|| digits.parse().ok()).flatten()
    })
}

pub fn parse_quality(attributes: &[&str], url: &str) -> Option<Quality> {
    let scraped_label = attributes
        .iter()
        .map(|attribute| attribute.trim())
        .find(|attribute| !attribute.is_empty());
    let label_or = |fallback: String| match scraped_label {
        Some(label) if label.chars().any(|c| c.is_ascii_alphabetic()) => label.to_string(),
        _ => fallback,
    };
    let path = Url::parse(url)
        .map(|parsed| parsed.path().to_string())
        .unwrap_or_default();
    for candidate in attributes
        .iter()
        .copied()
        .chain(std::iter::once(path.as_str()))
    {
        if candidate.is_empty() {
            continue;
        }
        if let Some(value) = resolution_in(candidate).filter(|value| *value > 0) {
            return Some(Quality {
                value,
                label: label_or(format!("{value}p")),
            });
        }
        if let Some(k) = ultra_hd_in(candidate).filter(|k| *k > 0) {
            return Some(Quality {
                value: k * ULTRA_HD_UNIT,
                label: label_or(format!("{k}K")),
            });
        }
    }
    None
}

#[cfg(test)]
mod tests {
    use super::*;

    fn quality(attributes: &[&str], url: &str) -> Option<(u32, String)> {
        parse_quality(attributes, url).map(|found| (found.value, found.label))
    }

    #[test]
    fn a_numeric_attribute_is_the_height_and_gets_a_p_label() {
        assert_eq!(
            quality(&["720"], "https://c.test/a.mp4"),
            Some((720, "720p".into()))
        );
        assert_eq!(
            quality(&["", "1080"], "https://c.test/a.mp4"),
            Some((1080, "1080p".into()))
        );
    }

    #[test]
    fn a_textual_label_is_kept_as_the_display_name() {
        assert_eq!(
            quality(&["1080p"], "https://c.test/a.mp4"),
            Some((1080, "1080p".into()))
        );
        assert_eq!(
            quality(&["Full HD 1080"], "https://c.test/a.mp4"),
            Some((1080, "Full HD 1080".into()))
        );
    }

    #[test]
    fn ultra_hd_labels_scale_from_the_k_value() {
        assert_eq!(
            quality(&["4K"], "https://c.test/a.mp4"),
            Some((2160, "4K".into()))
        );
        assert_eq!(
            quality(&["2k"], "https://c.test/a.mp4"),
            Some((1080, "2k".into()))
        );
    }

    #[test]
    fn the_url_path_is_the_last_resort() {
        assert_eq!(
            quality(&[], "https://cdn.test/one-piece-480.mp4?token=1080"),
            Some((480, "480p".into()))
        );
        assert_eq!(
            quality(&[""], "https://cdn.test/video/anime-1440p.mp4"),
            Some((1440, "1440p".into()))
        );
    }

    #[test]
    fn numbers_of_the_wrong_length_do_not_count() {
        assert_eq!(quality(&["12"], "https://c.test/a.mp4"), None);
        assert_eq!(quality(&["10800"], "https://c.test/a.mp4"), None);
        assert_eq!(quality(&["4k2"], "https://c.test/a.mp4"), None);
        assert_eq!(quality(&[], "not a url"), None);
    }
}
