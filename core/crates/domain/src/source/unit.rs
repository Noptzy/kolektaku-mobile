use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Unit {
    pub id: String,
    pub number: f64,
    pub label: String,
}

impl Unit {
    pub fn new(id: impl Into<String>, number: f64, label: impl Into<String>) -> Self {
        Self {
            id: id.into(),
            number,
            label: label.into(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn decimal_numbers_are_kept() {
        let unit = Unit::new("c-10-5", 10.5, "Chapter 10.5");
        assert_eq!(unit.number, 10.5);
    }
}
