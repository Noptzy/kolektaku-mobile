use domain::media::{ExternalLink, LinkKind};

use crate::catalog::anilist::schema::RawExternalLink;

const MAX_LINKS: usize = 8;
const SOCIAL_ORDER: [&str; 5] = ["twitter", "x", "instagram", "facebook", "tiktok"];

fn secure(url: &str) -> Option<String> {
    let trimmed = url.trim();
    if trimmed.starts_with("https://") {
        return Some(trimmed.to_string());
    }
    trimmed
        .strip_prefix("http://")
        .map(|rest| format!("https://{rest}"))
}

fn kind_of(raw: &str) -> Option<LinkKind> {
    match raw {
        "INFO" => Some(LinkKind::Info),
        "SOCIAL" => Some(LinkKind::Social),
        _ => None,
    }
}

fn rank(link: &ExternalLink) -> (u8, usize) {
    if link.kind == LinkKind::Info {
        return (0, 0);
    }
    let site = link.site.to_lowercase();
    let place = SOCIAL_ORDER
        .iter()
        .position(|known| *known == site)
        .unwrap_or(SOCIAL_ORDER.len());
    (1, place)
}

pub fn map_links(raw: Option<Vec<RawExternalLink>>) -> Vec<ExternalLink> {
    let mut links: Vec<ExternalLink> = Vec::new();
    for item in raw.unwrap_or_default() {
        if item.is_disabled == Some(true) {
            continue;
        }
        let (Some(site), Some(url), Some(kind)) = (
            item.site.filter(|site| !site.trim().is_empty()),
            item.url.as_deref().and_then(secure),
            item.kind.as_deref().and_then(kind_of),
        ) else {
            continue;
        };
        if links.iter().any(|known| known.url == url) {
            continue;
        }
        links.push(ExternalLink {
            site: site.trim().to_string(),
            url,
            kind,
        });
    }
    links.sort_by_key(rank);
    links.truncate(MAX_LINKS);
    links
}

#[cfg(test)]
mod tests {
    use super::*;

    fn raw(site: &str, url: &str, kind: &str) -> RawExternalLink {
        RawExternalLink {
            site: Some(site.into()),
            url: Some(url.into()),
            kind: Some(kind.into()),
            is_disabled: None,
        }
    }

    fn sites(links: &[ExternalLink]) -> Vec<&str> {
        links.iter().map(|link| link.site.as_str()).collect()
    }

    #[test]
    fn only_information_and_social_links_are_kept() {
        let links = map_links(Some(vec![
            raw("Official Site", "https://a.test/", "INFO"),
            raw("Crunchyroll", "https://c.test/", "STREAMING"),
            raw("Twitter", "https://twitter.com/x", "SOCIAL"),
            raw("Odd", "https://o.test/", "SOMETHING_NEW"),
        ]));
        assert_eq!(sites(&links), vec!["Official Site", "Twitter"]);
    }

    #[test]
    fn the_official_site_comes_first_then_social_in_a_known_order() {
        let links = map_links(Some(vec![
            raw("TikTok", "https://tiktok.com/@a", "SOCIAL"),
            raw("Instagram", "https://instagram.com/a", "SOCIAL"),
            raw("Official Site", "https://a.test/", "INFO"),
            raw("Twitter", "https://twitter.com/a", "SOCIAL"),
            raw("Mastodon", "https://m.test/a", "SOCIAL"),
        ]));
        assert_eq!(
            sites(&links),
            vec![
                "Official Site",
                "Twitter",
                "Instagram",
                "TikTok",
                "Mastodon"
            ]
        );
    }

    #[test]
    fn plain_http_addresses_are_upgraded_and_other_schemes_dropped() {
        let links = map_links(Some(vec![
            raw("Official Site", "http://a.test/season2/", "INFO"),
            raw("Weird", "javascript:alert(1)", "INFO"),
            raw("File", "file:///etc/passwd", "INFO"),
            raw("Relative", "/path", "INFO"),
        ]));
        assert_eq!(links.len(), 1);
        assert_eq!(links[0].url, "https://a.test/season2/");
    }

    #[test]
    fn disabled_blank_and_incomplete_links_are_skipped() {
        let mut disabled = raw("Dead", "https://d.test/", "INFO");
        disabled.is_disabled = Some(true);
        let links = map_links(Some(vec![
            disabled,
            raw("  ", "https://b.test/", "INFO"),
            RawExternalLink {
                site: Some("NoUrl".into()),
                url: None,
                kind: Some("INFO".into()),
                is_disabled: None,
            },
            RawExternalLink {
                site: Some("NoKind".into()),
                url: Some("https://k.test/".into()),
                kind: None,
                is_disabled: None,
            },
        ]));
        assert!(links.is_empty());
    }

    #[test]
    fn the_same_address_is_listed_once() {
        let links = map_links(Some(vec![
            raw("Twitter", "https://twitter.com/a", "SOCIAL"),
            raw("X", "http://twitter.com/a", "SOCIAL"),
        ]));
        assert_eq!(links.len(), 1);
    }

    #[test]
    fn the_list_is_capped() {
        let many: Vec<RawExternalLink> = (0..20)
            .map(|index| {
                raw(
                    &format!("S{index}"),
                    &format!("https://s{index}.test/"),
                    "SOCIAL",
                )
            })
            .collect();
        assert_eq!(map_links(Some(many)).len(), MAX_LINKS);
    }

    #[test]
    fn nothing_listed_is_an_empty_list() {
        assert!(map_links(None).is_empty());
        assert!(map_links(Some(Vec::new())).is_empty());
    }
}
