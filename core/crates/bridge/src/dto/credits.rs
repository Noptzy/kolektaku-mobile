use domain::media::{
    Character, MediaDate, MediaDetail, NextAiring, Relation, Staff, Trailer, VoiceActor,
};

use super::episodes::EpisodeInfoDto;
use super::links::ExternalLinkDto;
use super::media::{MediaSummaryDto, tag};
use super::studio::StudioRefDto;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct DateDto {
    pub year: Option<u16>,
    pub month: Option<u8>,
    pub day: Option<u8>,
}

impl From<MediaDate> for DateDto {
    fn from(date: MediaDate) -> Self {
        Self {
            year: date.year,
            month: date.month,
            day: date.day,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct VoiceActorDto {
    pub id: u64,
    pub name: String,
    pub image_url: Option<String>,
    pub language: String,
}

impl From<&VoiceActor> for VoiceActorDto {
    fn from(actor: &VoiceActor) -> Self {
        Self {
            id: actor.id,
            name: actor.name.clone(),
            image_url: actor.image_url.clone(),
            language: actor.language.clone(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CharacterDto {
    pub id: u64,
    pub name: String,
    pub image_url: Option<String>,
    pub role: String,
    pub voice_actors: Vec<VoiceActorDto>,
}

impl From<&Character> for CharacterDto {
    fn from(character: &Character) -> Self {
        Self {
            id: character.id,
            name: character.name.clone(),
            image_url: character.image_url.clone(),
            role: tag(&character.role),
            voice_actors: character.voice_actors.iter().map(Into::into).collect(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StaffDto {
    pub id: u64,
    pub name: String,
    pub role: String,
    pub image_url: Option<String>,
}

impl From<&Staff> for StaffDto {
    fn from(staff: &Staff) -> Self {
        Self {
            id: staff.id,
            name: staff.name.clone(),
            role: staff.role.clone(),
            image_url: staff.image_url.clone(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TrailerDto {
    pub site: String,
    pub video_id: String,
    pub thumbnail_url: Option<String>,
}

impl From<&Trailer> for TrailerDto {
    fn from(trailer: &Trailer) -> Self {
        Self {
            site: tag(&trailer.site),
            video_id: trailer.video_id.clone(),
            thumbnail_url: trailer.thumbnail_url.clone(),
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct RelationDto {
    pub relation_type: String,
    pub media: MediaSummaryDto,
}

impl From<&Relation> for RelationDto {
    fn from(relation: &Relation) -> Self {
        Self {
            relation_type: tag(&relation.relation_type),
            media: (&relation.media).into(),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct NextAiringDto {
    pub episode: u32,
    pub airing_at_secs: u64,
}

impl From<NextAiring> for NextAiringDto {
    fn from(airing: NextAiring) -> Self {
        Self {
            episode: airing.episode,
            airing_at_secs: airing.airing_at_secs,
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct MediaDetailDto {
    pub summary: MediaSummaryDto,
    pub banner_url: Option<String>,
    pub description: String,
    pub studios: Vec<StudioRefDto>,
    pub source: Option<String>,
    pub season: Option<String>,
    pub start_date: DateDto,
    pub end_date: DateDto,
    pub duration_minutes: Option<u32>,
    pub site_url: Option<String>,
    pub characters: Vec<CharacterDto>,
    pub staff: Vec<StaffDto>,
    pub trailer: Option<TrailerDto>,
    pub relations: Vec<RelationDto>,
    pub recommendations: Vec<MediaSummaryDto>,
    pub next_airing: Option<NextAiringDto>,
    pub episodes: Vec<EpisodeInfoDto>,
    pub links: Vec<ExternalLinkDto>,
}

impl From<&MediaDetail> for MediaDetailDto {
    fn from(detail: &MediaDetail) -> Self {
        Self {
            summary: (&detail.summary).into(),
            banner_url: detail.banner_url.clone(),
            description: detail.description.clone(),
            studios: detail.studios.iter().map(Into::into).collect(),
            source: detail.source.clone(),
            season: detail.season.clone(),
            start_date: detail.start_date.into(),
            end_date: detail.end_date.into(),
            duration_minutes: detail.duration_minutes,
            site_url: detail.site_url.clone(),
            characters: detail.characters.iter().map(Into::into).collect(),
            staff: detail.staff.iter().map(Into::into).collect(),
            trailer: detail.trailer.as_ref().map(Into::into),
            relations: detail.relations.iter().map(Into::into).collect(),
            recommendations: detail.recommendations.iter().map(Into::into).collect(),
            next_airing: detail.next_airing.map(Into::into),
            episodes: detail.episodes.iter().map(Into::into).collect(),
            links: detail.links.iter().map(Into::into).collect(),
        }
    }
}
