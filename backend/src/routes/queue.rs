use axum::{
    routing::{get, post},
    Router,
};

use crate::{handlers::queues::*, states::SharedAppState};

fn route() -> Router<SharedAppState> {
    Router::new()
        .route("/", get(queue_status))
        .route("/verify", post(verify_queue))
        .route("/register", post(register_queue))
        .route("/next", get(next_queue))
}

pub fn routes() -> Router<SharedAppState> {
    Router::new().nest("/queues", route())
}
