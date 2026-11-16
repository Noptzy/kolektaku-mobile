use std::fs;
use std::path::PathBuf;

pub fn read(group: &str, name: &str) -> String {
    let path: PathBuf = [env!("CARGO_MANIFEST_DIR"), "fixtures", group, name]
        .iter()
        .collect();
    let bytes = fs::read(&path).unwrap_or_else(|_| panic!("missing fixture {}", path.display()));
    String::from_utf8_lossy(&bytes).into_owned()
}

pub fn anilist(name: &str) -> String {
    read("anilist", name)
}

pub fn kuramanime(name: &str) -> String {
    read("kuramanime", name)
}

pub fn hianime(name: &str) -> String {
    read("hianime", name)
}

pub fn komiku(name: &str) -> String {
    read("komiku", name)
}

pub fn weebcentral(name: &str) -> String {
    read("weebcentral", name)
}

pub fn novelphoenix(name: &str) -> String {
    read("novelphoenix", name)
}

pub fn meionovels(name: &str) -> String {
    read("meionovels", name)
}

pub fn komikindo(name: &str) -> String {
    read("komikindo", name)
}

pub fn trace_moe(name: &str) -> String {
    read("trace_moe", name)
}

pub fn mal(name: &str) -> String {
    read("mal", name)
}

pub fn translate(name: &str) -> String {
    read("translate", name)
}
