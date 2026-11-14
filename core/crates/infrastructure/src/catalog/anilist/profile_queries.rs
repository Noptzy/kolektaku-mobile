use domain::media::ProfileKind;

const SUMMARY_FRAGMENT: &str = "
fragment S on Media {
  id
  type
  title { romaji english native }
  synonyms
  coverImage { large }
  format
  status
  seasonYear
  startDate { year }
  episodes
  chapters
  averageScore
  genres
  countryOfOrigin
  isAdult
}";

const CHARACTER_BODY: &str = "
query ($id: Int) {
  Character(id: $id) {
    id
    name { full native alternative }
    image { large }
    description(asHtml: true)
    gender
    dateOfBirth { year month day }
    age
    bloodType
    favourites
    siteUrl
    media(sort: START_DATE_DESC, perPage: 50) {
      edges { characterRole node { ...S } }
    }
  }
}";

const STAFF_BODY: &str = "
query ($id: Int) {
  Staff(id: $id) {
    id
    name { full native }
    image { large }
    description(asHtml: true)
    primaryOccupations
    gender
    dateOfBirth { year month day }
    dateOfDeath { year month day }
    age
    yearsActive
    homeTown
    bloodType
    languageV2
    favourites
    siteUrl
    characterMedia(sort: START_DATE_DESC, perPage: 50) {
      edges { characterRole node { ...S } characters { name { full } } }
    }
    staffMedia(sort: START_DATE_DESC, perPage: 50) {
      edges { staffRole node { ...S } }
    }
  }
}";

const STUDIO_BODY: &str = "
query ($id: Int) {
  Studio(id: $id) {
    id
    name
    favourites
    isAnimationStudio
    siteUrl
    media(sort: START_DATE_DESC, perPage: 50, isMain: true) {
      nodes { ...S }
    }
  }
}";

pub fn profile_query(kind: ProfileKind) -> String {
    let body = match kind {
        ProfileKind::Character => CHARACTER_BODY,
        ProfileKind::Staff => STAFF_BODY,
        ProfileKind::Studio => STUDIO_BODY,
    };
    format!("{body}{SUMMARY_FRAGMENT}")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_character_asks_for_its_media_with_the_role() {
        let document = profile_query(ProfileKind::Character);
        assert!(document.contains("Character(id: $id)"));
        assert!(document.contains("characterRole"));
        assert!(document.contains("dateOfBirth { year month day }"));
        assert!(document.contains("alternative"));
        assert!(document.contains("fragment S on Media"));
        assert!(!document.contains("Staff("));
    }

    #[test]
    fn a_studio_asks_for_the_works_it_mainly_produced() {
        let document = profile_query(ProfileKind::Studio);
        assert!(document.contains("Studio(id: $id)"));
        assert!(document.contains("isMain: true"));
        assert!(document.contains("isAnimationStudio"));
        assert!(document.contains("siteUrl"));
        assert!(document.contains("nodes { ...S }"));
        assert!(document.contains("fragment S on Media"));
        assert!(!document.contains("Character("));
    }

    #[test]
    fn a_staff_member_asks_for_the_characters_they_voiced() {
        let document = profile_query(ProfileKind::Staff);
        assert!(document.contains("Staff(id: $id)"));
        assert!(document.contains("characterMedia("));
        assert!(document.contains("characters { name { full } }"));
        assert!(document.contains("staffMedia("));
        assert!(document.contains("primaryOccupations"));
        assert!(document.contains("yearsActive"));
        assert!(document.contains("homeTown"));
        assert!(document.contains("staffRole"));
        assert!(document.contains("fragment S on Media"));
    }
}
