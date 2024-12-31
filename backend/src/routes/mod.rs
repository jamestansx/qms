use axum::Router;

use crate::states::SharedAppState;

pub mod appointment;
pub mod auth;
pub mod beacons;
pub mod queue;
pub mod wearables;

pub fn make_routes(state: SharedAppState) -> Router {
    Router::new()
        .merge(auth::routes())
        .merge(appointment::routes())
        .merge(queue::routes())
        .merge(wearables::routes())
        .merge(beacons::routes())
        .with_state(state)
}
