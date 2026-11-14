use application::streaming::Cue;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CueDto {
    pub start_ms: u64,
    pub end_ms: u64,
    pub text: String,
}

impl From<&Cue> for CueDto {
    fn from(cue: &Cue) -> Self {
        Self {
            start_ms: cue.start_ms,
            end_ms: cue.end_ms,
            text: cue.text.clone(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_cue_keeps_its_times_and_text() {
        let cue = Cue {
            start_ms: 1_000,
            end_ms: 2_500,
            text: "Halo".into(),
        };
        let dto = CueDto::from(&cue);
        assert_eq!(
            (dto.start_ms, dto.end_ms, dto.text.as_str()),
            (1_000, 2_500, "Halo")
        );
    }
}
