pub const MATCHER_VERSION: u32 = 2;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_rules_with_variants_and_refusals_are_version_two() {
        assert_eq!(MATCHER_VERSION, 2);
    }
}
