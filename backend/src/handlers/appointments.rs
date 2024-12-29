use axum::{
    extract::{Path, State},
    Json,
};
use sqlx::query_as;

use crate::{error::AppError, models::appointments::*, SharedAppState};

pub async fn list_appointments(
    State(state): State<SharedAppState>,
    Path(patient_id): Path<i64>,
) -> Result<Json<Vec<AppointmentModel>>, AppError> {
    let appointments: Vec<AppointmentModel> = query_as(
        r#"SELECT *
        FROM appointments
        WHERE patient_id = ?
        ORDER BY scheduled_at_utc ASC"#,
    )
    .bind(patient_id)
    .fetch_all(&state.db)
    .await?;
    Ok(Json(appointments))
}

pub async fn add_appointment(
    State(state): State<SharedAppState>,
    Json(params): Json<AddAppointmentsParams>,
) -> Result<Json<AppointmentModel>, AppError> {
    let uuid = uuid::Uuid::new_v4();

    let res = query_as::<_, AppointmentModel>(
        "INSERT INTO appointments (patient_id, scheduled_at_utc, uuid)
        VALUES (?, ?, ?)
        RETURNING *",
    )
    .bind(params.patient_id)
    .bind(params.scheduled_at_utc)
    .bind(uuid)
    .fetch_one(&state.db)
    .await?;

    Ok(Json(res))
}
