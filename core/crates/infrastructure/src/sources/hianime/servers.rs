use domain::stream::ServerVariant;
use url::Url;

use super::model::RawLinks;

const EMBED_HOSTS: [&str; 2] = ["zokoanime.video", "megaplay.buzz"];

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ServerChoice {
    pub id: String,
    pub label: String,
    pub url: String,
    pub host: String,
    pub variant: ServerVariant,
    pub audio: &'static str,
}

fn embed_host(address: &str) -> Option<String> {
    let url = Url::parse(address.trim()).ok()?;
    if url.scheme() != "https" {
        return None;
    }
    let host = url.host_str()?.to_lowercase();
    EMBED_HOSTS
        .iter()
        .any(|known| host == *known || host.ends_with(&format!(".{known}")))
        .then_some(host)
}

fn is_really_dubbed(address: &str, sub: &[String]) -> bool {
    let trimmed = address.trim();
    if sub.iter().any(|known| known.trim() == trimmed) {
        return false;
    }
    Url::parse(trimmed)
        .ok()
        .and_then(|url| {
            url.path_segments()
                .and_then(|mut segments| segments.next_back().map(str::to_lowercase))
        })
        .is_none_or(|last| last != "sub")
}

fn choices_for(
    kind: &str,
    label: &str,
    variant: ServerVariant,
    audio: &'static str,
    links: Option<Vec<String>>,
) -> Vec<ServerChoice> {
    links
        .unwrap_or_default()
        .into_iter()
        .enumerate()
        .filter_map(|(index, address)| {
            let host = embed_host(&address)?;
            let number = index + 1;
            Some(ServerChoice {
                id: format!("{kind}-{number}"),
                label: format!("Server {number} · {label}"),
                url: address.trim().to_string(),
                host,
                variant,
                audio,
            })
        })
        .collect()
}

pub fn server_choices(links: RawLinks) -> Vec<ServerChoice> {
    let sub = links.sub.clone().unwrap_or_default();
    let dub = links
        .dub
        .map(|all| all.into_iter().filter(|address| is_really_dubbed(address, &sub)).collect());
    let mut choices = choices_for("sub", "Sub", ServerVariant::Sub, "ja", links.sub);
    choices.extend(choices_for("dub", "Dub", ServerVariant::Dub, "en", dub));
    choices
}

#[cfg(test)]
mod tests {
    use super::*;

    fn links(sub: &[&str], dub: &[&str]) -> RawLinks {
        RawLinks {
            sub: Some(sub.iter().map(ToString::to_string).collect()),
            dub: Some(dub.iter().map(ToString::to_string).collect()),
        }
    }

    #[test]
    fn subs_come_first_then_dubs_each_numbered_by_position() {
        let choices = server_choices(links(
            &[
                "https://zokoanime.video/stream/mal/1/1/sub",
                "https://megaplay.buzz/stream/s-2/9/sub",
            ],
            &["https://zokoanime.video/stream/mal/1/1/dub"],
        ));
        let ids: Vec<&str> = choices.iter().map(|choice| choice.id.as_str()).collect();
        assert_eq!(ids, ["sub-1", "sub-2", "dub-1"]);
        assert_eq!(choices[0].label, "Server 1 · Sub");
        assert_eq!(choices[1].label, "Server 2 · Sub");
        assert_eq!(choices[2].label, "Server 1 · Dub");
        assert_eq!(choices[1].host, "megaplay.buzz");
        assert_eq!(choices[0].variant, ServerVariant::Sub);
        assert_eq!(choices[2].variant, ServerVariant::Dub);
        assert_eq!(choices[0].audio, "ja");
        assert_eq!(choices[2].audio, "en");
    }

    #[test]
    fn a_dub_that_only_points_at_the_sub_video_is_not_offered() {
        let choices = server_choices(links(
            &["https://zokoanime.video/stream/anime/9/sub?autostart=true"],
            &["https://zokoanime.video/stream/anime/9/sub?autostart=true"],
        ));
        let ids: Vec<&str> = choices.iter().map(|choice| choice.id.as_str()).collect();
        assert_eq!(ids, ["sub-1"]);
    }

    #[test]
    fn a_dub_whose_path_ends_in_sub_is_not_offered_either() {
        let choices = server_choices(links(
            &[],
            &[
                "https://zokoanime.video/stream/mal/1/1/sub",
                "https://zokoanime.video/stream/mal/1/1/dub?color=1",
            ],
        ));
        let ids: Vec<&str> = choices.iter().map(|choice| choice.id.as_str()).collect();
        assert_eq!(ids, ["dub-1"]);
    }

    #[test]
    fn a_host_outside_the_known_players_is_never_offered() {
        let choices = server_choices(links(
            &[
                "https://evil.example.test/stream/1",
                "https://zokoanime.video.evil.test/x",
                "http://zokoanime.video/x",
                "https://megaplay.buzz/stream/ok",
            ],
            &[],
        ));
        assert_eq!(choices.len(), 1);
        assert_eq!(choices[0].host, "megaplay.buzz");
        assert_eq!(choices[0].id, "sub-4");
    }

    #[test]
    fn a_subdomain_of_a_known_player_is_accepted() {
        let choices = server_choices(links(&["https://cdn.zokoanime.video/x"], &[]));
        assert_eq!(choices.len(), 1);
    }

    #[test]
    fn missing_lists_and_broken_addresses_give_nothing() {
        let none = RawLinks { sub: None, dub: None };
        assert!(server_choices(none).is_empty());
        assert!(server_choices(links(&["not a url", ""], &[])).is_empty());
    }

    #[test]
    fn the_address_is_trimmed_but_otherwise_kept() {
        let choices = server_choices(links(
            &["  https://zokoanime.video/stream/mal/1/1/sub?color=35d5bf  "],
            &[],
        ));
        assert_eq!(
            choices[0].url,
            "https://zokoanime.video/stream/mal/1/1/sub?color=35d5bf"
        );
    }
}
