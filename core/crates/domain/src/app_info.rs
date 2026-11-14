pub struct AppInfo {
    pub name: String,
}

impl AppInfo {
    pub fn new(name: impl Into<String>) -> Self {
        Self { name: name.into() }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_menyimpan_nama_apa_adanya() {
        let info = AppInfo::new("Kolektaku");
        assert_eq!(info.name, "Kolektaku");
    }
}
