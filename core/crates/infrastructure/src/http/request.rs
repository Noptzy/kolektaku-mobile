#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HttpMethod {
    Get,
    Post,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HttpRequest {
    pub method: HttpMethod,
    pub url: String,
    pub headers: Vec<(String, String)>,
    pub body: Option<String>,
    pub bytes: Option<Vec<u8>>,
}

impl HttpRequest {
    pub fn get(url: impl Into<String>) -> Self {
        Self {
            method: HttpMethod::Get,
            url: url.into(),
            headers: Vec::new(),
            body: None,
            bytes: None,
        }
    }

    pub fn post_bytes(url: impl Into<String>, bytes: Vec<u8>, content_type: &str) -> Self {
        Self {
            method: HttpMethod::Post,
            url: url.into(),
            headers: Vec::new(),
            body: None,
            bytes: Some(bytes),
        }
        .with_header("content-type", content_type)
        .with_header("accept", "application/json")
    }

    pub fn post_json(url: impl Into<String>, body: impl Into<String>) -> Self {
        Self {
            method: HttpMethod::Post,
            url: url.into(),
            headers: Vec::new(),
            body: Some(body.into()),
            bytes: None,
        }
        .with_header("content-type", "application/json")
        .with_header("accept", "application/json")
    }

    pub fn post_form(url: impl Into<String>, fields: &[(&str, &str)]) -> Self {
        let body = url::form_urlencoded::Serializer::new(String::new())
            .extend_pairs(fields)
            .finish();
        Self {
            method: HttpMethod::Post,
            url: url.into(),
            headers: Vec::new(),
            body: Some(body),
            bytes: None,
        }
        .with_header("content-type", "application/x-www-form-urlencoded")
        .with_header("accept", "application/json")
    }

    pub fn with_header(mut self, name: &str, value: &str) -> Self {
        self.headers.push((name.to_lowercase(), value.to_string()));
        self
    }

    pub fn header(&self, name: &str) -> Option<&str> {
        let wanted = name.to_lowercase();
        self.headers
            .iter()
            .find(|(key, _)| *key == wanted)
            .map(|(_, value)| value.as_str())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn get_has_no_body_and_no_headers() {
        let request = HttpRequest::get("https://example.test/a");
        assert_eq!(request.method, HttpMethod::Get);
        assert_eq!(request.body, None);
        assert!(request.headers.is_empty());
    }

    #[test]
    fn post_json_declares_json_both_ways() {
        let request = HttpRequest::post_json("https://example.test/q", "{}");
        assert_eq!(request.method, HttpMethod::Post);
        assert_eq!(request.body.as_deref(), Some("{}"));
        assert_eq!(request.header("Content-Type"), Some("application/json"));
        assert_eq!(request.header("accept"), Some("application/json"));
    }

    #[test]
    fn post_bytes_carries_the_raw_body_and_its_type() {
        let request =
            HttpRequest::post_bytes("https://example.test/s", vec![1, 2, 3], "image/jpeg");
        assert_eq!(request.method, HttpMethod::Post);
        assert_eq!(request.bytes.as_deref(), Some(&[1u8, 2, 3][..]));
        assert_eq!(request.body, None);
        assert_eq!(request.header("content-type"), Some("image/jpeg"));
    }

    #[test]
    fn post_form_encodes_repeated_fields_in_order() {
        let request = HttpRequest::post_form(
            "https://example.test/f",
            &[("q", "a b"), ("q", "c&d=e"), ("q", "é<i>")],
        );
        assert_eq!(request.method, HttpMethod::Post);
        assert_eq!(
            request.body.as_deref(),
            Some("q=a+b&q=c%26d%3De&q=%C3%A9%3Ci%3E")
        );
        assert_eq!(
            request.header("content-type"),
            Some("application/x-www-form-urlencoded")
        );
        assert_eq!(request.bytes, None);
    }

    #[test]
    fn post_form_without_fields_has_an_empty_body() {
        let request = HttpRequest::post_form("https://example.test/f", &[]);
        assert_eq!(request.body.as_deref(), Some(""));
    }

    #[test]
    fn header_lookup_ignores_case() {
        let request =
            HttpRequest::get("https://example.test").with_header("Referer", "https://a.test");
        assert_eq!(request.header("REFERER"), Some("https://a.test"));
        assert_eq!(request.header("origin"), None);
    }
}
