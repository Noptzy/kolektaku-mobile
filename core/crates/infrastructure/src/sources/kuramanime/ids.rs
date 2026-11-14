const ANIME_MARKER: &str = "/anime/";
const EPISODE_MARKER: &str = "/episode/";

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum IdShape {
    Anime,
    Episode,
}

fn leading_len(text: &str, accepts: impl Fn(char) -> bool) -> usize {
    text.find(|character: char| !accepts(character))
        .unwrap_or(text.len())
}

fn episode_suffix_len(text: &str) -> Option<usize> {
    let after_marker = text.strip_prefix(EPISODE_MARKER)?;
    let whole = leading_len(after_marker, |c| c.is_ascii_digit());
    if whole == 0 {
        return None;
    }
    let fraction = after_marker[whole..]
        .strip_prefix('.')
        .map(|after| leading_len(after, |c| c.is_ascii_digit()))
        .filter(|digits| *digits > 0)
        .map_or(0, |digits| 1 + digits);
    Some(EPISODE_MARKER.len() + whole + fraction)
}

fn read_path(text: &str) -> Option<(usize, IdShape)> {
    let digits = leading_len(text, |c| c.is_ascii_digit());
    if digits == 0 {
        return None;
    }
    let after_slash = text[digits..].strip_prefix('/')?;
    let slug = leading_len(after_slash, |c| c.is_ascii_alphanumeric() || c == '-');
    if slug == 0 {
        return None;
    }
    let anime_len = digits + 1 + slug;
    match episode_suffix_len(&text[anime_len..]) {
        Some(extra) => Some((anime_len + extra, IdShape::Episode)),
        None => Some((anime_len, IdShape::Anime)),
    }
}

pub fn provider_path(href: &str) -> Option<String> {
    href.match_indices(ANIME_MARKER)
        .find_map(|(index, marker)| {
            let rest = &href[index + marker.len()..];
            read_path(rest).map(|(length, _)| rest[..length].to_string())
        })
}

pub fn anime_path(href: &str) -> Option<String> {
    let path = provider_path(href)?;
    match path.rfind(EPISODE_MARKER) {
        Some(index) if episode_suffix_len(&path[index..]) == Some(path.len() - index) => {
            Some(path[..index].to_string())
        }
        _ => Some(path),
    }
}

pub fn id_shape(id: &str) -> Option<IdShape> {
    let (length, shape) = read_path(id)?;
    let slug_start = id.find('/')? + 1;
    let starts_alnum = id[slug_start..].starts_with(|c: char| c.is_ascii_alphanumeric());
    (length == id.len() && starts_alnum).then_some(shape)
}

pub fn is_genre_slug(slug: &str) -> bool {
    slug.starts_with(|c: char| c.is_ascii_alphanumeric())
        && slug.chars().all(|c| c.is_ascii_alphanumeric() || c == '-')
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn provider_path_finds_the_anime_and_episode_paths_inside_any_link() {
        assert_eq!(
            provider_path("/anime/50/one-piece").as_deref(),
            Some("50/one-piece")
        );
        assert_eq!(
            provider_path("https://v20.kuramanime.ing/anime/50/one-piece/episode/3?x=1").as_deref(),
            Some("50/one-piece/episode/3")
        );
        assert_eq!(
            provider_path("/anime/50/one-piece/episode/10.5").as_deref(),
            Some("50/one-piece/episode/10.5")
        );
        assert_eq!(provider_path("/anime/one-piece"), None);
        assert_eq!(provider_path("/manga/50/x"), None);
    }

    #[test]
    fn a_dangling_episode_marker_is_not_part_of_the_path() {
        assert_eq!(
            provider_path("/anime/50/x/episode/").as_deref(),
            Some("50/x")
        );
        assert_eq!(
            provider_path("/anime/50/x/episode/7.").as_deref(),
            Some("50/x/episode/7")
        );
    }

    #[test]
    fn anime_path_drops_the_episode_part() {
        assert_eq!(
            anime_path("/anime/50/one-piece-random/episode/1180").as_deref(),
            Some("50/one-piece-random")
        );
        assert_eq!(
            anime_path("/anime/99/finished-show").as_deref(),
            Some("99/finished-show")
        );
        assert_eq!(anime_path("/nothing"), None);
    }

    #[test]
    fn id_shape_accepts_only_exact_ids() {
        assert_eq!(id_shape("50/one-piece"), Some(IdShape::Anime));
        assert_eq!(id_shape("50/One-Piece/episode/3"), Some(IdShape::Episode));
        assert_eq!(id_shape("50/one-piece/episode/3.5"), Some(IdShape::Episode));
        for invalid in [
            "https://evil.example/a",
            "../admin",
            "50/-bad",
            "50/one-piece/",
            "50/one-piece/episode/x",
            "50/one piece",
            "",
        ] {
            assert_eq!(id_shape(invalid), None, "{invalid}");
        }
    }

    #[test]
    fn genre_slugs_are_alphanumeric_with_dashes() {
        assert!(is_genre_slug("slice-of-life"));
        assert!(is_genre_slug("Action"));
        assert!(!is_genre_slug("../admin"));
        assert!(!is_genre_slug("-x"));
        assert!(!is_genre_slug(""));
    }
}
