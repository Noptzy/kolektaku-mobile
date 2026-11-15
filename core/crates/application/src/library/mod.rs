mod continue_list;
mod migrate_novels;

#[cfg(test)]
mod continue_list_tests;
#[cfg(test)]
mod migrate_novels_tests;

pub use continue_list::ContinueList;
pub use migrate_novels::{MIGRATION_FLAG, MigrateNovelEntries, NovelMigration};
