use domain::media::ExternalLink;

use super::media::tag;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ExternalLinkDto {
    pub site: String,
    pub url: String,
    pub kind: String,
}

impl From<&ExternalLink> for ExternalLinkDto {
    fn from(link: &ExternalLink) -> Self {
        Self {
            site: link.site.clone(),
            url: link.url.clone(),
            kind: tag(&link.kind),
        }
    }
}

#[cfg(test)]
mod tests {
    use domain::media::LinkKind;

    use super::*;

    #[test]
    fn a_link_keeps_its_site_address_and_kind() {
        let link = ExternalLink {
            site: "Official Site".into(),
            url: "https://a.test/".into(),
            kind: LinkKind::Info,
        };
        let dto = ExternalLinkDto::from(&link);
        assert_eq!(dto.site, "Official Site");
        assert_eq!(dto.url, "https://a.test/");
        assert_eq!(dto.kind, "INFO");
    }

    #[test]
    fn a_social_link_names_its_kind() {
        let link = ExternalLink {
            site: "Twitter".into(),
            url: "https://twitter.com/a".into(),
            kind: LinkKind::Social,
        };
        assert_eq!(ExternalLinkDto::from(&link).kind, "SOCIAL");
    }
}
