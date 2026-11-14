use std::sync::Arc;

use domain::error::SourceError;
use domain::media::{MediaKind, MediaPage};
use domain::source::{SourcePage, SourceSearch};
use tokio::task::JoinSet;

use super::rerank::{rerank_items, rerank_media};
use crate::ports::{MetadataCatalog, SourceProvider};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Ask {
    pub catalog: bool,
    pub sources: Vec<bool>,
}

impl Ask {
    pub fn everyone(source_count: usize) -> Self {
        Self {
            catalog: true,
            sources: vec![true; source_count],
        }
    }

    pub fn nobody(&self) -> bool {
        !self.catalog && !self.sources.iter().any(|asked| *asked)
    }
}

pub struct Replies {
    pub media: Option<Result<MediaPage, SourceError>>,
    pub items: Vec<Option<Result<SourcePage, SourceError>>>,
}

enum Reply {
    Media(Result<MediaPage, SourceError>),
    Items(usize, Result<SourcePage, SourceError>),
}

pub async fn ask_participants<C: MetadataCatalog + 'static>(
    catalog: &Arc<C>,
    sources: &[Arc<dyn SourceProvider>],
    kind: MediaKind,
    query: &str,
    page: u32,
    ask: &Ask,
) -> Replies {
    let mut tasks = JoinSet::new();
    if ask.catalog {
        let catalog = Arc::clone(catalog);
        let query = query.to_string();
        tasks.spawn(async move { Reply::Media(catalog.search(kind, &query, page).await) });
    }
    for (index, source) in sources
        .iter()
        .enumerate()
        .filter(|(index, _)| ask.sources[*index])
    {
        let source = Arc::clone(source);
        let search = SourceSearch {
            page,
            ..SourceSearch::new(query)
        };
        tasks.spawn(async move { Reply::Items(index, source.search(search).await) });
    }
    let mut replies = Replies {
        media: None,
        items: sources.iter().map(|_| None).collect(),
    };
    while let Some(Ok(reply)) = tasks.join_next().await {
        match reply {
            Reply::Media(result) => replies.media = Some(result),
            Reply::Items(index, result) => replies.items[index] = Some(result),
        }
    }
    replies
}

impl Replies {
    pub fn has_results(&self) -> bool {
        let media = matches!(&self.media, Some(Ok(page)) if !page.items.is_empty());
        media
            || self
                .items
                .iter()
                .any(|reply| matches!(reply, Some(Ok(page)) if !page.items.is_empty()))
    }

    pub fn empty_participants(&self) -> Ask {
        Ask {
            catalog: matches!(&self.media, Some(Ok(page)) if page.items.is_empty()),
            sources: self
                .items
                .iter()
                .map(|reply| matches!(reply, Some(Ok(page)) if page.items.is_empty()))
                .collect(),
        }
    }

    pub fn absorb(&mut self, newer: Replies, query: &str) {
        if let Some(Ok(page)) = newer.media {
            self.media = Some(Ok(rerank_media(page, query)));
        }
        for (slot, reply) in self.items.iter_mut().zip(newer.items) {
            if let Some(Ok(page)) = reply {
                *slot = Some(Ok(rerank_items(page, query)));
            }
        }
    }

    pub fn errors(&self) -> Vec<(Option<usize>, SourceError)> {
        let catalog = self.media.iter().filter_map(|reply| reply.as_ref().err());
        let sources = self.items.iter().enumerate().filter_map(|(index, reply)| {
            reply
                .as_ref()
                .and_then(|result| result.as_ref().err())
                .map(|error| (Some(index), error))
        });
        catalog
            .map(|error| (None, error))
            .chain(sources)
            .map(|(origin, error)| (origin, error.clone()))
            .collect()
    }

    pub fn succeeded_anywhere(&self) -> bool {
        matches!(self.media, Some(Ok(_)))
            || self.items.iter().any(|reply| matches!(reply, Some(Ok(_))))
    }
}
