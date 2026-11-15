mod adult;
mod fetch;
mod html;
mod page_cache;
mod parallel;
mod percent;
mod slug;

pub use adult::{is_adult_genre, is_adult_label};
pub use fetch::PageFetcher;
pub use html::{
    absolute_url, collapse, first_number, known_text, selector, text_excluding, text_of,
};
pub use parallel::fetch_all;
pub use percent::percent_decode;
pub use slug::{is_slug, slug_in};
