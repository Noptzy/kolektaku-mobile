use std::sync::Arc;

use domain::error::SourceError;
use serde_json::{Value, json};

use crate::http::{HttpClient, HttpRequest, HttpResponse};

pub struct GraphQl {
    http: Arc<dyn HttpClient>,
    endpoint: String,
}

impl GraphQl {
    pub fn new(http: Arc<dyn HttpClient>, endpoint: impl Into<String>) -> Self {
        Self {
            http,
            endpoint: endpoint.into(),
        }
    }

    pub async fn run(&self, query: &str, variables: Value) -> Result<Value, SourceError> {
        let body = json!({ "query": query, "variables": variables }).to_string();
        let response = self
            .http
            .send(HttpRequest::post_json(&self.endpoint, body))
            .await?;
        interpret(response)
    }
}

fn interpret(response: HttpResponse) -> Result<Value, SourceError> {
    let status = response.status;
    let Ok(mut body) = serde_json::from_str::<Value>(&response.body) else {
        return Err(match status {
            429 => rate_limited(&response),
            500.. => unavailable(status),
            _ => SourceError::MarkupChanged("catalog sent a response that is not JSON".into()),
        });
    };
    let first_error = body["errors"].get(0).cloned();
    let error_status = first_error
        .as_ref()
        .and_then(|error| error["status"].as_u64());
    let message = first_error
        .as_ref()
        .and_then(|error| error["message"].as_str())
        .map(str::to_string);
    if status == 404 || error_status == Some(404) {
        return Err(SourceError::NotFound(
            message.unwrap_or_else(|| "not found".into()),
        ));
    }
    if status == 429 || error_status == Some(429) {
        return Err(rate_limited(&response));
    }
    if status >= 500 {
        return Err(unavailable(status));
    }
    if first_error.is_some() || !response.is_success() {
        return Err(SourceError::MarkupChanged(
            message.unwrap_or_else(|| format!("catalog returned HTTP {status}")),
        ));
    }
    match body["data"].take() {
        Value::Null => Err(SourceError::MarkupChanged("catalog sent no data".into())),
        data => Ok(data),
    }
}

fn rate_limited(response: &HttpResponse) -> SourceError {
    SourceError::RateLimited {
        retry_after_secs: response.header_number("retry-after"),
    }
}

fn unavailable(status: u16) -> SourceError {
    SourceError::Unavailable(format!("catalog returned HTTP {status}"))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::http::FakeHttp;

    async fn run_with(response: HttpResponse) -> Result<Value, SourceError> {
        let http = Arc::new(FakeHttp::always(response));
        GraphQl::new(http, "https://graphql.test")
            .run("{ x }", json!({}))
            .await
    }

    #[tokio::test]
    async fn posts_the_query_and_variables_as_json() {
        let http = Arc::new(FakeHttp::always(HttpResponse::new(
            200,
            r#"{"data":{"x":1}}"#,
        )));
        let data = GraphQl::new(http.clone(), "https://graphql.test")
            .run("{ x }", json!({"a": 1}))
            .await
            .unwrap();
        assert_eq!(data, json!({"x": 1}));
        let request = &http.requests()[0];
        assert_eq!(request.url, "https://graphql.test");
        let sent: Value = serde_json::from_str(request.body.as_deref().unwrap()).unwrap();
        assert_eq!(sent, json!({"query": "{ x }", "variables": {"a": 1}}));
    }

    #[tokio::test]
    async fn a_graphql_404_is_not_found_even_with_data() {
        let body = r#"{"errors":[{"message":"Not Found.","status":404}],"data":{"Media":null}}"#;
        let error = run_with(HttpResponse::new(404, body)).await.unwrap_err();
        assert_eq!(error, SourceError::NotFound("Not Found.".into()));
    }

    #[tokio::test]
    async fn a_429_is_rate_limited_with_the_retry_after_hint() {
        let body = r#"{"errors":[{"message":"Too Many Requests.","status":429}]}"#;
        let response = HttpResponse::new(429, body).with_header("retry-after", "30");
        let error = run_with(response).await.unwrap_err();
        assert_eq!(
            error,
            SourceError::RateLimited {
                retry_after_secs: Some(30)
            }
        );
    }

    #[tokio::test]
    async fn a_non_json_429_is_still_rate_limited() {
        let error = run_with(HttpResponse::new(429, "slow down"))
            .await
            .unwrap_err();
        assert_eq!(
            error,
            SourceError::RateLimited {
                retry_after_secs: None
            }
        );
    }

    #[tokio::test]
    async fn server_errors_are_unavailable_json_or_not() {
        let html = run_with(HttpResponse::new(502, "<html>bad gateway</html>")).await;
        assert!(matches!(html, Err(SourceError::Unavailable(_))));
        let json_body =
            run_with(HttpResponse::new(503, r#"{"errors":[{"message":"down"}]}"#)).await;
        assert!(matches!(json_body, Err(SourceError::Unavailable(_))));
    }

    #[tokio::test]
    async fn other_graphql_errors_and_odd_statuses_mean_the_shape_changed() {
        let body = r#"{"errors":[{"message":"Variable \"$id\" got invalid value"}]}"#;
        let graphql = run_with(HttpResponse::new(200, body)).await;
        assert!(
            matches!(graphql, Err(SourceError::MarkupChanged(message)) if message.contains("invalid value"))
        );
        let status = run_with(HttpResponse::new(403, r#"{"data":{}}"#)).await;
        assert!(matches!(status, Err(SourceError::MarkupChanged(_))));
        let html = run_with(HttpResponse::new(200, "<html>")).await;
        assert!(matches!(html, Err(SourceError::MarkupChanged(_))));
    }

    #[tokio::test]
    async fn missing_or_null_data_means_the_shape_changed() {
        for body in [r#"{}"#, r#"{"data":null}"#] {
            let result = run_with(HttpResponse::new(200, body)).await;
            assert!(
                matches!(result, Err(SourceError::MarkupChanged(_))),
                "{body}"
            );
        }
    }

    #[tokio::test]
    async fn transport_failures_pass_through() {
        let http = Arc::new(FakeHttp::scripted(vec![Err(SourceError::Network(
            "offline".into(),
        ))]));
        let error = GraphQl::new(http, "https://graphql.test")
            .run("{ x }", json!({}))
            .await
            .unwrap_err();
        assert_eq!(error, SourceError::Network("offline".into()));
    }
}
