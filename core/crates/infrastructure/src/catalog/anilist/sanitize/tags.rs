pub struct Tag {
    pub name: String,
    pub closing: bool,
    pub length: usize,
}

pub fn read_tag(text: &str) -> Option<Tag> {
    let rest = text.strip_prefix('<')?;
    let (closing, rest) = match rest.strip_prefix('/') {
        Some(after) => (true, after),
        None => (false, rest),
    };
    if !rest.starts_with(|c: char| c.is_ascii_alphabetic()) {
        return None;
    }
    let name_length = rest
        .find(|c: char| !c.is_ascii_alphanumeric())
        .unwrap_or(rest.len());
    let after_name = &rest[name_length..];
    if after_name.starts_with('_') {
        return None;
    }
    let close = after_name.find('>')?;
    let length = text.len() - after_name.len() + close + 1;
    Some(Tag {
        name: rest[..name_length].to_lowercase(),
        closing,
        length,
    })
}

pub fn render_tag(tag: &Tag) -> &'static str {
    match (tag.name.as_str(), tag.closing) {
        ("p", true) => "<br><br>",
        ("br", false) => "<br>",
        ("b" | "strong", false) => "<b>",
        ("b" | "strong", true) => "</b>",
        ("i" | "em", false) => "<i>",
        ("i" | "em", true) => "</i>",
        _ => "",
    }
}

pub fn escape_text(text: &str) -> String {
    text.replace('<', "&lt;").replace('>', "&gt;")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_opening_closing_and_self_closing_tags() {
        let open = read_tag("<b class=\"x\">rest").unwrap();
        assert_eq!(
            (open.name.as_str(), open.closing, open.length),
            ("b", false, 13)
        );
        let close = read_tag("</STRONG>").unwrap();
        assert_eq!((close.name.as_str(), close.closing), ("strong", true));
        assert_eq!(read_tag("<br />x").unwrap().length, 6);
    }

    #[test]
    fn rejects_text_that_only_looks_like_a_tag() {
        assert!(read_tag("< 5").is_none());
        assert!(read_tag("<img src=x").is_none());
        assert!(read_tag("<a_b>").is_none());
        assert!(read_tag("<3>").is_none());
        assert!(read_tag("plain").is_none());
    }

    #[test]
    fn only_breaks_bold_and_italic_survive() {
        let render = |text: &str| render_tag(&read_tag(text).unwrap());
        assert_eq!(render("<p>"), "");
        assert_eq!(render("</p>"), "<br><br>");
        assert_eq!(render("<br>"), "<br>");
        assert_eq!(render("</br>"), "");
        assert_eq!(render("<em>"), "<i>");
        assert_eq!(render("</strong>"), "</b>");
        assert_eq!(render("<script>"), "");
        assert_eq!(render("<a href=\"javascript:evil()\">"), "");
    }

    #[test]
    fn escapes_angle_brackets_only() {
        assert_eq!(escape_text("3 < 5 &amp; 6 > 2"), "3 &lt; 5 &amp; 6 &gt; 2");
    }
}
