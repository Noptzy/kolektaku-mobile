use scraper::{ElementRef, Html};
use url::Url;

use crate::sources::support::{absolute_url, selector};

const PICTURE_MARK: &str = "thumb.php?f=";
const COVER_WIDTH: u32 = 400;
const PAGE_WIDTH: u32 = 1200;

fn with_width(address: &str, width: u32) -> String {
    let Some(start) = address.find("width=") else {
        return address.to_string();
    };
    let digits_from = start + "width=".len();
    let end = address[digits_from..]
        .find(|symbol: char| !symbol.is_ascii_digit())
        .map_or(address.len(), |at| digits_from + at);
    format!("{}{width}{}", &address[..digits_from], &address[end..])
}

pub fn picture_of(image: ElementRef, base: &Url, width: u32) -> Option<String> {
    let source = image.value().attr("src")?;
    if !source.contains(PICTURE_MARK) {
        return None;
    }
    let address = absolute_url(source, base)?;
    Some(with_width(&address, width))
}

pub fn page_picture(image: ElementRef, base: &Url) -> Option<String> {
    picture_of(image, base, PAGE_WIDTH)
}

pub fn cover_of(document: &Html, base: &Url) -> Option<String> {
    document
        .select(&selector(".mw-parser-output img"))
        .find_map(|image| picture_of(image, base, COVER_WIDTH))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn base() -> Url {
        Url::parse("https://www.baka-tsuki.org").unwrap()
    }

    #[test]
    fn the_width_in_the_address_is_replaced() {
        let address = "https://x.test/project/thumb.php?f=A.jpg&width=92";
        assert_eq!(
            with_width(address, 1200),
            "https://x.test/project/thumb.php?f=A.jpg&width=1200"
        );
        assert_eq!(with_width("https://x.test/a.jpg", 5), "https://x.test/a.jpg");
        assert_eq!(
            with_width("https://x.test/t.php?width=9&f=A", 7),
            "https://x.test/t.php?width=7&f=A"
        );
    }

    #[test]
    fn only_wiki_pictures_count_and_they_are_enlarged() {
        let html = Html::parse_fragment(
            r#"<div class="mw-parser-output"><img src="/project/images/5/53/Stalled.gif">
            <img src="/project/thumb.php?f=Hyouka_01.jpg&amp;width=300"></div>"#,
        );
        let cover = cover_of(&html, &base()).unwrap();
        assert_eq!(
            cover,
            "https://www.baka-tsuki.org/project/thumb.php?f=Hyouka_01.jpg&width=400"
        );
        let first = html.select(&selector("img")).next().unwrap();
        assert_eq!(page_picture(first, &base()), None);
    }
}
