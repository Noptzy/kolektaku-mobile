const DEFAULT_HEX: &str = "#F5B82E";

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct AccentColor {
    red: u8,
    green: u8,
    blue: u8,
}

impl AccentColor {
    pub fn parse(text: &str) -> Option<Self> {
        let digits = text.strip_prefix('#')?;
        if digits.len() != 6 || !digits.chars().all(|digit| digit.is_ascii_hexdigit()) {
            return None;
        }
        let red = u8::from_str_radix(&digits[0..2], 16).ok()?;
        let green = u8::from_str_radix(&digits[2..4], 16).ok()?;
        let blue = u8::from_str_radix(&digits[4..6], 16).ok()?;
        Some(Self { red, green, blue })
    }

    pub fn hex(self) -> String {
        format!("#{:02X}{:02X}{:02X}", self.red, self.green, self.blue)
    }

    pub fn red(self) -> u8 {
        self.red
    }

    pub fn green(self) -> u8 {
        self.green
    }

    pub fn blue(self) -> u8 {
        self.blue
    }
}

impl Default for AccentColor {
    fn default() -> Self {
        Self::parse(DEFAULT_HEX).expect("default accent hex is valid")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_well_formed_hex_round_trips() {
        let accent = AccentColor::parse("#1E90FF").unwrap();
        assert_eq!(accent.red(), 0x1E);
        assert_eq!(accent.green(), 0x90);
        assert_eq!(accent.blue(), 0xFF);
        assert_eq!(accent.hex(), "#1E90FF");
    }

    #[test]
    fn lowercase_digits_are_accepted_and_normalized() {
        let accent = AccentColor::parse("#1e90ff").unwrap();
        assert_eq!(accent.hex(), "#1E90FF");
    }

    #[test]
    fn anything_else_is_rejected() {
        assert_eq!(AccentColor::parse("1E90FF"), None);
        assert_eq!(AccentColor::parse("#1E90F"), None);
        assert_eq!(AccentColor::parse("#1E90FFF"), None);
        assert_eq!(AccentColor::parse("#GGGGGG"), None);
        assert_eq!(AccentColor::parse(""), None);
        assert_eq!(AccentColor::parse("orange"), None);
    }

    #[test]
    fn the_default_is_the_current_yellow_accent() {
        assert_eq!(AccentColor::default().hex(), "#F5B82E");
    }
}
