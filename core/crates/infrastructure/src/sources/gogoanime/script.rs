const SCRIPT: &str = r#"(() => {
if(typeof jwplayer!=='function')return null;
let player;
let item;
let duration;
try{player=jwplayer();item=player.getPlaylistItem();duration=player.getDuration();}catch(error){return null;}
if(!item||!item.file)return null;
if(!(duration>0))return null;
const now=Date.now();
if(!window.__kolektakuSeen)window.__kolektakuSeen=now;
if(now-window.__kolektakuSeen<900)return null;
const given=(kind,value)=>value&&isFinite(value.start)&&isFinite(value.end)&&value.end>value.start?[{kind:kind,start:value.start,end:value.end}]:[];
const direct=given('intro',window.intro).concat(given('outro',window.outro));
const painted=Array.from(document.querySelectorAll('.osp-mark')).map(element=>{
const left=parseFloat(element.style.left);
const width=parseFloat(element.style.width);
return{kind:element.className.indexOf('outro')>=0?'outro':'intro',start:left*duration/100,end:(left+width)*duration/100};
}).filter(mark=>isFinite(mark.start)&&isFinite(mark.end));
const marks=direct.length>0?direct:painted;
const tracks=(item.tracks||[]).map(track=>({file:track.file||'',label:track.label||'',kind:track.kind||'',default:!!track.default}));
return JSON.stringify({origin:location.origin,file:item.file,image:item.image||'',duration:duration,tracks:tracks,marks:marks});
})()"#;

pub fn stream_script() -> &'static str {
    SCRIPT
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_is_one_self_calling_expression() {
        let script = stream_script();
        assert!(script.starts_with("(() => {") && script.ends_with("})()"));
    }

    #[test]
    fn it_waits_for_the_player_the_duration_and_the_skip_marks() {
        let script = stream_script();
        assert!(script.contains("jwplayer"));
        assert!(script.contains("getPlaylistItem"));
        assert!(script.contains("getDuration"));
        assert!(script.contains(".osp-mark"));
        assert!(script.contains("return null"));
    }

    #[test]
    fn it_reads_the_skip_ranges_the_player_page_publishes_before_the_painted_marks() {
        let script = stream_script();
        assert!(script.contains("window.intro"));
        assert!(script.contains("window.outro"));
        assert!(script.contains("direct.length>0?direct:painted"));
    }

    #[test]
    fn it_reports_everything_the_parser_reads() {
        let script = stream_script();
        for field in ["origin:", "file:item.file", "image:", "tracks:", "marks:"] {
            assert!(script.contains(field), "{field}");
        }
    }

    #[test]
    fn it_has_no_network_calls_and_no_navigation() {
        let script = stream_script();
        for forbidden in ["fetch(", "XMLHttpRequest", "location.href", "window.open", "eval("] {
            assert!(!script.contains(forbidden), "{forbidden}");
        }
    }
}
