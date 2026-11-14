mod links;
mod tags;
mod tidy;

pub use links::extract_urls;

use tags::{escape_text, read_tag, render_tag};

pub fn sanitize_description(html: &str) -> String {
    let text = tidy::remove_spoilers(html);
    let rendered = render_tags(&text);
    let text = tidy::collapse_newlines(&rendered);
    let text = tidy::collapse_breaks(&text);
    let text = tidy::trim_breaks(&text);
    tidy::collapse_spaces(&text)
}

fn render_tags(text: &str) -> String {
    let mut result = String::new();
    let mut plain_start = 0;
    let mut index = 0;
    while index < text.len() {
        let Some(tag) = text[index..]
            .starts_with('<')
            .then(|| read_tag(&text[index..]))
            .flatten()
        else {
            index += text[index..].chars().next().map_or(1, char::len_utf8);
            continue;
        };
        result.push_str(&escape_text(&text[plain_start..index]));
        result.push_str(render_tag(&tag));
        index += tag.length;
        plain_start = index;
    }
    result.push_str(&escape_text(&text[plain_start..]));
    result
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn keeps_only_line_breaks_bold_and_italic() {
        assert_eq!(
            sanitize_description("<p>Halo <b>dunia</b> <i>ini</i><br><br />\n<br>baris</p>"),
            "Halo <b>dunia</b> <i>ini</i><br><br>baris"
        );
    }

    #[test]
    fn maps_strong_and_em_and_strips_attributes() {
        assert_eq!(
            sanitize_description(
                "<strong class=\"x\" onclick=\"evil()\">a</strong><em style=\"y\">b</em>"
            ),
            "<b>a</b><i>b</i>"
        );
    }

    #[test]
    fn removes_scripts_images_links_and_every_other_tag() {
        let html = "a<script>alert(1)</script><img src=x onerror=alert(2)><a href=\"javascript:evil()\">link</a>b";
        let cleaned = sanitize_description(html);
        for forbidden in ["<script", "<img", "<a ", "onerror"] {
            assert!(!cleaned.contains(forbidden), "{forbidden} in {cleaned}");
        }
        assert!(cleaned.starts_with('a') && cleaned.ends_with('b'));
    }

    #[test]
    fn drops_spoiler_blocks_including_multi_line_ones() {
        assert_eq!(
            sanitize_description("Awal ~!bocoran\nsangat rahasia!~ akhir"),
            "Awal akhir"
        );
    }

    #[test]
    fn escapes_stray_angle_brackets_and_leaves_entities_alone() {
        assert_eq!(
            sanitize_description("3 < 5 &amp; 6 > 2"),
            "3 &lt; 5 &amp; 6 &gt; 2"
        );
        assert_eq!(
            sanitize_description("ends with <img src=x"),
            "ends with &lt;img src=x"
        );
    }

    #[test]
    fn trims_leading_and_trailing_breaks_and_collapses_long_runs() {
        assert_eq!(
            sanitize_description("<br><br>a<br><br><br><br>b<br>"),
            "a<br><br>b"
        );
    }

    #[test]
    fn keeps_non_ascii_text_intact() {
        assert_eq!(sanitize_description("<p>君の名は。</p>"), "君の名は。");
    }
}
