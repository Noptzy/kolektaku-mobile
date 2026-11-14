use domain::source::Unit;

use super::model::RawEpisode;
use super::urls::valid_slug;

pub fn number_label(number: f64) -> String {
    if number.fract() == 0.0 {
        format!("Episode {}", number as i64)
    } else {
        format!("Episode {number}")
    }
}

pub fn units_of(episodes: Vec<RawEpisode>) -> Vec<Unit> {
    let mut units: Vec<Unit> = episodes
        .into_iter()
        .filter_map(|episode| {
            let slug = episode.slug.filter(|slug| valid_slug(slug))?;
            let number = episode.number.filter(|number| number.is_finite() && *number >= 0.0)?;
            Some(Unit::new(slug, number, number_label(number)))
        })
        .collect();
    units.sort_by(|a, b| a.number.total_cmp(&b.number));
    units.dedup_by(|later, earlier| later.id == earlier.id);
    units
}

#[cfg(test)]
mod tests {
    use super::*;

    fn episode(slug: Option<&str>, number: Option<f64>) -> RawEpisode {
        RawEpisode {
            number,
            slug: slug.map(str::to_string),
            link: None,
        }
    }

    #[test]
    fn episodes_become_sorted_units_named_by_number() {
        let units = units_of(vec![
            episode(Some("b"), Some(2.0)),
            episode(Some("a"), Some(1.0)),
            episode(Some("c"), Some(10.0)),
        ]);
        let numbers: Vec<f64> = units.iter().map(|unit| unit.number).collect();
        assert_eq!(numbers, [1.0, 2.0, 10.0]);
        assert_eq!(units[0].id, "a");
        assert_eq!(units[2].label, "Episode 10");
    }

    #[test]
    fn a_half_episode_keeps_its_fraction() {
        let units = units_of(vec![episode(Some("x"), Some(12.5))]);
        assert_eq!(units[0].label, "Episode 12.5");
        assert_eq!(units[0].number, 12.5);
    }

    #[test]
    fn entries_without_a_slug_or_a_sensible_number_are_dropped() {
        let units = units_of(vec![
            episode(None, Some(1.0)),
            episode(Some("a/b"), Some(2.0)),
            episode(Some("c"), None),
            episode(Some("d"), Some(-1.0)),
            episode(Some("e"), Some(f64::NAN)),
            episode(Some("ok"), Some(3.0)),
        ]);
        assert_eq!(units.len(), 1);
        assert_eq!(units[0].id, "ok");
    }

    #[test]
    fn the_same_episode_listed_twice_is_one_unit() {
        let units = units_of(vec![
            episode(Some("a"), Some(1.0)),
            episode(Some("a"), Some(1.0)),
        ]);
        assert_eq!(units.len(), 1);
    }
}
