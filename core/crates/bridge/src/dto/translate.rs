#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TextTranslationDto {
    pub texts: Vec<String>,
    pub translated: bool,
    pub failed: bool,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_dto_carries_the_texts_and_both_flags() {
        let dto = TextTranslationDto {
            texts: vec!["a".into()],
            translated: true,
            failed: false,
        };
        assert_eq!(dto.texts, vec!["a"]);
        assert!(dto.translated && !dto.failed);
    }
}
