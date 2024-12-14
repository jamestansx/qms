use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};
use sqlx::{types::chrono::NaiveDate, FromRow};

#[derive(Serialize, Deserialize, FromRow, Hash, PartialEq, Eq, PartialOrd, Ord, Clone, Debug)]
pub struct Patient {
    pub id: i64,
    pub username: String,
    pub first_name: String,
    pub last_name: String,
    pub password: String,
    pub date_of_birth: NaiveDate,
}

#[derive(Serialize, Deserialize, FromRow)]
pub struct Appointment {
    pub id: i64,
    pub patient_id: i64,
    pub scheduled_at_utc: NaiveDateTime,
}
