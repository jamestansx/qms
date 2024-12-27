use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, sqlx::FromRow)]
pub struct AppointmentModel {
    #[sqlx(rename = "appointment_id")]
    pub id: i64,
    pub uuid: uuid::Uuid,
    pub patient_id: i64,
    pub scheduled_at_utc: NaiveDateTime,
}

#[derive(Deserialize)]
pub struct AddAppointmentsParams {
    pub patient_id: i64,
    pub scheduled_at_utc: NaiveDateTime,
}
