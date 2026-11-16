use domain::translation::LanguageRoute;

use crate::http::HttpRequest;

pub const DEFAULT_ENDPOINT: &str = "https://translate.googleapis.com/translate_a/t";
const DETECT_SOURCE: &str = "auto";

pub fn build_request(endpoint: &str, lines: &[String], route: &LanguageRoute) -> HttpRequest {
    let source = route.from_code().unwrap_or(DETECT_SOURCE);
    let url = format!(
        "{endpoint}?client=gtx&sl={source}&tl={target}",
        target = route.target_code()
    );
    let fields: Vec<(&str, &str)> = lines.iter().map(|line| ("q", line.as_str())).collect();
    HttpRequest::post_form(url, &fields)
}

#[cfg(test)]
mod tests {
    use domain::settings::TranslationLanguage;

    use super::*;
    use crate::http::HttpMethod;

    fn lines() -> Vec<String> {
        vec!["Hello, world".into(), "Wait & see".into()]
    }

    #[test]
    fn it_posts_every_line_as_its_own_q_field() {
        let route = LanguageRoute::detecting(TranslationLanguage::Indonesian).unwrap();
        let request = build_request(DEFAULT_ENDPOINT, &lines(), &route);
        assert_eq!(request.method, HttpMethod::Post);
        assert_eq!(
            request.body.as_deref(),
            Some("q=Hello%2C+world&q=Wait+%26+see")
        );
    }

    #[test]
    fn an_unknown_source_asks_the_service_to_detect_it() {
        let route = LanguageRoute::detecting(TranslationLanguage::Indonesian).unwrap();
        let request = build_request(DEFAULT_ENDPOINT, &lines(), &route);
        assert_eq!(
            request.url,
            "https://translate.googleapis.com/translate_a/t?client=gtx&sl=auto&tl=id"
        );
    }

    #[test]
    fn a_known_source_is_named_in_the_address() {
        let route = LanguageRoute::new(Some("ja"), TranslationLanguage::English).unwrap();
        let request = build_request(DEFAULT_ENDPOINT, &lines(), &route);
        assert!(request.url.ends_with("sl=ja&tl=en"));
    }

    #[test]
    fn the_endpoint_can_be_replaced() {
        let route = LanguageRoute::detecting(TranslationLanguage::Chinese).unwrap();
        let request = build_request("https://mirror.test/t", &lines(), &route);
        assert_eq!(
            request.url,
            "https://mirror.test/t?client=gtx&sl=auto&tl=zh-CN"
        );
    }
}
