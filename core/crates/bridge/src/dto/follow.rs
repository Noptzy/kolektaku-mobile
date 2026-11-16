use application::updates::UpdateEvent;

use super::media::{MediaKindDto, MediaRefDto};

#[derive(Debug, Clone, PartialEq)]
pub struct UpdateEventDto {
    pub kind: MediaKindDto,
    pub reference: MediaRefDto,
    pub title: String,
    pub cover_url: Option<String>,
    pub unit_number: f64,
    pub previous: f64,
}

impl From<&UpdateEvent> for UpdateEventDto {
    fn from(event: &UpdateEvent) -> Self {
        Self {
            kind: event.kind.into(),
            reference: (&event.media).into(),
            title: event.title.clone(),
            cover_url: event.cover_url.clone(),
            unit_number: event.unit_number,
            previous: event.previous,
        }
    }
}
