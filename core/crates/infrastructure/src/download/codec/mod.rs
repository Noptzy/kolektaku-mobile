mod aac;
mod h264;

pub use aac::{AdtsFrame, AudioConfig, SAMPLES_PER_FRAME, adts_frames};
pub use h264::{AvcFrame, ParameterSets, nal_units, to_avc_frame};

#[cfg(test)]
pub use aac::build_adts;
