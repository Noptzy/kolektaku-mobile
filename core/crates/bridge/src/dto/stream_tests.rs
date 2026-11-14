use domain::stream::StreamKind;

use super::stream::{HeaderDto, ServerDto, StreamPlanDto, StreamPlanKind, StreamSetDto};
use domain::stream::{EpisodeServer, ServerVariant, StreamPlan, StreamSet, StreamSource};

#[test]
fn a_web_view_plan_keeps_url_script_and_host() {
    let plan = StreamPlan::NeedsWebView {
        url: "https://site.test/ep".into(),
        script: "(() => 1)()".into(),
        allowed_host: "site.test".into(),
    };
    let dto = StreamPlanDto::from(&plan);
    let (url, script, allowed_host) = (dto.url, dto.script, dto.allowed_host);
    assert_eq!(dto.kind, StreamPlanKind::NeedsWebView);
    assert!(dto.sources.is_empty() && dto.headers.is_empty());
    assert_eq!(
        (url.as_str(), script.as_str(), allowed_host.as_str()),
        ("https://site.test/ep", "(() => 1)()", "site.test")
    );
}

#[test]
fn a_direct_plan_carries_sources_and_headers() {
    let source = StreamSource {
        url: "https://cdn.test/a.m3u8".into(),
        kind: StreamKind::Hls,
        quality: 720,
        label: "720p".into(),
        is_default: true,
    };
    let plan = StreamPlan::Direct {
        sources: vec![source],
        headers: vec![("Referer".into(), "https://site.test/".into())],
    };
    let dto = StreamPlanDto::from(&plan);
    assert_eq!(dto.kind, StreamPlanKind::Direct);
    let (sources, headers) = (dto.sources, dto.headers);
    assert_eq!(sources[0].kind, "hls");
    assert_eq!(
        headers[0],
        HeaderDto {
            name: "Referer".into(),
            value: "https://site.test/".into()
        }
    );
}

#[test]
fn a_stream_set_keeps_its_poster_and_default_flag() {
    let source = StreamSource {
        url: "https://cdn.test/a.mp4".into(),
        kind: StreamKind::Mp4,
        quality: 480,
        label: "480p".into(),
        is_default: true,
    };
    let set = StreamSet::from_sources(vec![source], Some("https://img.test/p.jpg".into())).unwrap();
    let dto = StreamSetDto::from(&set);
    assert_eq!(dto.poster_url.as_deref(), Some("https://img.test/p.jpg"));
    assert!(dto.sources[0].is_default);
}

#[test]
fn a_server_variant_reaches_the_ui_as_plain_text() {
    let sub = ServerDto::from(&EpisodeServer::new("sub-1", "x").with_variant(ServerVariant::Sub));
    let dub = ServerDto::from(
        &EpisodeServer::new("dub-1", "y")
            .with_variant(ServerVariant::Dub)
            .with_audio("en"),
    );
    let plain = ServerDto::from(&EpisodeServer::new("mega", "Mega"));
    assert_eq!(sub.variant.as_deref(), Some("sub"));
    assert_eq!(dub.variant.as_deref(), Some("dub"));
    assert_eq!(dub.audio.as_deref(), Some("en"));
    assert_eq!(sub.audio, None);
    assert_eq!(plain.variant, None);
}
