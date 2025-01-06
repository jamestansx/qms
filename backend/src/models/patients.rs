use chrono::{Datelike, Utc};
use serde::{Deserialize, Serialize};
use sqlx::types::chrono::NaiveDate;

#[derive(Serialize, Deserialize, sqlx::FromRow)]
pub struct PatientModel {
    #[sqlx(rename = "patient_id")]
    pub id: i64,
    pub username: String,
    pub first_name: String,
    pub last_name: String,
    pub date_of_birth: NaiveDate,
}

#[derive(Deserialize)]
pub struct CreatePatientParams {
    pub username: String,
    pub first_name: String,
    pub last_name: String,
    pub password: String,
    pub date_of_birth: NaiveDate,
}

#[derive(Deserialize)]
pub struct LoginPatientParams {
    pub username: String,
    pub password: String,
}

#[derive(Deserialize)]
pub struct FilterPatientQuery {
    #[serde(default)]
    pub name: String,
}

impl PatientModel {
    pub fn age(self: &Self) -> usize {
        let today = Utc::now();

        let mut age = today.year() - self.date_of_birth.year();

        if today.ordinal() < self.date_of_birth.ordinal() {
            age -= 1;
        }

        age as usize
    }
}
