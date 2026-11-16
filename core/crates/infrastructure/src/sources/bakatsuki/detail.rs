use domain::error::SourceError;
use domain::source::{ItemId, SourceDetail, SourceItem, Unit};
use scraper::{ElementRef, Html};
use url::Url;

use super::pictures::cover_of;
use crate::sources::support::{collapse, selector, text_of};

const TYPE_TEXT: &str = "Light Novel";
const SUBPAGE_STARTS: [&str; 8] = [
    "volume",
    "chapter",
    "prologue",
    "epilogue",
    "afterword",
    "illustration",
    "side story",
    "short story",
];

fn series_name(item: &str) -> String {
    item.replace('_', " ")
}

fn page_title(href: &str, base: &Url) -> Option<String> {
    if href.contains("action=") || href.contains("redlink") {
        return None;
    }
    let url = base.join(href).ok()?;
    let (_, title) = url.query_pairs().find(|(key, _)| key == "title")?;
    Some(title.replace('_', " "))
}

fn is_full_text(subpage: &str) -> bool {
    let rest = subpage.to_lowercase();
    let rest = rest.trim_start_matches("volume").trim();
    !rest.is_empty() && rest.chars().all(|symbol| symbol.is_ascii_digit())
}

fn is_chapter_page(subpage: &str) -> bool {
    let lowered = subpage.to_lowercase();
    SUBPAGE_STARTS.iter().any(|start| lowered.starts_with(start)) && !is_full_text(subpage)
}

fn volume_number(subpage: &str) -> Option<String> {
    let lowered = subpage.to_lowercase();
    let rest = lowered.strip_prefix("volume")?.trim_start();
    let digits: String = rest.chars().take_while(char::is_ascii_digit).collect();
    (!digits.is_empty()).then_some(digits)
}

fn label_of(subpage: &str, link_text: &str) -> String {
    let text = collapse(link_text);
    let text = if text.is_empty() { subpage.to_string() } else { text };
    match volume_number(subpage) {
        Some(number) => format!("Vol {number} \u{b7} {text}"),
        None => text,
    }
}

pub fn parse_units(html: &str, item: &str, base: &Url) -> Vec<Unit> {
    let document = Html::parse_document(html);
    let prefix = format!("{}:", series_name(item));
    let mut units: Vec<Unit> = Vec::new();
    for anchor in document.select(&selector(".mw-parser-output a[href]")) {
        let href = anchor.value().attr("href").unwrap_or_default();
        let Some(title) = page_title(href, base) else {
            continue;
        };
        let Some(subpage) = title.strip_prefix(&prefix) else {
            continue;
        };
        let id = title.replace(' ', "_");
        if !is_chapter_page(subpage) || units.iter().any(|known| known.id == id) {
            continue;
        }
        let number = (units.len() + 1) as f64;
        units.push(Unit::new(id, number, label_of(subpage, &text_of(anchor))));
    }
    units
}

fn synopsis_of(document: &Html) -> String {
    let mut found: Vec<String> = Vec::new();
    let mut inside = false;
    let Some(container) = document.select(&selector(".mw-parser-output")).next() else {
        return String::new();
    };
    for child in container.children().filter_map(ElementRef::wrap) {
        let name = child.value().name();
        if name == "h2" {
            if inside {
                break;
            }
            inside = child.select(&selector("#Story_Synopsis")).next().is_some();
        } else if inside && name == "p" {
            let text = collapse(&text_of(child));
            if !text.is_empty() {
                found.push(text);
            }
        }
    }
    found.join("\n\n")
}

pub fn parse_detail(html: &str, item: &str, base: &Url) -> Result<SourceDetail, SourceError> {
    let document = Html::parse_document(html);
    let title = document
        .select(&selector("#firstHeading"))
        .next()
        .map(|heading| collapse(&text_of(heading)))
        .filter(|text| !text.is_empty())
        .ok_or_else(|| SourceError::MarkupChanged("detail title was not found".into()))?;
    let units = parse_units(html, item, base);
    let mut detail = SourceDetail::new(SourceItem {
        item_id: ItemId::new(item),
        title,
        cover_url: cover_of(&document, base),
        latest_label: None,
    });
    detail.type_text = Some(TYPE_TEXT.into());
    detail.unit_count = (!units.is_empty()).then_some(units.len() as u32);
    detail.synopsis = synopsis_of(&document);
    Ok(detail)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::fixtures;

    fn base() -> Url {
        Url::parse("https://www.baka-tsuki.org").unwrap()
    }

    fn page() -> String {
        fixtures::read("bakatsuki", "detail.html")
    }

    #[test]
    fn the_chapters_come_in_reading_order_with_volume_labels() {
        let units = parse_units(&page(), "Hyouka", &base());
        assert!(units.len() > 30);
        assert_eq!(units[0].id, "Hyouka:Volume_1_Chapter_1");
        assert_eq!(units[0].number, 1.0);
        assert_eq!(units[0].label, "Vol 1 \u{b7} 1 - Letter from Benares");
        assert!(units.iter().any(|unit| unit.label.contains("Illustrations")));
    }

    #[test]
    fn the_full_text_pages_are_not_listed_twice() {
        let units = parse_units(&page(), "Hyouka", &base());
        assert!(units.iter().all(|unit| unit.id != "Hyouka:Volume_1"));
        let mut ids: Vec<&str> = units.iter().map(|unit| unit.id.as_str()).collect();
        ids.sort_unstable();
        ids.dedup();
        assert_eq!(ids.len(), units.len());
    }

    #[test]
    fn pages_of_other_series_and_languages_are_not_chapters() {
        let html = r#"<div class="mw-parser-output">
            <a href="/project/index.php?title=Hyouka:Volume_1_Chapter_1">One</a>
            <a href="/project/index.php?title=Other:Volume_1_Chapter_1">Other</a>
            <a href="/project/index.php?title=Hyouka_PL">Polski</a>
            <a href="/project/index.php?title=Hyouka:Volume_9_Chapter_1&amp;action=edit&amp;redlink=1">Nope</a>
            <a href="/project/index.php?title=Hyouka:Registration_Page">Registration</a></div>"#;
        let units = parse_units(html, "Hyouka", &base());
        assert_eq!(units.len(), 1);
    }

    #[test]
    fn the_detail_has_title_cover_synopsis_and_count() {
        let detail = parse_detail(&page(), "Hyouka", &base()).unwrap();
        assert_eq!(detail.item.title, "Hyouka");
        assert_eq!(detail.item.item_id.as_str(), "Hyouka");
        assert!(detail.item.cover_url.unwrap().contains("thumb.php?f=Hyouka_01.jpg"));
        assert!(detail.synopsis.contains("Houtarou"));
        assert!(detail.unit_count.unwrap() > 30);
        assert_eq!(detail.type_text.as_deref(), Some("Light Novel"));
    }

    #[test]
    fn a_page_without_a_heading_is_a_markup_change() {
        let result = parse_detail("<main>redesigned</main>", "Hyouka", &base());
        assert!(matches!(result, Err(SourceError::MarkupChanged(_))));
    }
}
