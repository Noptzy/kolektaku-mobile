use domain::media::{FactKind, ProfileFact};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FactKindDto {
    Occupations,
    Birthday,
    Died,
    Age,
    Gender,
    BloodType,
    HomeTown,
    YearsActive,
    Language,
    Nicknames,
    StudioType,
    Favourites,
}

impl From<FactKind> for FactKindDto {
    fn from(kind: FactKind) -> Self {
        match kind {
            FactKind::Occupations => Self::Occupations,
            FactKind::Birthday => Self::Birthday,
            FactKind::Died => Self::Died,
            FactKind::Age => Self::Age,
            FactKind::Gender => Self::Gender,
            FactKind::BloodType => Self::BloodType,
            FactKind::HomeTown => Self::HomeTown,
            FactKind::YearsActive => Self::YearsActive,
            FactKind::Language => Self::Language,
            FactKind::Nicknames => Self::Nicknames,
            FactKind::StudioType => Self::StudioType,
            FactKind::Favourites => Self::Favourites,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProfileFactDto {
    pub kind: FactKindDto,
    pub value: String,
}

impl From<&ProfileFact> for ProfileFactDto {
    fn from(fact: &ProfileFact) -> Self {
        Self {
            kind: fact.kind.into(),
            value: fact.value.clone(),
        }
    }
}
