use crate::http::{HttpMethod, HttpRequest};

const LIST_TTL_SECS: u64 = 30 * 60;
const DETAIL_TTL_SECS: u64 = 60 * 60;
const DETAIL_MARK: &str = "Media(id: $id";

pub fn catalog_ttl(request: &HttpRequest) -> Option<u64> {
    if request.method != HttpMethod::Post {
        return None;
    }
    let body = request.body.as_deref()?;
    Some(if body.contains(DETAIL_MARK) {
        DETAIL_TTL_SECS
    } else {
        LIST_TTL_SECS
    })
}

#[cfg(test)]
mod tests {
    use serde_json::json;

    use super::*;
    use crate::catalog::anilist::queries::{detail_query, list_query};

    fn post(query: String) -> HttpRequest {
        HttpRequest::post_json(
            "https://graphql.test",
            json!({ "query": query, "variables": {} }).to_string(),
        )
    }

    #[test]
    fn lists_are_kept_for_half_an_hour() {
        assert_eq!(catalog_ttl(&post(list_query(false))), Some(LIST_TTL_SECS));
    }

    #[test]
    fn a_detail_page_is_kept_for_an_hour() {
        assert_eq!(catalog_ttl(&post(detail_query())), Some(DETAIL_TTL_SECS));
    }

    #[test]
    fn plain_page_requests_are_never_cached() {
        assert_eq!(catalog_ttl(&HttpRequest::get("https://x.test")), None);
    }

    #[test]
    fn a_post_without_a_body_is_not_cached() {
        let mut request = HttpRequest::get("https://x.test");
        request.method = HttpMethod::Post;
        assert_eq!(catalog_ttl(&request), None);
    }
}
