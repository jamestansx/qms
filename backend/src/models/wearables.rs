use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, sqlx::FromRow)]
pub struct WearableModel {
    pub device_id: i64,
    pub device_name: String,
    pub uuid: uuid::Uuid,
}

#[derive(Deserialize)]
pub struct RegWearableParams {
    pub device_name: String,
}

#[derive(Serialize, Deserialize)]
pub struct WearableStatRes {
    pub uuid: uuid::Uuid,
    pub device_name: String,
    pub topic: String,
    pub data: String,
}
