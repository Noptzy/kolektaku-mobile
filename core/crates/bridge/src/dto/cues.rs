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

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CuePlanDto {
    pub cues: Vec<CueDto>,
    pub translated: bool,
    pub failed: bool,
    pub retry_at_secs: Option<u64>,
}

impl CuePlanDto {
    pub fn plain(cues: &[Cue]) -> Self {
        Self {
            cues: cues.iter().map(CueDto::from).collect(),
            translated: false,
            failed: false,
            retry_at_secs: None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_plain_plan_is_untranslated_and_has_no_retry_time() {
        let cue = Cue {
            start_ms: 1,
            end_ms: 2,
            text: "a".into(),
        };
        let plan = CuePlanDto::plain(&[cue]);
        assert_eq!(plan.cues.len(), 1);
        assert!(!plan.translated && !plan.failed);
        assert_eq!(plan.retry_at_secs, None);
    }

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
