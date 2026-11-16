use scraper::ElementRef;
use url::Url;

use super::html::absolute_url;

const IMAGE_ATTRIBUTES: [&str; 4] = ["data-src", "data-lazy-src", "data-original", "src"];

pub fn image_of(element: ElementRef, base: &Url) -> Option<String> {
    IMAGE_ATTRIBUTES
        .iter()
        .filter_map(|name| element.value().attr(name))
        .map(str::trim)
        .filter(|value| !value.is_empty() && !value.starts_with("data:"))
        .filter_map(|value| absolute_url(value, base))
        .find(|url| url.starts_with("http://") || url.starts_with("https://"))
}

#[cfg(test)]
mod tests {
    use scraper::Html;

    use super::*;
    use crate::sources::support::selector;

    fn first_image(html: &str) -> Option<String> {
        let document = Html::parse_fragment(html);
        let base = Url::parse("https://site.test/novel/x/").unwrap();
        let image = document.select(&selector("img")).next().unwrap();
        image_of(image, &base)
    }

    #[test]
    fn a_lazy_image_uses_its_real_address_not_the_placeholder() {
        let html = r#"<img class="lazy" src="data:image/gif;base64,R0lGOD" data-src="/img/a.jpg">"#;
        assert_eq!(
            first_image(html).as_deref(),
            Some("https://site.test/img/a.jpg")
        );
    }

    #[test]
    fn a_plain_image_uses_src() {
        let html = r#"<img src="https://cdn.test/b.png">"#;
        assert_eq!(first_image(html).as_deref(), Some("https://cdn.test/b.png"));
    }

    #[test]
    fn other_lazy_attributes_are_understood() {
        let html = r#"<img src="" data-lazy-src="//cdn.test/c.webp">"#;
        assert_eq!(
            first_image(html).as_deref(),
            Some("https://cdn.test/c.webp")
        );
    }

    #[test]
    fn an_image_with_only_a_placeholder_gives_nothing() {
        let html = r#"<img src="data:image/gif;base64,R0lGOD">"#;
        assert_eq!(first_image(html), None);
    }
}
