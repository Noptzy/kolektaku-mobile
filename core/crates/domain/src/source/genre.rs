use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Genre {
    pub slug: String,
    pub name: String,
}

impl Genre {
    pub fn new(slug: impl Into<String>, name: impl Into<String>) -> Self {
        Self {
            slug: slug.into(),
            name: name.into(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_keeps_slug_and_name() {
        let genre = Genre::new("action", "Aksi");
        assert_eq!(
            (genre.slug.as_str(), genre.name.as_str()),
            ("action", "Aksi")
        );
    }
}
