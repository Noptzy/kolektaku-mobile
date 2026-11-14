use domain::media::{MediaFormat, MediaStatus};

use super::case_support::{assert_auto, candidate, resolve, wanted};

#[test]
fn case_1_one_piece_tv_is_not_the_film_red() {
    let target = wanted(
        &["ONE PIECE", "One Piece", "ワンピース"],
        MediaFormat::Tv,
        1999,
        None,
        MediaStatus::Releasing,
    );
    let picked = resolve(
        &target,
        &[
            candidate("film-red", "One Piece Film: Red", "Movie", 2022, Some(1)),
            candidate("tv", "One Piece", "TV", 1999, None),
            candidate("movie-1", "One Piece Movie 1", "Movie", 2000, Some(1)),
        ],
    );
    assert_auto(picked, "tv");
}

#[test]
fn case_2_one_piece_movie_1_is_not_the_tv_series() {
    let target = wanted(
        &["ONE PIECE", "One Piece Movie 1", "One Piece: The Movie"],
        MediaFormat::Movie,
        2000,
        Some(1),
        MediaStatus::Finished,
    );
    let picked = resolve(
        &target,
        &[
            candidate("tv", "One Piece", "TV", 1999, None),
            candidate("movie-1", "One Piece Movie 1", "Movie", 2000, Some(1)),
            candidate("film-red", "One Piece Film: Red", "Movie", 2022, Some(1)),
        ],
    );
    assert_auto(picked, "movie-1");
}

#[test]
fn case_3_yuukaku_hen_is_not_season_1() {
    let target = wanted(
        &[
            "Kimetsu no Yaiba: Yuukaku-hen",
            "Demon Slayer: Kimetsu no Yaiba Entertainment District Arc",
        ],
        MediaFormat::Tv,
        2021,
        Some(11),
        MediaStatus::Finished,
    );
    let picked = resolve(
        &target,
        &[
            candidate("s1", "Kimetsu no Yaiba", "TV", 2019, Some(26)),
            candidate(
                "yuukaku",
                "Kimetsu no Yaiba: Yuukaku-hen",
                "TV",
                2021,
                Some(11),
            ),
            candidate(
                "mugen",
                "Kimetsu no Yaiba Movie: Mugen Ressha-hen",
                "Movie",
                2020,
                Some(1),
            ),
        ],
    );
    assert_auto(picked, "yuukaku");
}

#[test]
fn case_4_final_season_part_2_is_not_part_1() {
    let target = wanted(
        &[
            "Shingeki no Kyojin: The Final Season Part 2",
            "Attack on Titan: Final Season Part 2",
        ],
        MediaFormat::Tv,
        2022,
        Some(12),
        MediaStatus::Finished,
    );
    let picked = resolve(
        &target,
        &[
            candidate(
                "part-1",
                "Shingeki no Kyojin: The Final Season",
                "TV",
                2020,
                Some(16),
            ),
            candidate(
                "part-2",
                "Shingeki no Kyojin: The Final Season Part 2",
                "TV",
                2022,
                Some(12),
            ),
            candidate("s3", "Shingeki no Kyojin Season 3", "TV", 2018, Some(12)),
        ],
    );
    assert_auto(picked, "part-2");
}

#[test]
fn case_5_oshi_no_ko_2nd_season_is_not_season_1() {
    let target = wanted(
        &["【Oshi no Ko】 2nd Season", "Oshi no Ko Season 2"],
        MediaFormat::Tv,
        2024,
        Some(13),
        MediaStatus::Finished,
    );
    let picked = resolve(
        &target,
        &[
            candidate("s1", "Oshi no Ko", "TV", 2023, Some(11)),
            candidate("s2", "Oshi no Ko Season 2", "TV", 2024, Some(13)),
        ],
    );
    assert_auto(picked, "s2");
}

#[test]
fn case_6_spy_x_family_code_white_is_the_movie() {
    let target = wanted(
        &["Spy x Family Movie: Code: White", "SPY×FAMILY CODE: White"],
        MediaFormat::Movie,
        2023,
        Some(1),
        MediaStatus::Finished,
    );
    let picked = resolve(
        &target,
        &[
            candidate("s1", "Spy x Family", "TV", 2022, Some(25)),
            candidate("s2", "Spy x Family Season 2", "TV", 2023, Some(12)),
            candidate("movie", "Spy x Family Code: White", "Movie", 2023, Some(1)),
        ],
    );
    assert_auto(picked, "movie");
}

#[test]
fn case_7_a_title_the_provider_lacks_is_never_a_wrong_match() {
    let target = wanted(
        &["Kono Anime wa Tidak Ada", "This Anime Does Not Exist"],
        MediaFormat::Tv,
        2024,
        Some(12),
        MediaStatus::Finished,
    );
    let picked = resolve(
        &target,
        &[
            candidate("a", "One Piece", "TV", 1999, None),
            candidate("b", "Naruto", "TV", 2002, Some(220)),
            candidate(
                "c",
                "Kono Subarashii Sekai ni Shukufuku wo!",
                "TV",
                2016,
                Some(10),
            ),
        ],
    );
    assert_eq!(picked, None);
}
