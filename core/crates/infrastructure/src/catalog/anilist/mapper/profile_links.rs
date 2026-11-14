use domain::media::{ExternalLink, LinkKind};

use crate::catalog::anilist::sanitize::extract_urls;

const MAX_LINKS: usize = 6;

const KNOWN: [(&[&str], &str); 7] = [
    (&["twitter.com", "x.com"], "Twitter"),
    (&["instagram.com"], "Instagram"),
    (&["facebook.com", "fb.com"], "Facebook"),
    (&["youtube.com", "youtu.be"], "YouTube"),
    (&["tiktok.com"], "TikTok"),
    (&["twitch.tv"], "Twitch"),
    (&["pixiv.net"], "Pixiv"),
];

fn secure(url: &str) -> Option<String> {
    let trimmed = url.trim();
    if trimmed.starts_with("https://") {
        return Some(trimmed.to_string());
    }
    trimmed
        .strip_prefix("http://")
        .map(|rest| format!("https://{rest}"))
}

fn host_of(url: &str) -> Option<String> {
    let rest = url.strip_prefix("https://")?;
    let host = rest.split(['/', '?', '#']).next()?;
    let host = host.rsplit('@').next()?.split(':').next()?;
    let host = host.trim_start_matches("www.").to_lowercase();
    (host.contains('.') && !host.is_empty()).then_some(host)
}

fn on_domain(host: &str, domain: &str) -> bool {
    host == domain || host.ends_with(&format!(".{domain}"))
}

fn classify(url: String) -> Option<ExternalLink> {
    let host = host_of(&url)?;
    let known = KNOWN
        .iter()
        .find(|(domains, _)| domains.iter().any(|domain| on_domain(&host, domain)));
    Some(match known {
        Some((_, site)) => ExternalLink {
            site: (*site).to_string(),
            url,
            kind: LinkKind::Social,
        },
        None => ExternalLink {
            site: host,
            url,
            kind: LinkKind::Info,
        },
    })
}

pub fn profile_links(site_url: Option<&str>, description_html: &str) -> Vec<ExternalLink> {
    let mut links: Vec<ExternalLink> = Vec::new();
    let anilist = site_url.and_then(secure).map(|url| ExternalLink {
        site: "AniList".into(),
        url,
        kind: LinkKind::Info,
    });
    let urls = extract_urls(description_html);
    let from_text = urls
        .iter()
        .filter_map(|url| secure(url))
        .filter_map(classify);
    for link in anilist.into_iter().chain(from_text) {
        if !links.iter().any(|known| known.url == link.url) {
            links.push(link);
        }
    }
    links.sort_by_key(|link| (link.kind == LinkKind::Info, link.site != "AniList"));
    links.truncate(MAX_LINKS);
    links
}

#[cfg(test)]
mod tests {
    use super::*;

    fn description(urls: &[&str]) -> String {
        urls.iter()
            .map(|url| format!("<a href=\"{url}\">x</a>"))
            .collect()
    }

    #[test]
    fn social_sites_are_named_and_marked_social() {
        let links = profile_links(
            None,
            &description(&[
                "https://twitter.com/akutami",
                "https://www.instagram.com/p/x",
                "https://youtu.be/abc",
                "https://m.facebook.com/a",
            ]),
        );
        let sites: Vec<&str> = links.iter().map(|link| link.site.as_str()).collect();
        assert_eq!(sites, ["Twitter", "Instagram", "YouTube", "Facebook"]);
        assert!(links.iter().all(|link| link.kind == LinkKind::Social));
    }

    #[test]
    fn x_dot_com_counts_as_twitter() {
        let links = profile_links(None, &description(&["https://x.com/a"]));
        assert_eq!(links[0].site, "Twitter");
    }

    #[test]
    fn an_unknown_site_is_shown_by_its_host_as_information() {
        let links = profile_links(None, &description(&["http://www.example.co.jp/blog?x=1"]));
        assert_eq!(links[0].site, "example.co.jp");
        assert_eq!(links[0].url, "https://www.example.co.jp/blog?x=1");
        assert_eq!(links[0].kind, LinkKind::Info);
    }

    #[test]
    fn a_lookalike_host_is_not_taken_for_a_social_site() {
        let links = profile_links(None, &description(&["https://nottwitter.com/a"]));
        assert_eq!(links[0].kind, LinkKind::Info);
        assert_eq!(links[0].site, "nottwitter.com");
    }

    #[test]
    fn the_catalog_page_comes_with_the_others_and_social_ones_lead() {
        let links = profile_links(
            Some("https://anilist.co/staff/1"),
            &description(&["https://example.test/a", "https://twitter.com/a"]),
        );
        let sites: Vec<&str> = links.iter().map(|link| link.site.as_str()).collect();
        assert_eq!(sites, ["Twitter", "AniList", "example.test"]);
    }

    #[test]
    fn unsafe_or_broken_addresses_are_dropped_and_duplicates_merged() {
        let links = profile_links(
            Some("https://anilist.co/staff/1"),
            &description(&[
                "javascript:evil()",
                "ftp://files.test/x",
                "https://anilist.co/staff/1",
                "https://",
            ]),
        );
        assert_eq!(links.len(), 1);
        assert_eq!(links[0].site, "AniList");
    }

    #[test]
    fn at_most_six_links_are_kept() {
        let urls: Vec<String> = (0..10).map(|i| format!("https://s{i}.test/a")).collect();
        let refs: Vec<&str> = urls.iter().map(String::as_str).collect();
        assert_eq!(profile_links(None, &description(&refs)).len(), MAX_LINKS);
    }
}
