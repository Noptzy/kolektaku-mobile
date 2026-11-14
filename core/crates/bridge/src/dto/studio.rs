use domain::media::StudioRef;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StudioRefDto {
    pub id: Option<u64>,
    pub name: String,
}

impl From<&StudioRef> for StudioRefDto {
    fn from(studio: &StudioRef) -> Self {
        Self {
            id: studio.id,
            name: studio.name.clone(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_id_and_name_cross_over() {
        let dto = StudioRefDto::from(&StudioRef::identified(43, "ufotable"));
        assert_eq!(dto.id, Some(43));
        assert_eq!(dto.name, "ufotable");
        assert_eq!(StudioRefDto::from(&StudioRef::named("X")).id, None);
    }
}
