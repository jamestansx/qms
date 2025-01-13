use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, sqlx::FromRow)]
pub struct BeaconModel {
    pub device_id: i64,
    pub location_name: String,
    pub uuid: uuid::Uuid,
}

#[derive(Deserialize)]
pub struct RegBeaconParams {
    pub location_name: String,
}
