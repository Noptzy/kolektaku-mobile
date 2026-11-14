const TEMPLATE: &str = r#"(() => {
const select=document.querySelector('#changeServer');
if(!select)return null;
if(select.value!==__SERVER__){select.value=__SERVER__;select.dispatchEvent(new Event('change',{bubbles:true}));}
const sources=Array.from(document.querySelectorAll('video source[src]'));
if(sources.length===0)return null;
const video=document.querySelector('video');
const attrs=['size','data-quality','data-resolution','res','label'];
const guess=url=>(url.match(/(?:^|[^0-9])(\d{3,4})p(?:[^0-9]|$)/i)||[])[1]||'';
const sourceData=sources.map(source=>({url:source.src,type:source.getAttribute('type')||'',quality:attrs.map(name=>source.getAttribute(name)).find(Boolean)||guess(source.src)}));
return JSON.stringify({poster:video?video.poster||'':'',sources:sourceData});
})()"#;

pub fn stream_script(server_id: &str) -> String {
    let quoted = serde_json::to_string(server_id).unwrap_or_else(|_| "\"\"".into());
    TEMPLATE.replace("__SERVER__", &quoted)
}

pub fn is_valid_server_id(server_id: &str) -> bool {
    !server_id.is_empty()
        && server_id
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-')
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_server_id_is_quoted_into_the_script_everywhere() {
        let script = stream_script("kuramadrive");
        assert_eq!(script.matches("\"kuramadrive\"").count(), 2);
        assert!(!script.contains("__SERVER__"));
    }

    #[test]
    fn the_script_asks_for_the_poster_and_the_sources_as_json() {
        let script = stream_script("mega");
        assert!(script.contains("video source[src]"));
        assert!(script.contains("JSON.stringify({poster"));
        assert!(script.starts_with("(() => {") && script.ends_with("})()"));
    }

    #[test]
    fn a_hostile_server_id_cannot_break_out_of_the_string() {
        let script = stream_script("x\";alert(1);//");
        assert!(script.contains(r#""x\";alert(1);//""#));
    }

    #[test]
    fn only_simple_server_ids_are_valid() {
        assert!(is_valid_server_id("kuramadrive"));
        assert!(is_valid_server_id("server_2-b"));
        assert!(!is_valid_server_id(""));
        assert!(!is_valid_server_id("a b"));
        assert!(!is_valid_server_id("x\";alert(1)"));
    }
}
