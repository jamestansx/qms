use std::convert::Infallible;

use async_stream::try_stream;
use axum::{
    extract::{Path, State},
    response::{sse::Event, Sse},
    Json,
};
use futures::Stream;
use sqlx::{query, query_as};
use tracing::error;

use crate::{error::AppError, models::wearables::*, states::SharedAppState};

pub async fn monitor_status(
    State(state): State<SharedAppState>,
) -> Sse<impl Stream<Item = Result<Event, Infallible>>> {
    let mut rx = state.iot.tx_subscribe.subscribe();

    Sse::new(try_stream! {
        loop {
            let recv = rx.recv().await;
            if let Ok(recv) = recv {
                let device_name = query!("SELECT device_name FROM wearables WHERE uuid = ? LIMIT 1", recv.uuid).fetch_one(&state.db).await;

                if device_name.is_err() {
                    error!("ARGHHHH");
                    break;
                }

                match recv.topic.as_str() {
                    "heartRate/BPM" => {
                        yield Event::default().data(serde_json::to_string(&WearableStatRes {
                            uuid: recv.uuid,
                            device_name: device_name.unwrap().device_name,
                            topic: recv.topic,
                            data: recv.data.get("BPM").unwrap_or(&"-1".to_string()).to_string(),
                        }).unwrap());
                    },
                    "accelerometer/fall" => {
                        if let Some(uuid) = recv.data.get("location") {
                            let location_name = query!("SELECT location_name FROM bleBeacon WHERE uuid = ? LIMIT 1", uuid).fetch_one(&state.db).await;

                            if location_name.is_err() {
                                error!("FUCKKKK");
                                break;
                            }

                            yield Event::default().data(serde_json::to_string(&WearableStatRes {
                                uuid: recv.uuid,
                                device_name: device_name.unwrap().device_name,
                                topic: recv.topic,
                                data: location_name.unwrap().location_name,
                            }).unwrap());
                        }
                    },
                    _ => {},
                }
                // yield Event::default().data(serde_json::to_string(&recv).unwrap_or_else(|_| "SOMETHING GONE WRONG, WTF".into()));
            }
        }
    })
}

pub async fn register_wearable(
    State(state): State<SharedAppState>,
    Json(param): Json<RegWearableParams>,
) -> Result<Json<uuid::Uuid>, AppError> {
    let uuid = uuid::Uuid::new_v4();

    let _ = query("INSERT INTO wearables (uuid, device_name) VALUES (?, ?)")
        .bind(uuid)
        .bind(param.device_name)
        .execute(&state.db)
        .await?;

    Ok(Json(uuid))
}

pub async fn get_wearable_by_uuid(
    State(state): State<SharedAppState>,
    Path(uuid): Path<uuid::Uuid>,
) -> Result<Json<WearableModel>, AppError> {
    let res: WearableModel = query_as(
        "SELECT * FROM bleWearables
        WHERE uuid = ?
        LIMIT 1",
    )
    .bind(uuid)
    .fetch_one(&state.db)
    .await?;

    Ok(Json(res))
}

pub async fn wearbles_list(
    State(state): State<SharedAppState>,
) -> Result<Json<Vec<WearableModel>>, AppError> {
    let model: Vec<WearableModel> = query_as("SELECT * FROM wearables")
        .fetch_all(&state.db)
        .await?;
    Ok(Json(model))
}
