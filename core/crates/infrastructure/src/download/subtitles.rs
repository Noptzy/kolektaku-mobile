use std::sync::Arc;

use application::ports::Translator;
use application::streaming::{Cue, parse_vtt};
use application::translation::TranslateCues;
use domain::error::SourceError;
use domain::translation::LanguageRoute;

use super::mux::SubtitleInput;
use super::subtitle_plan::{SubtitlePlan, language_name};
use crate::http::{HttpClient, HttpRequest};

pub struct SubtitleFetch {
    pub http: Arc<dyn HttpClient>,
    pub translator: Arc<dyn Translator>,
    pub headers: Vec<(String, String)>,
}

impl SubtitleFetch {
    async fn cues(&self, url: &str) -> Result<Vec<Cue>, SourceError> {
        let request = self
            .headers
            .iter()
            .fold(HttpRequest::get(url), |request, (name, value)| {
                request.with_header(name, value)
            });
        let response = self.http.send(request).await?;
        if !response.is_success() {
            return Err(SourceError::Unavailable(format!(
                "subtitle answered {}",
                response.status
            )));
        }
        Ok(parse_vtt(&response.body))
    }

    pub async fn inputs(&self, plan: &SubtitlePlan) -> Vec<SubtitleInput> {
        let Ok(cues) = self.cues(&plan.track.url).await else {
            return Vec::new();
        };
        if cues.is_empty() {
            return Vec::new();
        }
        let language = plan.track.language.clone();
        let original = SubtitleInput {
            name: language_name(language.as_deref(), &plan.track.label),
            language: language.clone(),
            default: true,
            cues: cues.clone(),
        };
        let Some(target) = plan.translate_to else {
            return vec![original];
        };
        let Some(route) = LanguageRoute::new(language.as_deref(), target) else {
            return vec![original];
        };
        let outcome = TranslateCues::new(self.translator.clone())
            .execute(cues, &route, 0)
            .await;
        if !outcome.translated {
            return vec![original];
        }
        let code = route.target_code().to_string();
        let translated = SubtitleInput {
            name: format!(
                "{} (terjemahan otomatis)",
                language_name(Some(&code), &code)
            ),
            language: Some(code),
            default: true,
            cues: outcome.cues,
        };
        vec![
            translated,
            SubtitleInput {
                default: false,
                ..original
            },
        ]
    }
}

#[cfg(test)]
mod tests {
    use application::testing::FakeTranslator;
    use domain::settings::TranslationLanguage;
    use domain::stream::{SubtitleTrack, SubtitleVariant};

    use super::*;
    use crate::http::{FakeHttp, HttpResponse};

    const VTT: &str = "WEBVTT\n\n00:00:01.000 --> 00:00:02.000\nHello\n";

    fn plan(translate: bool) -> SubtitlePlan {
        SubtitlePlan {
            track: SubtitleTrack {
                label: "English".into(),
                language: Some("en".into()),
                variant: SubtitleVariant::Full,
                url: "https://subs.test/en.vtt".into(),
                is_default: true,
            },
            translate_to: translate.then_some(TranslationLanguage::Indonesian),
        }
    }

    fn fetch(response: HttpResponse, translator: FakeTranslator) -> SubtitleFetch {
        SubtitleFetch {
            http: Arc::new(FakeHttp::always(response)),
            translator: Arc::new(translator),
            headers: vec![("referer".into(), "https://site.test/".into())],
        }
    }

    #[tokio::test]
    async fn a_translated_track_comes_first_and_the_original_is_kept_behind_it() {
        let translator = FakeTranslator::prefixing("ID:");
        let inputs = fetch(HttpResponse::new(200, VTT), translator)
            .inputs(&plan(true))
            .await;
        assert_eq!(inputs.len(), 2);
        assert_eq!(inputs[0].name, "Indonesia (terjemahan otomatis)");
        assert_eq!(inputs[0].cues[0].text, "ID:Hello");
        assert!(inputs[0].default && !inputs[1].default);
        assert_eq!(inputs[1].cues[0].text, "Hello");
    }

    #[tokio::test]
    async fn without_translation_only_the_original_is_kept() {
        let translator = FakeTranslator::prefixing("ID:");
        let inputs = fetch(HttpResponse::new(200, VTT), translator)
            .inputs(&plan(false))
            .await;
        assert_eq!(inputs.len(), 1);
        assert_eq!(inputs[0].name, "Inggris");
    }

    #[tokio::test]
    async fn a_subtitle_that_cannot_be_fetched_is_simply_left_out() {
        let translator = FakeTranslator::prefixing("ID:");
        let inputs = fetch(HttpResponse::new(404, ""), translator)
            .inputs(&plan(true))
            .await;
        assert!(inputs.is_empty());
    }
}
