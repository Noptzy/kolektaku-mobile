use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct MediaDate {
    pub year: Option<u16>,
    pub month: Option<u8>,
    pub day: Option<u8>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn default_has_no_parts() {
        assert_eq!(
            MediaDate::default(),
            MediaDate {
                year: None,
                month: None,
                day: None
            }
        );
    }
}
