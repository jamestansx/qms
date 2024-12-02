use axum::{routing::post, Router};

use crate::{handlers::{register_appointment, register_patient}, states::AppState};

pub fn create_router(app_state: AppState) -> Router {
    Router::new()
        .route("/api/v1/patients/register", post(register_patient))
        .route("/api/v1/appointment/register", post(register_appointment))
        .with_state(app_state)
}
