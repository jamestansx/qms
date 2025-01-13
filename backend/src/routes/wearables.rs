use axum::{
    routing::{get, post},
    Router,
};

use crate::{handlers::wearables::*, states::SharedAppState};

fn route() -> Router<SharedAppState> {
    Router::new()
        .route("/monitor", get(monitor_status))
        .route("/register", post(register_wearable))
        .route("/:id", get(get_wearable_by_uuid))
        .route("/list", get(wearbles_list))
        .route("/fallack", get(ack_fall))
}

pub fn routes() -> Router<SharedAppState> {
    Router::new().nest("/wearables", route())
}
