use domain::media::MediaRef;
use serde::Serialize;
use serde::de::DeserializeOwned;

pub fn json_error(error: serde_json::Error) -> rusqlite::Error {
    rusqlite::Error::ToSqlConversionFailure(Box::new(error))
}

pub fn media_key(media: &MediaRef) -> rusqlite::Result<String> {
    serde_json::to_string(media).map_err(json_error)
}

pub fn encode<T: Serialize>(value: &T) -> rusqlite::Result<String> {
    serde_json::to_string(value).map_err(json_error)
}

pub fn decode_all<T: DeserializeOwned>(rows: Vec<String>) -> Vec<T> {
    rows.into_iter()
        .filter_map(|text| serde_json::from_str(&text).ok())
        .collect()
}

#[cfg(test)]
mod tests {
    use domain::media::MediaId;

    use super::*;

    #[test]
    fn the_same_reference_always_gives_the_same_key() {
        let media = MediaRef::catalog(MediaId::new(7).unwrap());
        assert_eq!(media_key(&media).unwrap(), media_key(&media).unwrap());
        let other = MediaRef::catalog(MediaId::new(8).unwrap());
        assert_ne!(media_key(&media).unwrap(), media_key(&other).unwrap());
    }

    #[test]
    fn a_broken_row_is_skipped_without_hurting_its_neighbours() {
        let rows = vec!["5".to_string(), "not json".to_string(), "6".to_string()];
        let numbers: Vec<u32> = decode_all(rows);
        assert_eq!(numbers, vec![5, 6]);
    }

    #[test]
    fn encoding_round_trips() {
        let text = encode(&vec![1, 2]).unwrap();
        let back: Vec<u32> = serde_json::from_str(&text).unwrap();
        assert_eq!(back, vec![1, 2]);
    }
}
