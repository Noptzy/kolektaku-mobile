use domain::library::{Favorite, FavoriteInput, Progress, ProgressInput, UnitOrder};

use super::media::{MediaKindDto, MediaRefDto};

#[derive(Debug, Clone, PartialEq)]
pub struct FavoriteDto {
    pub reference: MediaRefDto,
    pub kind: MediaKindDto,
    pub title: String,
    pub cover_url: Option<String>,
    pub added_at_secs: u64,
}

impl From<&Favorite> for FavoriteDto {
    fn from(favorite: &Favorite) -> Self {
        Self {
            reference: (&favorite.entry.media).into(),
            kind: favorite.entry.kind.into(),
            title: favorite.entry.title.clone(),
            cover_url: favorite.entry.cover_url.clone(),
            added_at_secs: favorite.added_at_secs,
        }
    }
}

impl FavoriteDto {
    pub fn to_input(&self) -> Option<FavoriteInput> {
        Some(FavoriteInput {
            media: self.reference.to_domain()?,
            kind: self.kind.into(),
            title: self.title.clone(),
            cover_url: self.cover_url.clone(),
        })
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct ProgressDto {
    pub reference: MediaRefDto,
    pub kind: MediaKindDto,
    pub unit_number: f64,
    pub title: String,
    pub cover_url: Option<String>,
    pub position: f64,
    pub length: f64,
    pub updated_at_secs: u64,
    pub completed: bool,
}

impl From<&Progress> for ProgressDto {
    fn from(progress: &Progress) -> Self {
        let entry = &progress.entry;
        Self {
            reference: (&entry.media).into(),
            kind: entry.kind.into(),
            unit_number: entry.unit_number,
            title: entry.title.clone(),
            cover_url: entry.cover_url.clone(),
            position: entry.position,
            length: entry.length,
            updated_at_secs: entry.updated_at_secs,
            completed: progress.completed,
        }
    }
}

impl ProgressDto {
    pub fn to_input(&self) -> Option<ProgressInput> {
        Some(ProgressInput {
            media: self.reference.to_domain()?,
            kind: self.kind.into(),
            unit_number: self.unit_number,
            title: self.title.clone(),
            cover_url: self.cover_url.clone(),
            position: self.position,
            length: self.length,
            updated_at_secs: self.updated_at_secs,
        })
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum UnitOrderDto {
    Asc,
    Desc,
}

impl From<UnitOrder> for UnitOrderDto {
    fn from(order: UnitOrder) -> Self {
        match order {
            UnitOrder::Asc => Self::Asc,
            UnitOrder::Desc => Self::Desc,
        }
    }
}

impl From<UnitOrderDto> for UnitOrder {
    fn from(order: UnitOrderDto) -> Self {
        match order {
            UnitOrderDto::Asc => Self::Asc,
            UnitOrderDto::Desc => Self::Desc,
        }
    }
}

#[cfg(test)]
mod tests {
    use domain::media::{MediaId, MediaKind, MediaRef};

    use super::*;

    fn input() -> ProgressInput {
        ProgressInput {
            media: MediaRef::catalog(MediaId::new(9).unwrap()),
            kind: MediaKind::Anime,
            unit_number: 3.0,
            title: "Frieren".into(),
            cover_url: None,
            position: 1300.0,
            length: 1440.0,
            updated_at_secs: 77,
        }
    }

    #[test]
    fn progress_survives_the_trip_and_knows_when_it_is_finished() {
        let progress = Progress::from_input(input());
        let dto = ProgressDto::from(&progress);
        assert!(dto.completed);
        assert_eq!(dto.to_input(), Some(input()));
    }

    #[test]
    fn a_favorite_survives_the_trip() {
        let entry = FavoriteInput {
            media: MediaRef::catalog(MediaId::new(2).unwrap()),
            kind: MediaKind::Manga,
            title: "Berserk".into(),
            cover_url: Some("c".into()),
        };
        let dto = FavoriteDto::from(&Favorite::added(entry.clone(), 5));
        assert_eq!(dto.added_at_secs, 5);
        assert_eq!(dto.to_input(), Some(entry));
    }

    #[test]
    fn an_invalid_reference_makes_the_input_unusable() {
        let mut dto = ProgressDto::from(&Progress::from_input(input()));
        dto.reference = MediaRefDto::catalog(0);
        assert_eq!(dto.to_input(), None);
    }

    #[test]
    fn unit_orders_convert_both_ways() {
        for order in [UnitOrder::Asc, UnitOrder::Desc] {
            assert_eq!(UnitOrder::from(UnitOrderDto::from(order)), order);
        }
    }
}
