const SECS_PER_DAY: u64 = 86_400;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct AiringSeason {
    pub name: &'static str,
    pub year: u16,
}

pub fn season_of(now_secs: u64) -> AiringSeason {
    let (year, month) = civil_year_and_month(now_secs / SECS_PER_DAY);
    let name = match month {
        1..=3 => "WINTER",
        4..=6 => "SPRING",
        7..=9 => "SUMMER",
        _ => "FALL",
    };
    AiringSeason { name, year }
}

fn civil_year_and_month(days_since_epoch: u64) -> (u16, u8) {
    let shifted = days_since_epoch + 719_468;
    let era = shifted / 146_097;
    let day_of_era = shifted - era * 146_097;
    let year_of_era =
        (day_of_era - day_of_era / 1_460 + day_of_era / 36_524 - day_of_era / 146_096) / 365;
    let day_of_year = day_of_era - (365 * year_of_era + year_of_era / 4 - year_of_era / 100);
    let month_index = (5 * day_of_year + 2) / 153;
    let month = if month_index < 10 {
        month_index + 3
    } else {
        month_index - 9
    };
    let year = year_of_era + era * 400 + u64::from(month <= 2);
    (year as u16, month as u8)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn every_quarter_maps_to_its_season() {
        let cases = [
            (1_768_478_400, "WINTER", 2026),
            (1_774_958_400, "WINTER", 2026),
            (1_775_044_800, "SPRING", 2026),
            (1_785_499_200, "SUMMER", 2026),
            (1_791_201_600, "FALL", 2026),
            (1_798_718_400, "FALL", 2026),
        ];
        for (secs, name, year) in cases {
            assert_eq!(season_of(secs), AiringSeason { name, year }, "{secs}");
        }
    }

    #[test]
    fn leap_days_and_the_epoch_are_dated_correctly() {
        assert_eq!(
            season_of(1_709_208_000),
            AiringSeason {
                name: "WINTER",
                year: 2024
            }
        );
        assert_eq!(
            season_of(43_200),
            AiringSeason {
                name: "WINTER",
                year: 1970
            }
        );
    }
}
