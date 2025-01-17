use axum::{
    routing::{get, post},
    Router,
};

use crate::{handlers::patients::*, states::SharedAppState};

fn route() -> Router<SharedAppState> {
    Router::new()
        .route("/register", post(register_patient))
        .route("/login", post(login_patient))
        .route("/:id", get(get_patient_by_id))
        .route("/list", get(get_patient_list))
}

pub fn routes() -> Router<SharedAppState> {
    Router::new().nest("/patients", route())
}
