use std::sync::Arc;

use domain::error::SourceError;
use domain::matching::Confidence;
use domain::media::{MediaId, MediaKind, MediaRef};
use domain::settings::TranslationLanguage;
use domain::source::{ItemId, SourceId, SourceLink, SourceLinkStore, TextBlock, Unit};

use super::OpenNovelChapter;
use crate::ports::SourceProvider;
use crate::sources::{SourceDirectory, SourceHealth};
use crate::testing::{FakeClock, FakeSource, FakeText, FakeTranslator, MemoryLinkStore};

fn reference() -> MediaRef {
    MediaRef::catalog(MediaId::new(30013).unwrap())
}

fn text_for(id: &str, language: &str, chapters: u32) -> FakeText {
    (1..=chapters).fold(FakeText::new(), |text, number| {
        text.with_chapter(&format!("{id}-ch-{number}"), language, &["Satu", "Dua"])
    })
}

fn site(id: &str, priority: u8, text: FakeText) -> FakeSource {
    let units = (1..=5)
        .map(|number| {
            Unit::new(
                format!("{id}-ch-{number}"),
                f64::from(number),
                format!("Chapter {number}"),
            )
        })
        .collect();
    FakeSource::new(id, MediaKind::Novel)
        .with_priority(priority)
        .with_units(&format!("{id}-item"), units)
        .with_text(text)
}

struct Rig {
    use_case: OpenNovelChapter<MemoryLinkStore>,
    translator: Arc<FakeTranslator>,
}

async fn rig(sites: Vec<FakeSource>, translator: FakeTranslator) -> Rig {
    let providers: Vec<Arc<dyn SourceProvider>> = sites
        .into_iter()
        .map(|site| Arc::new(site) as Arc<dyn SourceProvider>)
        .collect();
    let store = Arc::new(MemoryLinkStore::new());
    let links: Vec<SourceLink> = providers
        .iter()
        .map(|site| {
            let id = site.info().id.clone();
            let item = ItemId::new(format!("{id}-item"));
            SourceLink::matched(id, item, Confidence::new(0.9), 0)
        })
        .collect();
    store.save_all(&reference(), links).await.unwrap();
    let health = Arc::new(SourceHealth::new(Arc::new(FakeClock::at(0))));
    let directory = Arc::new(SourceDirectory::new(providers));
    let translator = Arc::new(translator);
    let use_case = OpenNovelChapter::new(store, directory, health.clone(), translator.clone());
    Rig {
        use_case,
        translator,
    }
}

async fn open(rig: &Rig, target: TranslationLanguage) -> super::NovelChapterView {
    rig.use_case
        .execute(&reference(), 3.0, None, &[], target)
        .await
        .unwrap()
}

#[tokio::test]
async fn the_best_site_serves_the_chapter_text() {
    let rig = rig(
        vec![
            site("a", 1, text_for("a", "id", 5)),
            site("b", 5, text_for("b", "en", 5)),
        ],
        FakeTranslator::prefixing("T:"),
    )
    .await;
    let view = open(&rig, TranslationLanguage::Indonesian).await;
    assert_eq!(view.source.as_str(), "a");
    assert_eq!(view.unit.id, "a-ch-3");
    assert_eq!(view.text.language, "id");
    assert!(view.translation.is_none() && !view.translation_failed);
    assert!(rig.translator.calls().is_empty());
}

#[tokio::test]
async fn an_english_chapter_comes_with_its_translation_side_by_side() {
    let rig = rig(
        vec![site("b", 1, text_for("b", "en", 5))],
        FakeTranslator::prefixing("T:"),
    )
    .await;
    let view = open(&rig, TranslationLanguage::Indonesian).await;
    assert_eq!(
        view.text.paragraphs().collect::<Vec<_>>(),
        vec!["Satu", "Dua"]
    );
    let translation = view.translation.unwrap();
    assert_eq!(translation.language, "id");
    assert_eq!(
        translation.blocks,
        vec![
            TextBlock::Paragraph("T:Satu".into()),
            TextBlock::Paragraph("T:Dua".into())
        ]
    );
}

#[tokio::test]
async fn translation_off_never_asks_the_service() {
    let rig = rig(
        vec![site("b", 1, text_for("b", "en", 5))],
        FakeTranslator::prefixing("T:"),
    )
    .await;
    let view = open(&rig, TranslationLanguage::Off).await;
    assert!(view.translation.is_none() && !view.translation_failed);
    assert!(rig.translator.calls().is_empty());
}

#[tokio::test]
async fn a_failed_translation_keeps_the_original_and_says_so() {
    let rig = rig(
        vec![site("b", 1, text_for("b", "en", 5))],
        FakeTranslator::failing_with(SourceError::Network("down".into())),
    )
    .await;
    let view = open(&rig, TranslationLanguage::Indonesian).await;
    assert!(view.translation.is_none());
    assert!(view.translation_failed);
    assert_eq!(view.text.paragraphs().count(), 2);
}

#[tokio::test]
async fn a_site_that_cannot_load_the_text_hands_over_to_the_next() {
    let broken = text_for("a", "id", 5);
    broken.set_failure(Some(SourceError::Unavailable("down".into())));
    let rig = rig(
        vec![site("a", 1, broken), site("b", 5, text_for("b", "id", 5))],
        FakeTranslator::prefixing("T:"),
    )
    .await;
    let view = open(&rig, TranslationLanguage::Indonesian).await;
    assert_eq!(view.source.as_str(), "b");
    assert_eq!(view.switched_from, Some(SourceId::new("a")));
}

#[tokio::test]
async fn a_chapter_that_exists_nowhere_is_not_found() {
    let rig = rig(
        vec![site("a", 1, text_for("a", "id", 5))],
        FakeTranslator::prefixing("T:"),
    )
    .await;
    let result = rig
        .use_case
        .execute(&reference(), 99.0, None, &[], TranslationLanguage::Off)
        .await;
    assert!(matches!(result, Err(SourceError::NotFound(_))));
}
