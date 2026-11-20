pub const EBML: u32 = 0x1A45_DFA3;
pub const EBML_VERSION: u32 = 0x4286;
pub const EBML_READ_VERSION: u32 = 0x42F7;
pub const EBML_MAX_ID_LENGTH: u32 = 0x42F2;
pub const EBML_MAX_SIZE_LENGTH: u32 = 0x42F3;
pub const DOC_TYPE: u32 = 0x4282;
pub const DOC_TYPE_VERSION: u32 = 0x4287;
pub const DOC_TYPE_READ_VERSION: u32 = 0x4285;

pub const SEGMENT: u32 = 0x1853_8067;
pub const SEEK_HEAD: u32 = 0x114D_9B74;
pub const SEEK: u32 = 0x4DBB;
pub const SEEK_ID: u32 = 0x53AB;
pub const SEEK_POSITION: u32 = 0x53AC;

pub const INFO: u32 = 0x1549_A966;
pub const TIMESTAMP_SCALE: u32 = 0x2A_D7B1;
pub const DURATION: u32 = 0x4489;
pub const MUXING_APP: u32 = 0x4D80;
pub const WRITING_APP: u32 = 0x5741;

pub const TRACKS: u32 = 0x1654_AE6B;
pub const TRACK_ENTRY: u32 = 0xAE;
pub const TRACK_NUMBER: u32 = 0xD7;
pub const TRACK_UID: u32 = 0x73C5;
pub const TRACK_TYPE: u32 = 0x83;
pub const FLAG_DEFAULT: u32 = 0x88;
pub const FLAG_LACING: u32 = 0x9C;
pub const NAME: u32 = 0x536E;
pub const LANGUAGE: u32 = 0x22_B59C;
pub const LANGUAGE_BCP47: u32 = 0x22_B59D;
pub const CODEC_ID: u32 = 0x86;
pub const CODEC_PRIVATE: u32 = 0x63A2;
pub const VIDEO: u32 = 0xE0;
pub const PIXEL_WIDTH: u32 = 0xB0;
pub const PIXEL_HEIGHT: u32 = 0xBA;
pub const AUDIO: u32 = 0xE1;
pub const SAMPLING_FREQUENCY: u32 = 0xB5;
pub const CHANNELS: u32 = 0x9F;

pub const CLUSTER: u32 = 0x1F43_B675;
pub const TIMESTAMP: u32 = 0xE7;
pub const SIMPLE_BLOCK: u32 = 0xA3;
pub const BLOCK_GROUP: u32 = 0xA0;
pub const BLOCK: u32 = 0xA1;
pub const BLOCK_DURATION: u32 = 0x9B;

pub const CUES: u32 = 0x1C53_BB6B;
pub const CUE_POINT: u32 = 0xBB;
pub const CUE_TIME: u32 = 0xB3;
pub const CUE_TRACK_POSITIONS: u32 = 0xB7;
pub const CUE_TRACK: u32 = 0xF7;
pub const CUE_CLUSTER_POSITION: u32 = 0xF1;
