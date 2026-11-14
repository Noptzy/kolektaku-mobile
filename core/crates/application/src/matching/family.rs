use domain::media::MediaFormat;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FormatFamily {
    Series,
    Movie,
    Short,
    Music,
    Book,
}

pub fn family_of_format(format: Option<MediaFormat>) -> Option<FormatFamily> {
    match format? {
        MediaFormat::Tv | MediaFormat::TvShort | MediaFormat::Ona => Some(FormatFamily::Series),
        MediaFormat::Movie => Some(FormatFamily::Movie),
        MediaFormat::Ova | MediaFormat::Special => Some(FormatFamily::Short),
        MediaFormat::Music => Some(FormatFamily::Music),
        MediaFormat::Manga | MediaFormat::OneShot | MediaFormat::Novel => Some(FormatFamily::Book),
    }
}

pub fn family_of_type(type_text: Option<&str>) -> Option<FormatFamily> {
    let value = type_text?.to_lowercase();
    let has = |words: &[&str]| words.iter().any(|word| value.contains(word));
    if has(&["movie", "film"]) {
        Some(FormatFamily::Movie)
    } else if has(&["ova", "oad", "special"]) {
        Some(FormatFamily::Short)
    } else if has(&["music"]) {
        Some(FormatFamily::Music)
    } else if has(&[
        "manga", "manhwa", "manhua", "komik", "webtoon", "doujin", "novel",
    ]) || mentions_one_shot(&value)
    {
        Some(FormatFamily::Book)
    } else if has(&["tv", "ona", "series"]) {
        Some(FormatFamily::Series)
    } else {
        None
    }
}

fn mentions_one_shot(value: &str) -> bool {
    value.match_indices("one").any(|(start, _)| {
        let rest = &value[start + 3..];
        rest.starts_with("shot")
            || rest
                .chars()
                .next()
                .is_some_and(|separator| rest[separator.len_utf8()..].starts_with("shot"))
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn catalog_formats_map_to_families() {
        assert_eq!(
            family_of_format(Some(MediaFormat::TvShort)),
            Some(FormatFamily::Series)
        );
        assert_eq!(
            family_of_format(Some(MediaFormat::Movie)),
            Some(FormatFamily::Movie)
        );
        assert_eq!(
            family_of_format(Some(MediaFormat::Special)),
            Some(FormatFamily::Short)
        );
        assert_eq!(
            family_of_format(Some(MediaFormat::Novel)),
            Some(FormatFamily::Book)
        );
        assert_eq!(family_of_format(None), None);
    }

    #[test]
    fn provider_type_text_maps_to_families() {
        assert_eq!(family_of_type(Some("TV")), Some(FormatFamily::Series));
        assert_eq!(family_of_type(Some("Movie")), Some(FormatFamily::Movie));
        assert_eq!(family_of_type(Some("OVA")), Some(FormatFamily::Short));
        assert_eq!(family_of_type(Some("Manhwa")), Some(FormatFamily::Book));
        assert_eq!(family_of_type(Some("One-Shot")), Some(FormatFamily::Book));
        assert_eq!(family_of_type(Some("oneshot")), Some(FormatFamily::Book));
        assert_eq!(family_of_type(Some("???")), None);
        assert_eq!(family_of_type(None), None);
    }
}
