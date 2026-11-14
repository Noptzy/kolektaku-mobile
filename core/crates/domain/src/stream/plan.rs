use serde::{Deserialize, Serialize};

use super::StreamSource;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum StreamPlan {
    Direct {
        sources: Vec<StreamSource>,
        headers: Vec<(String, String)>,
    },
    NeedsWebView {
        url: String,
        script: String,
        allowed_host: String,
    },
}

impl StreamPlan {
    pub fn needs_web_view(&self) -> bool {
        matches!(self, Self::NeedsWebView { .. })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn web_plan() -> StreamPlan {
        StreamPlan::NeedsWebView {
            url: "https://x/ep/1".into(),
            script: "s".into(),
            allowed_host: "x".into(),
        }
    }

    #[test]
    fn only_the_web_view_variant_needs_a_web_view() {
        let direct = StreamPlan::Direct {
            sources: Vec::new(),
            headers: Vec::new(),
        };
        assert!(!direct.needs_web_view());
        assert!(web_plan().needs_web_view());
    }

    #[test]
    fn survives_a_json_round_trip() {
        let plan = web_plan();
        let json = serde_json::to_string(&plan).unwrap();
        assert_eq!(serde_json::from_str::<StreamPlan>(&json).unwrap(), plan);
    }
}
