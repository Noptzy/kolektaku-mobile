use domain::AppInfo;

pub fn greet(target: &str) -> String {
    let info = AppInfo::new("Kolektaku");
    format!("Halo dari Rust untuk {target}! {} siap jalan.", info.name)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn greet_menyebut_target_dan_nama_app() {
        let result = greet("Flutter");
        assert!(result.contains("Flutter"));
        assert!(result.contains("Kolektaku"));
    }
}
