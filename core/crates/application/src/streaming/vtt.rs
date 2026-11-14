#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Cue {
    pub start_ms: u64,
    pub end_ms: u64,
    pub text: String,
}

const MAX_CUES: usize = 5_000;
const INVISIBLE: [char; 4] = ['\u{200e}', '\u{200f}', '\u{feff}', '\u{200b}'];

fn clock_ms(text: &str) -> Option<u64> {
    let (whole, fraction) = text.trim().split_once('.')?;
    let parts: Vec<&str> = whole.split(':').collect();
    let (hours, minutes, seconds) = match parts.as_slice() {
        [minutes, seconds] => ("0", *minutes, *seconds),
        [hours, minutes, seconds] => (*hours, *minutes, *seconds),
        _ => return None,
    };
    let millis: String = fraction.chars().take(3).collect();
    let millis = format!("{millis:0<3}");
    let total = hours.parse::<u64>().ok()? * 3_600_000
        + minutes.parse::<u64>().ok()? * 60_000
        + seconds.parse::<u64>().ok()? * 1_000
        + millis.parse::<u64>().ok()?;
    Some(total)
}

fn timing(line: &str) -> Option<(u64, u64)> {
    let (start, rest) = line.split_once("-->")?;
    let end = rest.split_whitespace().next()?;
    Some((clock_ms(start)?, clock_ms(end)?))
}

fn strip_markup(text: &str) -> String {
    let mut plain = String::new();
    let mut inside = false;
    for character in text.chars() {
        match character {
            '<' => inside = true,
            '>' if inside => inside = false,
            _ if inside => {}
            other => plain.push(other),
        }
    }
    plain
        .replace("&amp;", "&")
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&nbsp;", " ")
        .replace("&quot;", "\"")
}

fn clean_line(line: &str) -> String {
    strip_markup(line)
        .chars()
        .filter(|character| !INVISIBLE.contains(character))
        .collect::<String>()
        .trim()
        .to_string()
}

fn cue_of(block: &str) -> Option<Cue> {
    let mut lines = block.lines();
    let (start_ms, end_ms) = lines.by_ref().find_map(timing)?;
    let text = lines
        .map(clean_line)
        .filter(|line| !line.is_empty())
        .collect::<Vec<_>>()
        .join("\n");
    (!text.is_empty() && end_ms > start_ms).then_some(Cue {
        start_ms,
        end_ms,
        text,
    })
}

pub fn parse_vtt(text: &str) -> Vec<Cue> {
    let normalized = text.replace("\r\n", "\n").replace('\r', "\n");
    let mut cues: Vec<Cue> = normalized
        .split("\n\n")
        .map(str::trim)
        .filter(|block| {
            !(block.starts_with("WEBVTT")
                || block.starts_with("NOTE")
                || block.starts_with("STYLE")
                || block.starts_with("REGION"))
        })
        .filter_map(cue_of)
        .take(MAX_CUES)
        .collect();
    cues.sort_by_key(|cue| cue.start_ms);
    cues
}

#[cfg(test)]
mod tests {
    use super::*;

    const SAMPLE: &str = "WEBVTT\n\n00:12.095 --> 00:16.015\n\u{200e}Gyro Zeppeli finishes!\n\n00:16.766 --> 00:20.937\n\u{200e}We have our first stage champion!\n";

    #[test]
    fn a_plain_file_yields_its_cues_in_milliseconds() {
        let cues = parse_vtt(SAMPLE);
        assert_eq!(cues.len(), 2);
        assert_eq!(
            cues[0],
            Cue {
                start_ms: 12_095,
                end_ms: 16_015,
                text: "Gyro Zeppeli finishes!".into()
            }
        );
        assert_eq!(cues[1].start_ms, 16_766);
    }

    #[test]
    fn hours_ids_and_settings_are_understood() {
        let text =
            "WEBVTT\n\nintro\n01:02:03.500 --> 01:02:05.250 align:start position:0%\nSatu\nDua\n";
        let cues = parse_vtt(text);
        assert_eq!(cues[0].start_ms, 3_723_500);
        assert_eq!(cues[0].end_ms, 3_725_250);
        assert_eq!(cues[0].text, "Satu\nDua");
    }

    #[test]
    fn markup_and_entities_are_removed() {
        let text = "WEBVTT\n\n00:01.000 --> 00:02.000\n<i>Halo</i> &amp; <c.yellow>selamat</c> &lt;datang&gt;\n";
        assert_eq!(parse_vtt(text)[0].text, "Halo & selamat <datang>");
    }

    #[test]
    fn notes_styles_regions_and_empty_cues_are_skipped() {
        let text = "WEBVTT\n\nNOTE komentar\n\nSTYLE\n::cue { color: red }\n\n00:01.000 --> 00:02.000\n\n00:03.000 --> 00:04.000\nada\n";
        let cues = parse_vtt(text);
        assert_eq!(cues.len(), 1);
        assert_eq!(cues[0].text, "ada");
    }

    #[test]
    fn windows_line_endings_work_too() {
        let text = "WEBVTT\r\n\r\n00:01.000 --> 00:02.000\r\nIni\r\n\r\n00:03.000 --> 00:04.000\r\nItu\r\n";
        assert_eq!(parse_vtt(text).len(), 2);
    }

    #[test]
    fn cues_come_back_sorted_and_a_backwards_one_is_dropped() {
        let text = "WEBVTT\n\n00:09.000 --> 00:10.000\nakhir\n\n00:01.000 --> 00:02.000\nawal\n\n00:07.000 --> 00:06.000\nsalah\n";
        let order: Vec<String> = parse_vtt(text).into_iter().map(|cue| cue.text).collect();
        assert_eq!(order, ["awal", "akhir"]);
    }

    #[test]
    fn short_fractions_are_padded_and_garbage_gives_nothing() {
        let text = "WEBVTT\n\n00:01.5 --> 00:02.25\nok\n";
        let cues = parse_vtt(text);
        assert_eq!((cues[0].start_ms, cues[0].end_ms), (1_500, 2_250));
        assert!(parse_vtt("").is_empty());
        assert!(parse_vtt("<html>nope</html>").is_empty());
        assert!(parse_vtt("WEBVTT\n\nx --> y\nteks\n").is_empty());
    }

    #[test]
    fn a_huge_file_is_capped() {
        let mut text = String::from("WEBVTT\n\n");
        for index in 0..(MAX_CUES + 50) {
            let second = index % 60;
            let minute = (index / 60) % 60;
            text.push_str(&format!(
                "{minute:02}:{second:02}.000 --> {minute:02}:{second:02}.500\ncue {index}\n\n"
            ));
        }
        assert_eq!(parse_vtt(&text).len(), MAX_CUES);
    }
}
