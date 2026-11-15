use domain::error::SourceError;
use domain::translation::TranslationReply;
use serde_json::Value;

pub fn read_reply(body: &str) -> Result<TranslationReply, SourceError> {
    let parsed: Value = serde_json::from_str(body).map_err(changed)?;
    let items = parsed
        .as_array()
        .ok_or_else(|| changed("the reply is not a list"))?;
    let mut lines = Vec::with_capacity(items.len());
    let mut detected_from = None;
    for item in items {
        let (text, language) = text_and_language(item)?;
        detected_from = detected_from.or(language);
        lines.push(text);
    }
    Ok(TranslationReply::new(lines, detected_from))
}

fn text_and_language(item: &Value) -> Result<(String, Option<String>), SourceError> {
    match item {
        Value::String(text) => Ok((text.clone(), None)),
        Value::Array(pair) => {
            let text = pair
                .first()
                .and_then(Value::as_str)
                .ok_or_else(|| changed("a list item has no text"))?;
            let language = pair.get(1).and_then(Value::as_str).map(str::to_string);
            Ok((text.to_string(), language))
        }
        _ => Err(changed("a list item is neither text nor a pair")),
    }
}

fn changed(detail: impl ToString) -> SourceError {
    SourceError::MarkupChanged(format!("translate reply: {}", detail.to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::fixtures;

    #[test]
    fn a_list_of_strings_keeps_its_order_and_decodes_escapes() {
        let reply = read_reply(&fixtures::translate("explicit_multi.json")).unwrap();
        assert_eq!(reply.lines.len(), 3);
        assert_eq!(reply.lines[0], "Halo, apa kabarmu?");
        assert_eq!(reply.lines[2], "<i>Tunggu aku!</i>");
        assert_eq!(reply.detected_from, None);
    }

    #[test]
    fn pairs_give_the_text_and_the_detected_language() {
        let reply = read_reply(&fixtures::translate("auto_multi.json")).unwrap();
        assert_eq!(
            reply.lines,
            vec!["Halo, apa kabarmu?", "Selamat pagi semuanya."]
        );
        assert_eq!(reply.detected_from.as_deref(), Some("en"));
    }

    #[test]
    fn a_single_line_comes_back_as_a_list_of_one() {
        let plain = read_reply(&fixtures::translate("explicit_single.json")).unwrap();
        assert_eq!(plain.lines, vec!["Hanya satu baris."]);
        let auto = read_reply(&fixtures::translate("auto_single.json")).unwrap();
        assert_eq!(auto.lines, vec!["Hanya satu baris."]);
        assert_eq!(auto.detected_from.as_deref(), Some("en"));
    }

    #[test]
    fn an_empty_list_is_an_empty_answer() {
        let reply = read_reply("[]").unwrap();
        assert!(reply.lines.is_empty());
    }

    #[test]
    fn anything_that_is_not_a_list_means_the_service_changed() {
        for body in [
            "<html>blocked</html>",
            r#"{"error":"x"}"#,
            "\"text\"",
            "",
            "42",
        ] {
            assert!(
                matches!(read_reply(body), Err(SourceError::MarkupChanged(_))),
                "{body}"
            );
        }
    }

    #[test]
    fn an_item_of_the_wrong_kind_means_the_service_changed() {
        for body in ["[1]", "[null]", "[[]]", "[[5,\"en\"]]", "[{\"a\":1}]"] {
            assert!(
                matches!(read_reply(body), Err(SourceError::MarkupChanged(_))),
                "{body}"
            );
        }
    }
}
