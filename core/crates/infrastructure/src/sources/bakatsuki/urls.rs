use domain::error::SourceError;
use url::Url;

const CATEGORY: &str = "Category:Light novel (English)";
const MAX_TITLE_CHARS: usize = 200;
const FORBIDDEN: [char; 8] = ['#', '<', '>', '[', ']', '|', '{', '}'];

#[derive(Debug, Clone)]
pub struct BakaTsukiUrls {
    base: Url,
}

fn climbs_folders(title: &str) -> bool {
    let parts: Vec<&str> = title.split('/').collect();
    parts.len() > 1 && parts.iter().any(|part| *part == "." || *part == "..")
        || title == "."
        || title == ".."
}

fn not_found(value: &str) -> SourceError {
    SourceError::NotFound(format!("not a valid page title: {value}"))
}

impl BakaTsukiUrls {
    pub fn new(base_url: &str) -> Result<Self, SourceError> {
        let base = Url::parse(base_url)
            .ok()
            .filter(|url| matches!(url.scheme(), "http" | "https") && url.host_str().is_some())
            .ok_or_else(|| {
                SourceError::Unsupported(format!("invalid source address: {base_url}"))
            })?;
        Ok(Self { base })
    }

    pub fn base(&self) -> &Url {
        &self.base
    }

    fn at(&self, path: &str) -> Url {
        let mut url = self.base.clone();
        url.set_path(path);
        url.set_query(None);
        url
    }

    pub fn categories(&self) -> String {
        let mut url = self.at("/project/api.php");
        url.query_pairs_mut()
            .append_pair("action", "query")
            .append_pair("list", "categorymembers")
            .append_pair("cmtitle", CATEGORY)
            .append_pair("cmlimit", "500")
            .append_pair("cmnamespace", "0")
            .append_pair("format", "json");
        url.into()
    }

    pub fn page(&self, title: &str) -> Result<String, SourceError> {
        let spaced = title.replace('_', " ");
        let clean = spaced.trim();
        let bad = clean.is_empty()
            || climbs_folders(clean)
            || clean.chars().count() > MAX_TITLE_CHARS
            || clean
                .chars()
                .any(|symbol| symbol.is_control() || FORBIDDEN.contains(&symbol));
        if bad {
            return Err(not_found(title));
        }
        let mut url = self.at("/project/index.php");
        url.query_pairs_mut().append_pair("title", clean);
        Ok(url.into())
    }
}
