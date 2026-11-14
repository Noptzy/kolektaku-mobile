use domain::source::{SourceId, SourceLink};

#[derive(Debug, Clone, PartialEq)]
pub struct ResolvedSources {
    pub links: Vec<SourceLink>,
}

impl ResolvedSources {
    pub fn best(&self) -> Option<&SourceLink> {
        self.links.first()
    }

    pub fn needs_hint(&self, source: &SourceId) -> bool {
        self.links
            .iter()
            .any(|link| link.source == *source && !link.manual && !link.confidence.is_automatic())
    }
}
