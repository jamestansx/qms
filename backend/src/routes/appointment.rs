use axum::{
    routing::{get, post},
    Router,
};

use crate::{handlers::appointments::*, SharedAppState};

fn route() -> Router<SharedAppState> {
    Router::new()
        .route("/:id", get(list_appointments))
        .route("/book", post(add_appointment))
}

pub fn routes() -> Router<SharedAppState> {
    Router::new().nest("/appointments", route())
}
