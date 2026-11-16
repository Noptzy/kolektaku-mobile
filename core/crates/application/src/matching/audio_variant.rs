pub const DUB_INDONESIAN: &str = "Dub Indonesia";
pub const DUB_ENGLISH: &str = "Dub Inggris";
pub const DUB_PLAIN: &str = "Dub";

const MARKERS: [(&str, &str); 8] = [
    ("dub indonesia", DUB_INDONESIAN),
    ("dub indo", DUB_INDONESIAN),
    ("dub id", DUB_INDONESIAN),
    ("english dub", DUB_ENGLISH),
    ("dub english", DUB_ENGLISH),
    ("dub eng", DUB_ENGLISH),
    ("dub en", DUB_ENGLISH),
    ("dub", DUB_PLAIN),
];

const WRAPPERS: [(&str, &str); 3] = [("(", ")"), ("[", "]"), ("", "")];

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SplitTitle {
    pub base: String,
    pub audio: Option<&'static str>,
}

fn separator(symbol: char) -> bool {
    symbol.is_whitespace() || matches!(symbol, '-' | '\u{2013}' | '\u{2014}' | ':')
}

fn base_before(title: &str, lowered: &str, start: usize, bare: bool) -> Option<String> {
    let previous = lowered[..start].chars().next_back();
    if bare && previous.is_some_and(|symbol| !separator(symbol)) {
        return None;
    }
    let base = title[..start].trim_end_matches(separator);
    (!base.is_empty()).then(|| base.to_string())
}

pub fn split_audio(title: &str) -> SplitTitle {
    let lowered = title.to_ascii_lowercase();
    let head = lowered.trim_end();
    for (core, label) in MARKERS {
        for (open, close) in WRAPPERS {
            let pattern = format!("{open}{core}{close}");
            if !head.ends_with(&pattern) {
                continue;
            }
            let start = head.len() - pattern.len();
            if let Some(base) = base_before(title, &lowered, start, open.is_empty()) {
                return SplitTitle {
                    base,
                    audio: Some(label),
                };
            }
        }
    }
    SplitTitle {
        base: title.trim().to_string(),
        audio: None,
    }
}

pub fn audio_variant_of(title: &str) -> Option<&'static str> {
    split_audio(title).audio
}

pub fn without_audio_marker(title: &str) -> String {
    split_audio(title).base
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn recognises_the_dub_markers_sites_use() {
        let cases = [
            ("Kimetsu no Yaiba (Dub ID)", DUB_INDONESIAN),
            ("Kimetsu no Yaiba Dub Indo", DUB_INDONESIAN),
            ("Kimetsu no Yaiba [Dub Indonesia]", DUB_INDONESIAN),
            ("Demon Slayer (English Dub)", DUB_ENGLISH),
            ("Demon Slayer English Dub", DUB_ENGLISH),
            ("Demon Slayer (Dub EN)", DUB_ENGLISH),
            ("Demon Slayer (Dub)", DUB_PLAIN),
            ("Demon Slayer Dub", DUB_PLAIN),
        ];
        for (title, label) in cases {
            assert_eq!(audio_variant_of(title), Some(label), "{title}");
        }
    }

    #[test]
    fn the_base_title_loses_only_the_marker() {
        assert_eq!(
            without_audio_marker("Kimetsu no Yaiba: Yuukaku-hen (Dub ID)"),
            "Kimetsu no Yaiba: Yuukaku-hen"
        );
        assert_eq!(without_audio_marker("Show - Dub Indo"), "Show");
    }

    #[test]
    fn plain_titles_are_not_variants() {
        for title in [
            "Kimetsu no Yaiba",
            "Dubu Dubu",
            "Sub Indo Show",
            "Show (Sub Indo)",
            "Dub",
            "Hidub",
        ] {
            assert_eq!(audio_variant_of(title), None, "{title}");
        }
        assert_eq!(without_audio_marker("  Show  "), "Show");
    }

    #[test]
    fn non_ascii_titles_split_on_the_right_byte() {
        let split = split_audio("鬼滅の刃 (Dub ID)");
        assert_eq!(split.base, "鬼滅の刃");
        assert_eq!(split.audio, Some(DUB_INDONESIAN));
    }
}
