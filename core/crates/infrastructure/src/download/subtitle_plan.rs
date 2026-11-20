use domain::download::DownloadSubtitles;
use domain::settings::TranslationLanguage;
use domain::stream::{SubtitleTrack, SubtitleVariant};
use domain::translation::speaks_the_same;

#[derive(Debug, Clone, PartialEq)]
pub struct SubtitlePlan {
    pub track: SubtitleTrack,
    pub translate_to: Option<TranslationLanguage>,
}

const NAMES: [(&str, &str); 12] = [
    ("id", "Indonesia"),
    ("en", "Inggris"),
    ("ms", "Melayu"),
    ("ja", "Jepang"),
    ("ko", "Korea"),
    ("zh", "Mandarin"),
    ("ar", "Arab"),
    ("th", "Thai"),
    ("vi", "Vietnam"),
    ("es", "Spanyol"),
    ("pt", "Portugis"),
    ("fr", "Prancis"),
];

pub fn language_name(code: Option<&str>, fallback: &str) -> String {
    code.and_then(|code| NAMES.iter().find(|(short, _)| speaks_the_same(short, code)))
        .map_or_else(|| fallback.to_string(), |(_, name)| name.to_string())
}

fn full(tracks: &[SubtitleTrack]) -> impl Iterator<Item = &SubtitleTrack> {
    tracks
        .iter()
        .filter(|track| track.variant == SubtitleVariant::Full)
}

fn speaks(track: &SubtitleTrack, code: &str) -> bool {
    track
        .language
        .as_deref()
        .is_some_and(|language| speaks_the_same(language, code))
}

fn original_choice(tracks: &[SubtitleTrack]) -> Option<&SubtitleTrack> {
    full(tracks)
        .find(|track| speaks(track, "en"))
        .or_else(|| full(tracks).find(|track| track.is_default))
        .or_else(|| full(tracks).next())
        .or_else(|| tracks.first())
}

pub fn plan_subtitles(
    tracks: &[SubtitleTrack],
    mode: DownloadSubtitles,
    target: TranslationLanguage,
) -> Option<SubtitlePlan> {
    let code = target.code();
    match (mode, code) {
        (DownloadSubtitles::Off, _) => None,
        (DownloadSubtitles::Translated, Some(code)) => {
            if let Some(own) = full(tracks).find(|track| speaks(track, code)) {
                return Some(SubtitlePlan {
                    track: own.clone(),
                    translate_to: None,
                });
            }
            let track = original_choice(tracks)?.clone();
            Some(SubtitlePlan {
                track,
                translate_to: Some(target),
            })
        }
        _ => original_choice(tracks).map(|track| SubtitlePlan {
            track: track.clone(),
            translate_to: None,
        }),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn track(label: &str, language: &str, variant: SubtitleVariant) -> SubtitleTrack {
        SubtitleTrack {
            label: label.into(),
            language: Some(language.into()),
            variant,
            url: format!("https://subs.test/{label}.vtt"),
            is_default: false,
        }
    }

    fn tracks() -> Vec<SubtitleTrack> {
        vec![
            track("English - Forced", "en", SubtitleVariant::Forced),
            track("Arabic", "ar", SubtitleVariant::Full),
            track("English", "en", SubtitleVariant::Full),
        ]
    }

    #[test]
    fn a_human_made_track_in_the_target_language_is_used_as_it_is() {
        let mut all = tracks();
        all.push(track("Indonesian", "id", SubtitleVariant::Full));
        let plan = plan_subtitles(
            &all,
            DownloadSubtitles::Translated,
            TranslationLanguage::Indonesian,
        )
        .unwrap();
        assert_eq!(plan.track.label, "Indonesian");
        assert_eq!(plan.translate_to, None);
    }

    #[test]
    fn otherwise_the_full_english_track_is_translated() {
        let plan = plan_subtitles(
            &tracks(),
            DownloadSubtitles::Translated,
            TranslationLanguage::Indonesian,
        )
        .unwrap();
        assert_eq!(plan.track.label, "English");
        assert_eq!(plan.translate_to, Some(TranslationLanguage::Indonesian));
    }

    #[test]
    fn original_mode_or_translation_off_keeps_the_english_track_untranslated() {
        for (mode, target) in [
            (DownloadSubtitles::Original, TranslationLanguage::Indonesian),
            (DownloadSubtitles::Translated, TranslationLanguage::Off),
        ] {
            let plan = plan_subtitles(&tracks(), mode, target).unwrap();
            assert_eq!(
                (plan.track.label.as_str(), plan.translate_to),
                ("English", None)
            );
        }
    }

    #[test]
    fn subtitles_switched_off_or_missing_give_no_plan() {
        assert!(
            plan_subtitles(
                &tracks(),
                DownloadSubtitles::Off,
                TranslationLanguage::Indonesian
            )
            .is_none()
        );
        assert!(
            plan_subtitles(
                &[],
                DownloadSubtitles::Translated,
                TranslationLanguage::Indonesian
            )
            .is_none()
        );
    }

    #[test]
    fn track_names_are_shown_in_indonesian() {
        assert_eq!(language_name(Some("en"), "English"), "Inggris");
        assert_eq!(language_name(Some("xx"), "Lain"), "Lain");
        assert_eq!(language_name(None, "Asli"), "Asli");
    }
}
