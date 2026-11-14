use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream};

pub struct LocalServer {
    pub base_url: String,
}

pub enum Behavior {
    Echo { extra_header: Option<&'static str> },
    Silent,
}

impl LocalServer {
    pub async fn start(behavior: Behavior) -> Self {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let base_url = format!("http://{}", listener.local_addr().unwrap());
        tokio::spawn(async move {
            loop {
                let Ok((stream, _)) = listener.accept().await else {
                    return;
                };
                match &behavior {
                    Behavior::Echo { extra_header } => {
                        tokio::spawn(echo(stream, *extra_header));
                    }
                    Behavior::Silent => {
                        tokio::spawn(async move {
                            let _held = stream;
                            tokio::time::sleep(std::time::Duration::from_secs(30)).await;
                        });
                    }
                }
            }
        });
        Self { base_url }
    }
}

async fn read_request(stream: &mut TcpStream) -> String {
    let mut received = Vec::new();
    let mut chunk = [0u8; 2048];
    loop {
        let read = stream.read(&mut chunk).await.unwrap_or(0);
        if read == 0 {
            break;
        }
        received.extend_from_slice(&chunk[..read]);
        let text = String::from_utf8_lossy(&received).to_string();
        if request_is_complete(&text) {
            break;
        }
    }
    String::from_utf8_lossy(&received).to_string()
}

fn request_is_complete(text: &str) -> bool {
    let Some((head, body)) = text.split_once("\r\n\r\n") else {
        return false;
    };
    let wanted = head
        .lines()
        .filter_map(|line| {
            line.to_lowercase()
                .strip_prefix("content-length:")
                .map(str::to_string)
        })
        .find_map(|value| value.trim().parse::<usize>().ok())
        .unwrap_or(0);
    body.len() >= wanted
}

async fn echo(mut stream: TcpStream, extra_header: Option<&'static str>) {
    let request = read_request(&mut stream).await;
    let extra = extra_header
        .map(|line| format!("{line}\r\n"))
        .unwrap_or_default();
    let reply = format!(
        "HTTP/1.1 200 OK\r\ncontent-length: {}\r\n{extra}connection: close\r\n\r\n{request}",
        request.len()
    );
    let _ = stream.write_all(reply.as_bytes()).await;
    let _ = stream.shutdown().await;
}
