use domain::error::SourceError;
use domain::stream::EpisodeServer;
use scraper::Html;

use crate::sources::support::selector;

const PREFERRED_SERVER: &str = "kuramadrive";

pub fn parse_episode_servers(html: &str) -> Result<Vec<EpisodeServer>, SourceError> {
    let document = Html::parse_document(html);
    let mut servers: Vec<EpisodeServer> = document
        .select(&selector("#changeServer option"))
        .filter_map(|option| {
            let id = option.value().attr("value")?.trim().to_string();
            let label = option.text().collect::<String>().trim().to_string();
            (!id.is_empty() && !label.is_empty()).then(|| EpisodeServer::new(id, label))
        })
        .collect();
    if servers.is_empty() {
        return Err(SourceError::MarkupChanged(
            "episode servers were not found".into(),
        ));
    }
    servers.sort_by_key(|server| server.id != PREFERRED_SERVER);
    Ok(servers)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::fixtures;

    #[test]
    fn parses_the_available_servers() {
        let servers = parse_episode_servers(&fixtures::kuramanime("episode.html")).unwrap();
        assert_eq!(
            servers,
            vec![
                EpisodeServer::new("kuramadrive", "KuramaDrive"),
                EpisodeServer::new("mega", "Mega"),
                EpisodeServer::new("filemoon", "Filemoon"),
            ]
        );
    }

    #[test]
    fn the_sites_own_player_always_comes_first() {
        let html = r#"<select id="changeServer"><option value="mega">Mega</option>
            <option value="kuramadrive">KuramaDrive</option><option value="doodstream">Dood</option></select>"#;
        let ids: Vec<String> = parse_episode_servers(html)
            .unwrap()
            .into_iter()
            .map(|server| server.id)
            .collect();
        assert_eq!(ids, vec!["kuramadrive", "mega", "doodstream"]);
    }

    #[test]
    fn options_without_a_value_or_a_label_are_skipped() {
        let html = r#"<select id="changeServer"><option value="">Pilih</option><option value="x"> </option><option value="ok">Ok</option></select>"#;
        assert_eq!(
            parse_episode_servers(html).unwrap(),
            vec![EpisodeServer::new("ok", "Ok")]
        );
    }

    #[test]
    fn a_page_without_the_selector_is_a_markup_change() {
        assert!(matches!(
            parse_episode_servers("<main></main>"),
            Err(SourceError::MarkupChanged(_))
        ));
    }
}
