use std::sync::Arc;

mod trace_support;

use trace_support::{catalog_and_registry, env_text, kind_of, targets};

use application::matching::{MatchTarget, score_candidate, score_title};
use application::ports::{Clock, SourceProvider};
use application::sources::{ResolveSources, SourceHealth, search_queries};
use domain::media::MediaSummary;
use domain::source::{ItemId, SourceDetail, SourceSearch};
use infrastructure::storage::JsonSourceLinkStore;

fn describe(detail: &SourceDetail) -> String {
    format!(
        "tipe={:?} tahun={:?} unit={:?} nomor={:?} judul-lain={}",
        detail.type_text,
        detail.year,
        detail.unit_count,
        detail.catalog_id,
        detail.alternative_titles.len()
    )
}

async fn trace_source(source: &Arc<dyn SourceProvider>, media: &MediaSummary) {
    let target = MatchTarget::of(media);
    println!("  sumber {}", source.info().id);
    let mut seen: Vec<(String, String, f64)> = Vec::new();
    for query in search_queries(media) {
        match source.search(SourceSearch::new(query.clone())).await {
            Err(error) => println!("    kata kunci {query:?}: GAGAL {error}"),
            Ok(page) => {
                println!("    kata kunci {query:?}: {} hasil", page.items.len());
                for item in page.items {
                    let score = score_title(&target, &item.title);
                    if !seen.iter().any(|known| known.0 == item.item_id.to_string()) {
                        seen.push((item.item_id.to_string(), item.title, score));
                    }
                }
            }
        }
    }
    seen.sort_by(|left, right| right.2.total_cmp(&left.2));
    for (key, title, score) in seen.iter().take(5) {
        println!("      skor-judul {score:.2} {title:?} [{key}]");
        if *score < 0.5 {
            continue;
        }
        match source.detail(ItemId::new(key.clone())).await {
            Ok(detail) => {
                let facts = application::matching::CandidateFacts {
                    titles: std::iter::once(detail.item.title.clone())
                        .chain(detail.alternative_titles.iter().cloned())
                        .collect(),
                    type_text: detail.type_text.clone(),
                    year: detail.year,
                    unit_count: detail.unit_count,
                };
                println!(
                    "        {} skor-total={:.2}",
                    describe(&detail),
                    score_candidate(&target, &facts)
                );
            }
            Err(error) => println!("        detail GAGAL {error}"),
        }
    }
}

async fn print_units(source: &Arc<dyn SourceProvider>, item: ItemId) {
    match source.units(item).await {
        Ok(units) => println!(
            "      daftar unit: {} (pertama={:?}, terakhir={:?})",
            units.len(),
            units.first().map(|unit| unit.label.clone()),
            units.last().map(|unit| unit.label.clone())
        ),
        Err(error) => println!("      daftar unit GAGAL {error}"),
    }
}

async fn final_pick(
    source: &Arc<dyn SourceProvider>,
    media: &MediaSummary,
    clock: &Arc<dyn Clock>,
    folder: &std::path::Path,
) {
    let store = Arc::new(JsonSourceLinkStore::new(folder.join(format!(
        "{}-{}.json",
        source.info().id,
        media.id.get()
    ))));
    let health = Arc::new(SourceHealth::new(clock.clone()));
    let resolver = ResolveSources::new(vec![source.clone()], store, health, clock.clone());
    match resolver.execute(media).await {
        Ok(resolved) => match resolved.best() {
            Some(link) => {
                println!(
                    "    PILIHAN: {} keyakinan={:.2} unit={:?}",
                    link.item,
                    link.confidence.get(),
                    link.unit_count
                );
                print_units(source, link.item.clone()).await;
            }
            None => println!("    PILIHAN: tidak ada"),
        },
        Err(error) => println!("    PILIHAN: GAGAL {error}"),
    }
}

#[tokio::test]
#[ignore = "talks to AniList and the sites"]
async fn trace_matching_for_the_requested_titles() {
    let (catalog, registry, clock) = catalog_and_registry();
    let kind = kind_of(&env_text("TRACE_KIND", "anime"));
    let folder = std::env::temp_dir().join(format!("kolektaku-trace-{}", std::process::id()));
    std::fs::create_dir_all(&folder).unwrap();
    for media in targets(&catalog, kind).await {
        println!(
            "\n## {} / {:?} (#{}) format={:?} tahun={:?} unit={:?} status={:?}",
            media.title.romaji,
            media.title.english,
            media.id.get(),
            media.format,
            media.year,
            media.unit_count,
            media.status
        );
        for source in registry.for_kind(kind) {
            trace_source(&source, &media).await;
            final_pick(&source, &media, &clock, &folder).await;
        }
    }
    let _ = std::fs::remove_dir_all(&folder);
}
