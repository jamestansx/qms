use axum::{
    extract::{Path, State},
    Json,
};
use sqlx::{query, query_as};

use crate::{error::AppError, models::beacons::*, states::SharedAppState};

pub async fn register_beacon(
    State(state): State<SharedAppState>,
    Json(param): Json<RegBeaconParams>,
) -> Result<Json<uuid::Uuid>, AppError> {
    let uuid = uuid::Uuid::new_v4();

    let _ = query(
        "INSERT INTO bleBeacons (uuid, location_name)
        VALUES (?, ?)",
    )
    .bind(uuid)
    .bind(param.location_name)
    .execute(&state.db)
    .await?;

    Ok(Json(uuid))
}

pub async fn get_beacon_by_uuid(
    State(state): State<SharedAppState>,
    Path(uuid): Path<uuid::Uuid>,
) -> Result<Json<BeaconModel>, AppError> {
    let res: BeaconModel = query_as(
        "SELECT * FROM bleBeacons
        WHERE uuid = ?
        LIMIT 1",
    )
    .bind(uuid)
    .fetch_one(&state.db)
    .await?;

    Ok(Json(res))
}
