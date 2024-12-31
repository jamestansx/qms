use axum::{
    routing::{get, post},
    Router,
};

use crate::{handlers::beacons::*, states::SharedAppState};

fn route() -> Router<SharedAppState> {
    Router::new()
        .route("/register", post(register_beacon))
        .route("/:id", get(get_beacon_by_uuid))
}

pub fn routes() -> Router<SharedAppState> {
    Router::new().nest("/beacons", route())
}
