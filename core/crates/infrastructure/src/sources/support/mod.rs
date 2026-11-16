mod adult;
mod chapter_image;
mod fetch;
mod html;
mod page_cache;
mod parallel;
mod percent;
mod slug;

pub use adult::{is_adult_genre, is_adult_label};
pub use chapter_image::image_of;
pub use fetch::{PageFetcher, share_page_cache};
pub use html::{
    absolute_url, collapse, first_number, known_text, selector, text_excluding, text_of,
};
pub use parallel::fetch_all;
pub use percent::percent_decode;
pub use slug::{is_slug, slug_in};
