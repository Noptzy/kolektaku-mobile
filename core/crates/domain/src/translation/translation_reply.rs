#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TranslationReply {
    pub lines: Vec<String>,
    pub detected_from: Option<String>,
}

impl TranslationReply {
    pub fn new(lines: Vec<String>, detected_from: Option<String>) -> Self {
        Self {
            lines,
            detected_from,
        }
    }

    pub fn answers(&self, asked: usize) -> bool {
        self.lines.len() == asked
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_reply_answers_only_when_the_counts_match() {
        let reply = TranslationReply::new(vec!["a".into(), "b".into()], None);
        assert!(reply.answers(2));
        assert!(!reply.answers(3));
        assert!(!reply.answers(1));
    }
}
