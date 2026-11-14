use domain::error::SourceError;
use serde::de::DeserializeOwned;

pub fn parse_json<T: DeserializeOwned>(body: &str, what: &str) -> Result<T, SourceError> {
    serde_json::from_str(body)
        .map_err(|error| SourceError::MarkupChanged(format!("{what} data is invalid: {error}")))
}

#[cfg(test)]
mod tests {
    use serde::Deserialize;

    use super::*;

    #[derive(Debug, Deserialize)]
    struct Probe {
        value: u32,
    }

    #[test]
    fn valid_json_is_read() {
        let probe: Probe = parse_json(r#"{"value":3}"#, "probe").unwrap();
        assert_eq!(probe.value, 3);
    }

    #[test]
    fn anything_else_is_a_markup_change_naming_what_was_read() {
        for body in ["", "<main>redesigned</main>", r#"{"other":1}"#, "[]"] {
            let error = parse_json::<Probe>(body, "probe").unwrap_err();
            assert!(
                matches!(&error, SourceError::MarkupChanged(message) if message.contains("probe")),
                "{body:?}"
            );
        }
    }
}
