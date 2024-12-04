use axum::{extract::State, Json};
use chrono::{Datelike, NaiveDate, NaiveDateTime, Utc};
use serde::Deserialize;
use sqlx::{query_as, FromRow};

use crate::{
    errors::AppError,
    models::{Appointment, Patient},
    queue::QueuePriority,
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
    let patient = query_as::<_, Patient>(
        "INSERT INTO patients (first_name, last_name, username, date_of_birth)
        VALUES (?, ?, ?, ?)
        RETURNING *",
    )
    .bind(user.first_name)
    .bind(user.last_name)
    .bind(user.username)
    .bind(user.date_of_birth)
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
    let appointment = query_as::<_, Appointment>(
        "INSERT INTO appointments (patient_id, scheduled_at_utc)
        VALUES (?, ?)
        RETURNING *",
    )
    .bind(appointment.patient_id)
    .bind(appointment.scheduled_at_utc)
    .fetch_one(&state.db)
    .await?;

    Ok(Json(appointment))
}

#[derive(Deserialize)]
pub struct AddQueueReq {
    appointment_id: u16,
}

#[derive(FromRow)]
struct PatientAppointment {
    #[sqlx(flatten)]
    patient: Patient,
    #[sqlx(flatten)]
    appointment: Appointment,
}

pub async fn add_to_queue(
    State(state): State<AppState>,
    Json(queue): Json<AddQueueReq>,
) -> Result<(), AppError> {
    let appointment = query_as::<_, PatientAppointment>(
        r#"
        SELECT *
        FROM appointments
        INNER JOIN patients ON patients.id = appointments.patient_id
        WHERE appointments.id = ?
    "#,
    )
    .bind(queue.appointment_id)
    .fetch_one(&state.db)
    .await?;

    state.queue.write().unwrap().push(
        appointment.patient.clone(),
        QueuePriority {
            queue_number: 1,
            age: (Utc::now().year() - appointment.patient.date_of_birth.year()) as usize,
            appointment_time: appointment.appointment.scheduled_at_utc,
        },
    );

    println!("{:?}", state.queue.read().unwrap());
    Ok(())
}