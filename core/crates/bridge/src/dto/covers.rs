use application::catalog::GenreCover;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct GenreCoverDto {
    pub genre: String,
    pub cover_url: String,
}

impl From<&GenreCover> for GenreCoverDto {
    fn from(cover: &GenreCover) -> Self {
        Self {
            genre: cover.genre.clone(),
            cover_url: cover.cover_url.clone(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_cover_keeps_its_genre_and_address() {
        let cover = GenreCover {
            genre: "Action".into(),
            cover_url: "https://img.test/a.jpg".into(),
        };
        let dto = GenreCoverDto::from(&cover);
        assert_eq!(dto.genre, "Action");
        assert_eq!(dto.cover_url, "https://img.test/a.jpg");
    }
}
