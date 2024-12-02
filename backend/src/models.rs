use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};
use sqlx::{prelude::FromRow, types::chrono::NaiveDate};

#[derive(Serialize, Deserialize, FromRow)]
pub struct Patient {
    pub id: i64,
    pub username: String,
    pub first_name: String,
    pub last_name: String,
    pub date_of_birth: NaiveDate,
    pub updated_at: NaiveDateTime,
    pub created_at: NaiveDateTime,
}

#[derive(Serialize, Deserialize, FromRow)]
pub struct Appointment {
    pub id: i64,
    pub patient_id: i64,
    pub scheduled_at_utc: NaiveDateTime,
    pub updated_at: NaiveDateTime,
    pub created_at: NaiveDateTime,
}
