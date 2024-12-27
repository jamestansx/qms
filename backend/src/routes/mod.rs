use axum::Router;

use crate::SharedAppState;

pub mod appointment;
pub mod auth;
pub mod queue;

pub fn make_routes(state: SharedAppState) -> Router {
    Router::new()
        .merge(auth::routes())
        .merge(appointment::routes())
        .merge(queue::routes())
        .with_state(state)
}
