use thiserror::Error;

#[derive(Debug, Clone, PartialEq, Eq, Error)]
#[error("storage error: {0}")]
pub struct StorageError(pub String);

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn display_includes_the_detail() {
        assert_eq!(
            StorageError("disk full".into()).to_string(),
            "storage error: disk full"
        );
    }
}
