use updater::{Asset, Progress, Update};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct UpdateOfferDto {
    pub version: String,
    pub notes: String,
    pub abi: String,
    pub url: String,
    pub size: u64,
    pub sha256: String,
    pub required: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct UpdateProgressDto {
    pub received: u64,
    pub total: u64,
    pub path: Option<String>,
}

pub fn offer_dto(update: &Update, required: bool) -> UpdateOfferDto {
    UpdateOfferDto {
        version: update.version.to_string(),
        notes: update.notes.clone(),
        abi: update.abi.clone(),
        url: update.asset.url.clone(),
        size: update.asset.size,
        sha256: update.asset.sha256.clone(),
        required,
    }
}

pub fn asset_of(offer: &UpdateOfferDto) -> Asset {
    Asset {
        url: offer.url.clone(),
        size: offer.size,
        sha256: offer.sha256.clone(),
    }
}

pub fn progress_dto(progress: Progress) -> UpdateProgressDto {
    UpdateProgressDto {
        received: progress.received,
        total: progress.total,
        path: None,
    }
}

pub fn finished_dto(total: u64, path: String) -> UpdateProgressDto {
    UpdateProgressDto {
        received: total,
        total,
        path: Some(path),
    }
}
