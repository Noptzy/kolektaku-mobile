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

const DETAIL_BODY: &str = "
query ($id: Int, $type: MediaType) {
  Media(id: $id, type: $type) {
    ...S
    idMal
    externalLinks { site url type isDisabled }
    coverImage { extraLarge }
    bannerImage
    description(asHtml: true)
    duration
    season
    source(version: 3)
    siteUrl
    endDate { year month day }
    startDate { year month day }
    studios(isMain: true) { nodes { id name } }
    trailer { id site thumbnail }
    nextAiringEpisode { episode airingAt }
    streamingEpisodes { title thumbnail }
    characters(sort: [ROLE, RELEVANCE], perPage: 25) {
      edges {
        role
        node { id name { full } image { large } }
        voiceActors(language: JAPANESE) { id name { full } image { large } languageV2 }
      }
    }
    staff(sort: RELEVANCE, perPage: 12) {
      edges { role node { id name { full } image { large } } }
    }
    relations { edges { relationType(version: 2) node { ...S } } }
    recommendations(sort: RATING_DESC, perPage: 12) { nodes { mediaRecommendation { ...S } } }
  }
}";

const LIST_BODY: &str = "
query ($page: Int, $perPage: Int, $type: MediaType, $sort: [MediaSort], $country: CountryCode, $season: MediaSeason, $year: Int) {
  Page(page: $page, perPage: $perPage) {
    pageInfo { currentPage hasNextPage }
    media(type: $type, sort: $sort, isAdult: false, countryOfOrigin: $country, season: $season, seasonYear: $year) { ...S }
  }
}";

const SEARCH_BODY: &str = "
query ($page: Int, $perPage: Int, $type: MediaType, $search: String, $country: CountryCode) {
  Page(page: $page, perPage: $perPage) {
    pageInfo { currentPage hasNextPage }
    media(type: $type, search: $search, sort: [SEARCH_MATCH], isAdult: false, countryOfOrigin: $country) { ...S }
  }
}";

const DISCOVER_BODY: &str = "
query ($page: Int, $perPage: Int, $type: MediaType, $search: String, $genre: String, $tag: String, $from: FuzzyDateInt, $to: FuzzyDateInt, $sort: [MediaSort], $country: CountryCode, $formats: [MediaFormat], $status: MediaStatus, $source: MediaSource) {
  Page(page: $page, perPage: $perPage) {
    pageInfo { currentPage hasNextPage }
    media(type: $type, search: $search, genre: $genre, tag: $tag, minimumTagRank: 60, startDate_greater: $from, startDate_lesser: $to, format_in: $formats, status: $status, source: $source, sort: $sort, isAdult: false, countryOfOrigin: $country) { ...S }
  }
}";

pub fn discover_query() -> String {
    format!("{DISCOVER_BODY}{SUMMARY_FRAGMENT}")
}

pub fn detail_query() -> String {
    format!("{DETAIL_BODY}{SUMMARY_FRAGMENT}")
}

pub fn list_query() -> String {
    format!("{LIST_BODY}{SUMMARY_FRAGMENT}")
}

pub fn search_query() -> String {
    format!("{SEARCH_BODY}{SUMMARY_FRAGMENT}")
}

pub fn batch_match_query(count: usize) -> String {
    let variables: Vec<String> = (0..count)
        .map(|index| format!("$t{index}: String"))
        .collect();
    let aliases: Vec<String> = (0..count)
        .map(|index| {
            format!(
                "m{index}: Page(perPage: 3) {{ media(search: $t{index}, type: $type, isAdult: false, sort: [SEARCH_MATCH]) {{ ...S }} }}"
            )
        })
        .collect();
    format!(
        "query ($type: MediaType, {}) {{\n  {}\n}}\n{SUMMARY_FRAGMENT}",
        variables.join(", "),
        aliases.join("\n  ")
    )
}

const TAG_RANK: &str = "minimumTagRank: 80, ";

pub fn genre_covers_query(count: usize) -> String {
    let variables: Vec<String> = (0..count)
        .map(|index| format!("$n{index}: String"))
        .collect();
    let aliases: Vec<String> = (0..count)
        .flat_map(|index| {
            [("g", "genre", ""), ("t", "tag", TAG_RANK)].map(|(prefix, field, rank)| {
                format!(
                    "{prefix}{index}: Page(perPage: 4) {{ media({field}: $n{index}, {rank}type: $type, isAdult: false, genre_not_in: [\"Hentai\", \"Ecchi\"], sort: [POPULARITY_DESC]) {{ coverImage {{ large }} }} }}"
                )
            })
        })
        .collect();
    format!(
        "query ($type: MediaType, {}) {{
  {}
}}",
        variables.join(", "),
        aliases.join(
            "
  "
        )
    )
}

#[cfg(test)]
#[path = "queries_tests.rs"]
mod tests;
