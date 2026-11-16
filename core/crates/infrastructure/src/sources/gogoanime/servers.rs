use domain::stream::ServerVariant;
use scraper::Html;
use url::Url;

use crate::sources::support::selector;

const WRAPPER_HOSTS: [&str; 1] = ["gogoanime.me.uk"];
const EMBED_HOSTS: [&str; 2] = ["megaplay.buzz", "vidwish.live"];

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ServerChoice {
    pub id: String,
    pub label: String,
    pub wrapper: String,
    pub variant: ServerVariant,
    pub audio: &'static str,
}

fn host_is(url: &Url, known: &[&str]) -> bool {
    url.host_str().is_some_and(|host| {
        let host = host.to_lowercase();
        known
            .iter()
            .any(|name| host == *name || host.ends_with(&format!(".{name}")))
    })
}

pub fn decode_base64(text: &str) -> Option<String> {
    let mut bits = 0u32;
    let mut count = 0u32;
    let mut bytes = Vec::new();
    for symbol in text.trim().trim_end_matches('=').bytes() {
        let value = match symbol {
            b'A'..=b'Z' => symbol - b'A',
            b'a'..=b'z' => symbol - b'a' + 26,
            b'0'..=b'9' => symbol - b'0' + 52,
            b'+' | b'-' => 62,
            b'/' | b'_' => 63,
            _ => return None,
        };
        bits = (bits << 6) | u32::from(value);
        count += 6;
        if count >= 8 {
            count -= 8;
            bytes.push((bits >> count) as u8);
            bits &= (1 << count) - 1;
        }
    }
    String::from_utf8(bytes).ok()
}

fn source_of(markup: &str) -> Option<String> {
    let fragment = Html::parse_fragment(markup);
    fragment
        .select(&selector("iframe[src]"))
        .next()
        .and_then(|frame| frame.value().attr("src"))
        .map(|src| src.trim().to_string())
}

fn choice_of(address: &str, number: usize) -> Option<ServerChoice> {
    let url = Url::parse(address).ok()?;
    if url.scheme() != "https" || !host_is(&url, &WRAPPER_HOSTS) {
        return None;
    }
    let query = |name: &str| {
        url.query_pairs()
            .find(|(key, _)| key == name)
            .map(|(_, value)| value.to_string())
    };
    let kind = query("type").filter(|kind| kind.chars().all(|c| c.is_ascii_alphanumeric() || c == '-'))?;
    let (variant, audio, label) = match query("category").as_deref() {
        Some("dub") => (ServerVariant::Dub, "en", "Dub"),
        _ => (ServerVariant::Sub, "ja", "Sub"),
    };
    Some(ServerChoice {
        id: kind,
        label: format!("Server {number} · {label}"),
        wrapper: url.to_string(),
        variant,
        audio,
    })
}

pub fn server_choices(html: &str) -> Vec<ServerChoice> {
    let document = Html::parse_document(html);
    let mut addresses: Vec<String> = document
        .select(&selector("select.mirror option[value]"))
        .filter_map(|option| option.value().attr("value"))
        .filter(|value| !value.trim().is_empty())
        .filter_map(decode_base64)
        .filter_map(|markup| source_of(&markup))
        .collect();
    if addresses.is_empty() {
        addresses.extend(
            document
                .select(&selector("#pembed iframe[src]"))
                .filter_map(|frame| frame.value().attr("src"))
                .map(|src| src.trim().to_string()),
        );
    }
    let mut choices: Vec<ServerChoice> = Vec::new();
    for address in addresses {
        let number = choices.len() + 1;
        let Some(choice) = choice_of(&address, number) else {
            continue;
        };
        if choices.iter().all(|known| known.id != choice.id) {
            choices.push(choice);
        }
    }
    choices
}

pub fn embed_of(wrapper_html: &str) -> Option<(String, String)> {
    let address = source_of(wrapper_html)?;
    let url = Url::parse(&address).ok()?;
    if url.scheme() != "https" || !host_is(&url, &EMBED_HOSTS) {
        return None;
    }
    let host = url.host_str()?.to_lowercase();
    Some((url.to_string(), host))
}

#[cfg(test)]
mod tests {
    use super::*;

    const HD1: &str = "https://gogoanime.me.uk/newplayer.php?id=my-star-season-2-19256?ep=128473&type=hd-1&category=sub";

    fn page(addresses: &[&str]) -> String {
        let options: String = addresses
            .iter()
            .enumerate()
            .map(|(index, address)| {
                let markup = format!("<iframe src=\"{address}\" allowfullscreen></iframe>");
                format!("<option value=\"{}\">HD-{}</option>", encode(&markup), index + 1)
            })
            .collect();
        format!(
            "<select class=\"mirror\"><option value=\"\">Select Video Server</option>{options}</select>"
        )
    }

    fn encode(text: &str) -> String {
        const ALPHABET: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        let mut out = String::new();
        for chunk in text.as_bytes().chunks(3) {
            let value = chunk.iter().enumerate().fold(0u32, |sum, (index, byte)| sum | (u32::from(*byte) << (16 - 8 * index)));
            for index in 0..=chunk.len() {
                out.push(ALPHABET[((value >> (18 - 6 * index)) & 63) as usize] as char);
            }
            for _ in chunk.len()..3 {
                out.push('=');
            }
        }
        out
    }

    #[test]
    fn base64_is_decoded_with_or_without_padding() {
        assert_eq!(decode_base64("aGVsbG8=").as_deref(), Some("hello"));
        assert_eq!(decode_base64("aGVsbG8").as_deref(), Some("hello"));
        assert_eq!(decode_base64("").as_deref(), Some(""));
        assert_eq!(decode_base64("a*b"), None);
    }

    #[test]
    fn each_mirror_becomes_a_numbered_server_with_its_audio() {
        let hd2 = HD1.replace("hd-1", "hd-2");
        let choices = server_choices(&page(&[HD1, &hd2]));
        let ids: Vec<&str> = choices.iter().map(|choice| choice.id.as_str()).collect();
        assert_eq!(ids, ["hd-1", "hd-2"]);
        assert_eq!(choices[0].label, "Server 1 · Sub");
        assert_eq!(choices[1].label, "Server 2 · Sub");
        assert_eq!(choices[0].variant, ServerVariant::Sub);
        assert_eq!(choices[0].audio, "ja");
        assert_eq!(choices[0].wrapper, HD1);
    }

    #[test]
    fn a_dub_page_offers_dub_servers() {
        let dub = HD1.replace("category=sub", "category=dub");
        let choices = server_choices(&page(&[&dub]));
        assert_eq!(choices[0].variant, ServerVariant::Dub);
        assert_eq!(choices[0].audio, "en");
        assert_eq!(choices[0].label, "Server 1 · Dub");
    }

    #[test]
    fn a_page_without_mirrors_falls_back_to_the_shown_player() {
        let html = format!("<div id=\"pembed\"><iframe src=\"{HD1}\"></iframe></div>");
        assert_eq!(server_choices(&html).len(), 1);
    }

    #[test]
    fn a_player_on_an_unknown_host_or_without_https_is_never_offered() {
        let evil = HD1.replace("gogoanime.me.uk", "evil.example.test");
        let plain = HD1.replace("https://", "http://");
        let lookalike = HD1.replace("gogoanime.me.uk", "gogoanime.me.uk.evil.test");
        assert!(server_choices(&page(&[&evil, &plain, &lookalike])).is_empty());
    }

    #[test]
    fn a_repeated_server_is_listed_once() {
        assert_eq!(server_choices(&page(&[HD1, HD1])).len(), 1);
    }

    #[test]
    fn a_page_with_nothing_playable_gives_nothing() {
        assert!(server_choices("<html><body>nothing</body></html>").is_empty());
    }

    #[test]
    fn the_embed_is_read_from_the_wrapper_and_only_on_known_players() {
        let good = "<iframe src=\"https://megaplay.buzz/stream/s-2/128473/sub?autostart=true\"></iframe>";
        let (url, host) = embed_of(good).unwrap();
        assert_eq!(host, "megaplay.buzz");
        assert!(url.starts_with("https://megaplay.buzz/stream/s-2/128473/sub"));
        let other = good.replace("megaplay.buzz", "vidwish.live");
        assert_eq!(embed_of(&other).unwrap().1, "vidwish.live");
        assert!(embed_of("<iframe src=\"https://evil.example.test/x\"></iframe>").is_none());
        assert!(embed_of("<iframe src=\"http://megaplay.buzz/x\"></iframe>").is_none());
        assert!(embed_of("<p>no player</p>").is_none());
    }
}
