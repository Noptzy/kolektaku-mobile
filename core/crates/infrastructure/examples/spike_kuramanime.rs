use scraper::{Html, Selector};

const EPISODE_URL: &str = "https://v20.kuramanime.ing/anime/5244/fx-senshi-kurumi-chan/episode/7";

#[tokio::main]
async fn main() {
    let client = reqwest::Client::builder()
        .user_agent("Mozilla/5.0 (Linux; Android 14) Kolektaku-Spike/1.0")
        .build()
        .expect("http client");

    let response = client
        .get(EPISODE_URL)
        .send()
        .await
        .expect("fetch episode page");
    let status = response.status();
    let body = response.text().await.expect("read body");
    println!("status: {status}");
    println!("body length: {} bytes", body.len());

    let document = Html::parse_document(&body);
    report_servers(&document);
    report_data_kk(&body);
    report_video_sources(&document);
}

fn report_servers(document: &Html) {
    let selector = Selector::parse("#changeServer option").unwrap();
    let servers: Vec<(String, String)> = document
        .select(&selector)
        .map(|option| {
            let id = option.value().attr("value").unwrap_or("").to_string();
            let label = option.text().collect::<String>().trim().to_string();
            (id, label)
        })
        .filter(|(id, label)| !id.is_empty() && !label.is_empty())
        .collect();
    println!("servers found: {}", servers.len());
    for (id, label) in &servers {
        println!("  - {id}: {label}");
    }
}

fn report_data_kk(body: &str) {
    match body.find("data-kk") {
        Some(_) => println!("data-kk attribute: found"),
        None => println!("data-kk attribute: NOT found"),
    }
}

fn report_video_sources(document: &Html) {
    let selector = Selector::parse("video source[src]").unwrap();
    let count = document.select(&selector).count();
    println!("video source[src] elements: {count}");
}
