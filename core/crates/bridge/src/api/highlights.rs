use crate::dto::highlight::{HighlightDto, HighlightInputDto};
use crate::dto::media::MediaRefDto;
use crate::error::BridgeError;
use crate::service::highlights;
use crate::state::global;

pub async fn highlight_add(input: HighlightInputDto) -> Result<i64, BridgeError> {
    highlights::add(global()?, &input).await
}

pub async fn highlight_remove(id: i64) -> Result<(), BridgeError> {
    highlights::remove(global()?, id).await
}

pub async fn highlights_of_chapter(
    reference: MediaRefDto,
    chapter: f64,
) -> Result<Vec<HighlightDto>, BridgeError> {
    highlights::for_chapter(global()?, &reference, chapter).await
}

pub async fn highlights_all() -> Result<Vec<HighlightDto>, BridgeError> {
    highlights::all(global()?).await
}
