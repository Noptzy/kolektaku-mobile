pub const CHECK_INTERVAL_SECS: u64 = 12 * 60 * 60;

pub fn due(last_checked_secs: Option<u64>, now_secs: u64, manual: bool) -> bool {
    if manual {
        return true;
    }
    match last_checked_secs {
        None => true,
        Some(last) if last > now_secs => true,
        Some(last) => now_secs - last >= CHECK_INTERVAL_SECS,
    }
}
