use axum::{extract::State, Json};
use chrono::{NaiveDate, NaiveDateTime};
use serde::Deserialize;
use sqlx::query_as;

use crate::{
    errors::AppError,
    models::{Appointment, Patient},
    states::AppState,
};

#[derive(Deserialize)]
pub struct RegPatientReq {
    first_name: String,
    last_name: String,
    username: String,
    date_of_birth: NaiveDate,
}

pub async fn register_patient(
    State(state): State<AppState>,
    Json(user): Json<RegPatientReq>,
) -> Result<Json<Patient>, AppError> {
    let patient = query_as!(
        Patient,
        r#"
        INSERT INTO patients (first_name, last_name, username, date_of_birth)
        VALUES (?, ?, ?, ?)
        RETURNING *
        "#,
        user.first_name,
        user.last_name,
        user.username,
        user.date_of_birth
    )
    .fetch_one(&state.db)
    .await?;

    Ok(Json(patient))
}

#[derive(Deserialize)]
pub struct RegAppointmentReq {
    patient_id: u16,
    scheduled_at_utc: NaiveDateTime,
}

pub async fn register_appointment(
    State(state): State<AppState>,
    Json(appointment): Json<RegAppointmentReq>,
) -> Result<Json<Appointment>, AppError> {
    let appointment = query_as!(
        Appointment,
        r#"
        INSERT INTO appointments (patient_id, scheduled_at_utc)
        VALUES (?, ?)
        RETURNING *
        "#,
        appointment.patient_id,
        appointment.scheduled_at_utc,
    )
    .fetch_one(&state.db)
    .await?;

    Ok(Json(appointment))
}
