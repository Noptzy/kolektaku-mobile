use std::path::{Path, PathBuf};

use sha2::{Digest, Sha256};
use tokio::fs::{self, File, OpenOptions};
use tokio::io::{AsyncReadExt, AsyncWriteExt};

use crate::error::UpdateError;
use crate::manifest::{Asset, host_allowed};
use crate::transport::Transport;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Progress {
    pub received: u64,
    pub total: u64,
}

fn partial_of(destination: &Path) -> PathBuf {
    let mut name = destination.as_os_str().to_os_string();
    name.push(".part");
    PathBuf::from(name)
}

async fn length_of(path: &Path) -> u64 {
    fs::metadata(path).await.map(|meta| meta.len()).unwrap_or(0)
}

async fn hash_of(path: &Path) -> Result<String, UpdateError> {
    let mut file = File::open(path).await?;
    let mut hasher = Sha256::new();
    let mut buffer = vec![0u8; 64 * 1024];
    loop {
        let read = file.read(&mut buffer).await?;
        if read == 0 {
            break;
        }
        hasher.update(&buffer[..read]);
    }
    Ok(hasher
        .finalize()
        .iter()
        .map(|byte| format!("{byte:02x}"))
        .collect())
}

async fn stream_into(
    transport: &dyn Transport,
    asset: &Asset,
    partial: &Path,
    from: u64,
    on_progress: &mut (dyn FnMut(Progress) + Send),
) -> Result<bool, UpdateError> {
    let mut fetched = transport.fetch(&asset.url, from).await?;
    if !host_allowed(&fetched.url) {
        return Err(UpdateError::Untrusted(fetched.url));
    }
    if fetched.status == 416 {
        return Ok(false);
    }
    if fetched.status != 200 && fetched.status != 206 {
        return Err(UpdateError::Network(format!("answered {}", fetched.status)));
    }
    let resumed = fetched.status == 206 && from > 0;
    let mut file = if resumed {
        OpenOptions::new().append(true).open(partial).await?
    } else {
        File::create(partial).await?
    };
    let mut received = if resumed { from } else { 0 };
    let streamed: Result<(), UpdateError> = async {
        while let Some(chunk) = fetched.body.next().await? {
            file.write_all(&chunk).await?;
            received += chunk.len() as u64;
            on_progress(Progress {
                received,
                total: asset.size,
            });
        }
        Ok(())
    }
    .await;
    file.flush().await?;
    streamed?;
    Ok(true)
}

async fn verify(partial: &Path, asset: &Asset) -> Result<(), UpdateError> {
    let got = length_of(partial).await;
    if got != asset.size {
        let _ = fs::remove_file(partial).await;
        return Err(UpdateError::SizeMismatch {
            expected: asset.size,
            got,
        });
    }
    if hash_of(partial).await? != asset.sha256 {
        let _ = fs::remove_file(partial).await;
        return Err(UpdateError::HashMismatch);
    }
    Ok(())
}

pub async fn download(
    transport: &dyn Transport,
    asset: &Asset,
    destination: &Path,
    mut on_progress: impl FnMut(Progress) + Send,
) -> Result<PathBuf, UpdateError> {
    if !host_allowed(&asset.url) {
        return Err(UpdateError::Untrusted(asset.url.clone()));
    }
    if let Some(folder) = destination.parent() {
        fs::create_dir_all(folder).await?;
    }
    let partial = partial_of(destination);
    let mut have = length_of(&partial).await;
    if have > asset.size {
        let _ = fs::remove_file(&partial).await;
        have = 0;
    }
    if have < asset.size {
        let served = stream_into(transport, asset, &partial, have, &mut on_progress).await?;
        if !served {
            let _ = fs::remove_file(&partial).await;
            stream_into(transport, asset, &partial, 0, &mut on_progress).await?;
        }
    }
    verify(&partial, asset).await?;
    let _ = fs::remove_file(destination).await;
    fs::rename(&partial, destination).await?;
    Ok(destination.to_path_buf())
}
