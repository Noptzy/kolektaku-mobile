#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HttpResponse {
    pub status: u16,
    pub url: String,
    pub body: String,
    pub headers: Vec<(String, String)>,
}

impl HttpResponse {
    pub fn new(status: u16, body: impl Into<String>) -> Self {
        Self {
            status,
            url: String::new(),
            body: body.into(),
            headers: Vec::new(),
        }
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

    pub fn header_number(&self, name: &str) -> Option<u64> {
        self.header(name)?.trim().parse().ok()
    }

    pub fn is_success(&self) -> bool {
        (200..300).contains(&self.status)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn headers_are_found_regardless_of_case() {
        let response = HttpResponse::new(200, "").with_header("X-RateLimit-Remaining", "80");
        assert_eq!(response.header("x-ratelimit-remaining"), Some("80"));
        assert_eq!(response.header_number("X-RATELIMIT-REMAINING"), Some(80));
    }

    #[test]
    fn a_header_that_is_not_a_number_reads_as_missing() {
        let response = HttpResponse::new(200, "").with_header("retry-after", "soon");
        assert_eq!(response.header_number("retry-after"), None);
        assert_eq!(response.header_number("absent"), None);
    }

    #[test]
    fn only_2xx_is_success() {
        assert!(HttpResponse::new(204, "").is_success());
        assert!(!HttpResponse::new(301, "").is_success());
        assert!(!HttpResponse::new(500, "").is_success());
    }
}
