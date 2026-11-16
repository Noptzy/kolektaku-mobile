mod open_chapter;
mod open_novel_chapter;

#[cfg(test)]
mod open_chapter_tests;
#[cfg(test)]
mod open_novel_chapter_tests;

pub use open_chapter::{ChapterView, OpenChapter};
pub use open_novel_chapter::{NovelChapterView, NovelTranslation, OpenNovelChapter};
