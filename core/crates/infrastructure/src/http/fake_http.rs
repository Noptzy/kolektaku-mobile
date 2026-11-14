use std::collections::VecDeque;
use std::sync::Mutex;

use application::ports::BoxFuture;
use domain::error::SourceError;

use super::{HttpClient, HttpRequest, HttpResponse};

type Reply = Result<HttpResponse, SourceError>;
type Handler = Box<dyn Fn(&HttpRequest) -> Reply + Send + Sync>;

pub struct FakeHttp {
    handler: Handler,
    requests: Mutex<Vec<HttpRequest>>,
}

impl FakeHttp {
    pub fn replying(handler: impl Fn(&HttpRequest) -> Reply + Send + Sync + 'static) -> Self {
        Self {
            handler: Box::new(handler),
            requests: Mutex::new(Vec::new()),
        }
    }

    pub fn always(response: HttpResponse) -> Self {
        Self::replying(move |_| Ok(response.clone()))
    }

    pub fn scripted(replies: Vec<Reply>) -> Self {
        let queue = Mutex::new(VecDeque::from(replies));
        Self::replying(move |_| {
            queue
                .lock()
                .unwrap()
                .pop_front()
                .unwrap_or_else(|| Err(SourceError::Network("no scripted reply left".into())))
        })
    }

    pub fn requests(&self) -> Vec<HttpRequest> {
        self.requests.lock().unwrap().clone()
    }
}

impl HttpClient for FakeHttp {
    fn send(&self, request: HttpRequest) -> BoxFuture<'_, Reply> {
        Box::pin(async move {
            let reply = (self.handler)(&request);
            self.requests.lock().unwrap().push(request);
            reply
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn scripted_replies_come_back_in_order_then_run_out() {
        let http = FakeHttp::scripted(vec![
            Ok(HttpResponse::new(200, "one")),
            Ok(HttpResponse::new(500, "two")),
        ]);
        assert_eq!(http.send(HttpRequest::get("a")).await.unwrap().body, "one");
        assert_eq!(http.send(HttpRequest::get("b")).await.unwrap().status, 500);
        assert!(http.send(HttpRequest::get("c")).await.is_err());
        assert_eq!(http.requests().len(), 3);
    }

    #[tokio::test]
    async fn always_repeats_the_same_response() {
        let http = FakeHttp::always(HttpResponse::new(200, "same"));
        for _ in 0..2 {
            assert_eq!(http.send(HttpRequest::get("a")).await.unwrap().body, "same");
        }
    }
}
