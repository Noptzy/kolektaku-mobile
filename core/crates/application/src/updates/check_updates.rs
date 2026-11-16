use std::sync::Arc;
use std::time::Duration;

use domain::library::{Favorite, LibraryRepository};
use domain::media::{MediaKind, MediaRef};
use domain::source::SourceLinkStore;
use tokio::sync::Semaphore;
use tokio::task::JoinSet;

use super::UpdateEvent;
use crate::ports::{Clock, UpdateLedger};
use crate::sources::{SourceDirectory, SourceHealth, candidate_links};

pub const MAX_PER_ROUND: usize = 30;
pub const AT_ONCE: usize = 2;
pub const PER_TITLE_LIMIT: Duration = Duration::from_secs(10);
pub const ROUND_LIMIT: Duration = Duration::from_secs(60);
const NEW_UNIT_MARGIN: f64 = 1e-6;

pub struct CheckUpdates<L, S, U> {
    library: Arc<L>,
    links: Arc<S>,
    ledger: Arc<U>,
    directory: Arc<SourceDirectory>,
    health: Arc<SourceHealth>,
    clock: Arc<dyn Clock>,
}

impl<L, S, U> CheckUpdates<L, S, U>
where
    L: LibraryRepository + 'static,
    S: SourceLinkStore + 'static,
    U: UpdateLedger + 'static,
{
    pub fn new(
        library: Arc<L>,
        links: Arc<S>,
        ledger: Arc<U>,
        directory: Arc<SourceDirectory>,
        health: Arc<SourceHealth>,
        clock: Arc<dyn Clock>,
    ) -> Self {
        Self {
            library,
            links,
            ledger,
            directory,
            health,
            clock,
        }
    }

    pub async fn execute(&self) -> Vec<UpdateEvent> {
        let queue = self.queue().await;
        let gate = Arc::new(Semaphore::new(AT_ONCE));
        let mut tasks = JoinSet::new();
        for favorite in queue {
            let worker = self.worker();
            let gate = Arc::clone(&gate);
            tasks.spawn(async move {
                let _turn = gate.acquire().await.ok()?;
                tokio::time::timeout(PER_TITLE_LIMIT, worker.check(favorite))
                    .await
                    .ok()
                    .flatten()
            });
        }
        let mut events = Vec::new();
        let collect = async {
            while let Some(done) = tasks.join_next().await {
                if let Ok(Some(event)) = done {
                    events.push(event);
                }
            }
        };
        let _ = tokio::time::timeout(ROUND_LIMIT, collect).await;
        tasks.abort_all();
        events
    }

    async fn queue(&self) -> Vec<Favorite> {
        let mut waiting: Vec<(u64, Favorite)> = Vec::new();
        for kind in [MediaKind::Anime, MediaKind::Manga, MediaKind::Novel] {
            for favorite in self.library.favorites(kind).await.unwrap_or_default() {
                let checked = self
                    .ledger
                    .seen(kind, &favorite.entry.media)
                    .await
                    .ok()
                    .flatten()
                    .map_or(0, |entry| entry.checked_at);
                waiting.push((checked, favorite));
            }
        }
        waiting.sort_by_key(|(checked, _)| *checked);
        waiting
            .into_iter()
            .take(MAX_PER_ROUND)
            .map(|(_, favorite)| favorite)
            .collect()
    }

    fn worker(&self) -> Worker<S, U> {
        Worker {
            links: Arc::clone(&self.links),
            ledger: Arc::clone(&self.ledger),
            directory: Arc::clone(&self.directory),
            health: Arc::clone(&self.health),
            clock: Arc::clone(&self.clock),
        }
    }
}

struct Worker<S, U> {
    links: Arc<S>,
    ledger: Arc<U>,
    directory: Arc<SourceDirectory>,
    health: Arc<SourceHealth>,
    clock: Arc<dyn Clock>,
}

impl<S: SourceLinkStore, U: UpdateLedger> Worker<S, U> {
    async fn latest_of(&self, media: &MediaRef) -> Option<f64> {
        let links =
            candidate_links(self.links.as_ref(), &self.directory, &self.health, media).await;
        let link = links.into_iter().next()?;
        let source = self.directory.get(&link.source).ok()?;
        let units = source.units(link.item).await.ok()?;
        units.iter().map(|unit| unit.number).reduce(f64::max)
    }

    async fn check(&self, favorite: Favorite) -> Option<UpdateEvent> {
        let (kind, media) = (favorite.entry.kind, favorite.entry.media.clone());
        let latest = self.latest_of(&media).await?;
        let before = self.ledger.seen(kind, &media).await.ok().flatten();
        let now = self.clock.now_secs();
        self.ledger.record(kind, &media, latest, now).await.ok()?;
        let previous = before?.latest;
        (latest > previous + NEW_UNIT_MARGIN).then_some(UpdateEvent {
            kind,
            media,
            title: favorite.entry.title,
            cover_url: favorite.entry.cover_url,
            unit_number: latest,
            previous,
        })
    }
}
