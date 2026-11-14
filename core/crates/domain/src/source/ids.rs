use std::fmt;

use serde::{Deserialize, Serialize};

macro_rules! string_id {
    ($name:ident) => {
        #[derive(Debug, Clone, PartialEq, Eq, Hash, PartialOrd, Ord, Serialize, Deserialize)]
        #[serde(transparent)]
        pub struct $name(String);

        impl $name {
            pub fn new(value: impl Into<String>) -> Self {
                Self(value.into())
            }

            pub fn as_str(&self) -> &str {
                &self.0
            }
        }

        impl fmt::Display for $name {
            fn fmt(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str(&self.0)
            }
        }
    };
}

string_id!(SourceId);
string_id!(ItemId);

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ids_expose_their_text_and_display_it() {
        let id = SourceId::new("kuramanime");
        assert_eq!(id.as_str(), "kuramanime");
        assert_eq!(id.to_string(), "kuramanime");
    }

    #[test]
    fn ids_are_plain_strings_in_json() {
        assert_eq!(
            serde_json::to_string(&ItemId::new("5244/x")).unwrap(),
            "\"5244/x\""
        );
        assert_eq!(
            serde_json::from_str::<ItemId>("\"a\"").unwrap(),
            ItemId::new("a")
        );
    }
}
