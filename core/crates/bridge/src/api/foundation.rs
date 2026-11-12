#[flutter_rust_bridge::frb(sync)]
pub fn halo(target: String) -> String {
    application::greet(&target)
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}
