use std::path::{Path, PathBuf};

pub fn unique_path(folder: &Path, stem: &str, extension: &str) -> PathBuf {
    let first = folder.join(format!("{stem}.{extension}"));
    if !first.exists() {
        return first;
    }
    (2..)
        .map(|number| folder.join(format!("{stem} ({number}).{extension}")))
        .find(|candidate| !candidate.exists())
        .expect("an unused name always exists")
}

pub fn work_folder(output: &Path, job_id: i64) -> PathBuf {
    output.join(".parts").join(format!("job-{job_id}"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_taken_name_gets_a_number() {
        let folder = std::env::temp_dir().join(format!("kolektaku-files-{}", std::process::id()));
        std::fs::create_dir_all(&folder).unwrap();
        let first = unique_path(&folder, "Judul - Episode 01", "mkv");
        assert!(first.ends_with("Judul - Episode 01.mkv"));
        std::fs::write(&first, b"x").unwrap();
        let second = unique_path(&folder, "Judul - Episode 01", "mkv");
        assert!(second.ends_with("Judul - Episode 01 (2).mkv"));
        let _ = std::fs::remove_dir_all(&folder);
    }

    #[test]
    fn each_job_works_in_its_own_folder() {
        let root = Path::new("work");
        assert_ne!(work_folder(root, 1), work_folder(root, 2));
    }
}
