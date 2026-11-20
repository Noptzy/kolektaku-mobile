const WRAP: u64 = 1 << 33;
const HALF_WRAP: u64 = 1 << 32;
pub const TICKS_PER_MS: u64 = 90;

#[derive(Debug, Default, Clone)]
pub struct Unwrapper {
    last: Option<u64>,
    offset: u64,
}

impl Unwrapper {
    pub fn unwrap(&mut self, ticks: u64) -> u64 {
        if let Some(last) = self.last {
            if ticks + HALF_WRAP < last {
                self.offset += WRAP;
            } else if ticks > last + HALF_WRAP && self.offset >= WRAP {
                self.offset -= WRAP;
            }
        }
        self.last = Some(ticks);
        ticks + self.offset
    }
}

pub fn ticks_to_ms(ticks: u64, base: u64) -> i64 {
    (ticks as i64 - base as i64) / TICKS_PER_MS as i64
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn times_that_wrap_around_keep_counting_up() {
        let mut clock = Unwrapper::default();
        assert_eq!(clock.unwrap(WRAP - 90), WRAP - 90);
        assert_eq!(clock.unwrap(10), WRAP + 10);
        assert_eq!(clock.unwrap(100), WRAP + 100);
    }

    #[test]
    fn small_steps_back_from_reordered_frames_are_not_a_wrap() {
        let mut clock = Unwrapper::default();
        assert_eq!(clock.unwrap(9_000), 9_000);
        assert_eq!(clock.unwrap(6_000), 6_000);
    }

    #[test]
    fn ticks_become_milliseconds_from_the_base() {
        assert_eq!(ticks_to_ms(180_000, 90_000), 1_000);
        assert_eq!(ticks_to_ms(90_000, 180_000), -1_000);
    }
}
