use axum::{
    extract::{Path, State},
    Json,
};
use sqlx::query_as;

use crate::{error::AppError, models::patients::*, states::SharedAppState};

pub async fn register_patient(
    State(state): State<SharedAppState>,
    Json(param): Json<CreatePatientParams>,
) -> Result<Json<PatientModel>, AppError> {
    let res: PatientModel = query_as(
        "INSERT INTO patients (username, first_name, last_name, password, date_of_birth)
        VALUES (?, ?, ?, ?, ?)
        RETURNING *",
    )
    .bind(param.username)
    .bind(param.first_name)
    .bind(param.last_name)
    .bind(param.password)
    .bind(param.date_of_birth)
    .fetch_one(&state.db)
    .await?;

    Ok(Json(res))
}

pub async fn login_patient(
    State(state): State<SharedAppState>,
    Json(param): Json<LoginPatientParams>,
) -> Result<Json<PatientModel>, AppError> {
    let res: PatientModel = query_as(
        "SELECT * FROM patients
        WHERE username = ? AND password = ?
        LIMIT 1",
    )
    .bind(param.username)
    .bind(param.password)
    .fetch_one(&state.db)
    .await?;

    Ok(Json(res))
}

pub async fn get_patient_by_id(
    State(state): State<SharedAppState>,
    Path(id): Path<i64>,
) -> Result<Json<PatientModel>, AppError> {
    let res: PatientModel = query_as(
        "SELECT * FROM patients
        WHERE patient_id = ?
        LIMIT 1",
    )
    .bind(id)
    .fetch_one(&state.db)
    .await?;

    Ok(Json(res))
}
