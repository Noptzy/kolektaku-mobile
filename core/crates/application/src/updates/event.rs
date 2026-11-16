use domain::media::{MediaKind, MediaRef};

#[derive(Debug, Clone, PartialEq)]
pub struct UpdateEvent {
    pub kind: MediaKind,
    pub media: MediaRef,
    pub title: String,
    pub cover_url: Option<String>,
    pub unit_number: f64,
    pub previous: f64,
}
