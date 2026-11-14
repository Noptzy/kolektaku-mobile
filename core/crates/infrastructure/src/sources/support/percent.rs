pub fn percent_decode(text: &str) -> String {
    let bytes = text.as_bytes();
    let mut decoded = Vec::with_capacity(bytes.len());
    let mut index = 0;
    while index < bytes.len() {
        match hex_pair(bytes, index) {
            Some(value) => {
                decoded.push(value);
                index += 3;
            }
            None => {
                decoded.push(bytes[index]);
                index += 1;
            }
        }
    }
    String::from_utf8(decoded).unwrap_or_else(|_| text.to_string())
}

fn hex_pair(bytes: &[u8], index: usize) -> Option<u8> {
    if bytes.get(index) != Some(&b'%') {
        return None;
    }
    let high = hex_digit(*bytes.get(index + 1)?)?;
    let low = hex_digit(*bytes.get(index + 2)?)?;
    Some(high * 16 + low)
}

fn hex_digit(byte: u8) -> Option<u8> {
    char::from(byte).to_digit(16).map(|digit| digit as u8)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn decodes_escaped_bytes_including_multibyte_characters() {
        assert_eq!(percent_decode("a%20b"), "a b");
        assert_eq!(percent_decode("%E3%83%81%E3%82%A7"), "チェ");
        assert_eq!(percent_decode("chainsaw-man"), "chainsaw-man");
    }

    #[test]
    fn malformed_or_non_utf8_escapes_leave_the_text_alone() {
        assert_eq!(percent_decode("100%"), "100%");
        assert_eq!(percent_decode("a%zzb"), "a%zzb");
        assert_eq!(percent_decode("%FF%FE"), "%FF%FE");
        assert_eq!(percent_decode(""), "");
    }
}
