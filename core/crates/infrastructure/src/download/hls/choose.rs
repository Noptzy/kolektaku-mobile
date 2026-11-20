use super::master::{AudioRendition, Variant};

fn rank(variant: &Variant) -> (u32, u64) {
    (variant.height.unwrap_or(0), variant.bandwidth)
}

pub fn choose_variant(variants: &[Variant], max_height: Option<u32>) -> Option<&Variant> {
    let ceiling = max_height.unwrap_or(u32::MAX);
    let fitting = variants
        .iter()
        .filter(|variant| variant.height.is_none_or(|height| height <= ceiling))
        .max_by_key(|variant| rank(variant));
    fitting.or_else(|| variants.iter().min_by_key(|variant| rank(variant)))
}

pub fn choose_audio<'a>(
    audio: &'a [AudioRendition],
    group: Option<&str>,
) -> Option<&'a AudioRendition> {
    let group = group?;
    let usable: Vec<&AudioRendition> = audio
        .iter()
        .filter(|rendition| rendition.group == group && rendition.url.is_some())
        .collect();
    usable
        .iter()
        .find(|rendition| rendition.is_default)
        .or_else(|| usable.first())
        .copied()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn variant(height: Option<u32>, bandwidth: u64) -> Variant {
        Variant {
            url: format!("{height:?}-{bandwidth}"),
            bandwidth,
            width: None,
            height,
            audio_group: Some("aud".into()),
        }
    }

    fn rendition(name: &str, group: &str, is_default: bool, url: bool) -> AudioRendition {
        AudioRendition {
            group: group.into(),
            name: name.into(),
            language: None,
            is_default,
            url: url.then(|| format!("{name}.m3u8")),
        }
    }

    #[test]
    fn the_tallest_picture_under_the_ceiling_wins() {
        let variants = [
            variant(Some(360), 1),
            variant(Some(720), 3),
            variant(Some(1080), 5),
        ];
        assert_eq!(
            choose_variant(&variants, Some(720)).unwrap().height,
            Some(720)
        );
        assert_eq!(choose_variant(&variants, None).unwrap().height, Some(1080));
    }

    #[test]
    fn when_nothing_fits_the_smallest_is_taken() {
        let variants = [variant(Some(720), 3), variant(Some(1080), 5)];
        assert_eq!(
            choose_variant(&variants, Some(360)).unwrap().height,
            Some(720)
        );
        assert!(choose_variant(&[], Some(720)).is_none());
    }

    #[test]
    fn without_heights_the_highest_bandwidth_wins() {
        let variants = [variant(None, 1), variant(None, 9)];
        assert_eq!(choose_variant(&variants, Some(720)).unwrap().bandwidth, 9);
    }

    #[test]
    fn the_default_audio_of_the_group_is_preferred() {
        let audio = [
            rendition("English", "aud", false, true),
            rendition("Japanese", "aud", true, true),
            rendition("Other", "x", true, true),
        ];
        assert_eq!(choose_audio(&audio, Some("aud")).unwrap().name, "Japanese");
        assert!(choose_audio(&audio, None).is_none());
    }

    #[test]
    fn audio_without_its_own_playlist_is_skipped() {
        let audio = [
            rendition("Muxed", "aud", true, false),
            rendition("English", "aud", false, true),
        ];
        assert_eq!(choose_audio(&audio, Some("aud")).unwrap().name, "English");
    }
}
