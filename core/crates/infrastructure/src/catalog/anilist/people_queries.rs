use domain::media::ProfileKind;

const CHARACTERS: &str = "
query ($search: String) {
  Page(page: 1, perPage: 25) {
    characters(search: $search, sort: SEARCH_MATCH) {
      id
      name { full native }
      image { large }
      media(perPage: 1, sort: POPULARITY_DESC) { nodes { title { romaji english } isAdult } }
    }
  }
}";

const STAFF: &str = "
query ($search: String) {
  Page(page: 1, perPage: 25) {
    staff(search: $search, sort: SEARCH_MATCH) {
      id
      name { full native }
      image { large }
      primaryOccupations
    }
  }
}";

const STUDIOS: &str = "
query ($search: String) {
  Page(page: 1, perPage: 25) {
    studios(search: $search, sort: SEARCH_MATCH) {
      id
      name
      media(perPage: 1, sort: POPULARITY_DESC, isMain: true) { nodes { title { romaji english } isAdult } }
    }
  }
}";

pub fn search_profiles_query(kind: ProfileKind) -> &'static str {
    match kind {
        ProfileKind::Character => CHARACTERS,
        ProfileKind::Staff => STAFF,
        ProfileKind::Studio => STUDIOS,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn each_kind_asks_for_its_own_connection_by_best_match() {
        for (kind, field) in [
            (ProfileKind::Character, "characters(search: $search"),
            (ProfileKind::Staff, "staff(search: $search"),
            (ProfileKind::Studio, "studios(search: $search"),
        ] {
            let document = search_profiles_query(kind);
            assert!(document.contains(field), "{kind:?}");
            assert!(document.contains("SEARCH_MATCH"));
            assert!(document.contains("perPage: 25"));
        }
    }

    #[test]
    fn characters_and_studios_carry_their_top_work_with_its_adult_flag() {
        for kind in [ProfileKind::Character, ProfileKind::Studio] {
            let document = search_profiles_query(kind);
            assert!(document.contains("title { romaji english }"));
            assert!(document.contains("isAdult"));
        }
        assert!(search_profiles_query(ProfileKind::Staff).contains("primaryOccupations"));
    }
}
