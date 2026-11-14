use serde::de::DeserializeOwned;
use serde::{Deserialize, Deserializer};
use serde_json::Value;

pub fn lenient<'de, D, T>(deserializer: D) -> Result<Option<T>, D::Error>
where
    D: Deserializer<'de>,
    T: DeserializeOwned,
{
    let value = Value::deserialize(deserializer)?;
    Ok(serde_json::from_value(value).ok())
}

#[cfg(test)]
mod tests {
    use domain::media::MediaFormat;

    use super::*;

    #[derive(Deserialize)]
    struct Holder {
        #[serde(default, deserialize_with = "lenient")]
        format: Option<MediaFormat>,
    }

    fn read(json: &str) -> Option<MediaFormat> {
        serde_json::from_str::<Holder>(json).unwrap().format
    }

    #[test]
    fn known_values_are_read() {
        assert_eq!(read(r#"{"format":"MOVIE"}"#), Some(MediaFormat::Movie));
    }

    #[test]
    fn unknown_null_and_missing_values_become_none() {
        assert_eq!(read(r#"{"format":"HOLOGRAM"}"#), None);
        assert_eq!(read(r#"{"format":null}"#), None);
        assert_eq!(read("{}"), None);
        assert_eq!(read(r#"{"format":12}"#), None);
    }
}
