use axum::{
    routing::{get, post},
    Router,
};

use crate::{handlers::*, states::AppState};

pub fn create_router(app_state: AppState) -> Router {
    Router::new()
        .route("/api/v1/patients/register", post(register_patient))
        .route("/api/v1/appointment/register", post(register_appointment))
        .route("/api/v1/queues", post(add_to_queue))
        .route("/api/v1/queues", get(queue_status))
        .with_state(app_state)
}
