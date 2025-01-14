use std::{
    convert::Infallible,
    sync::{atomic::Ordering, Arc},
};

use async_stream::try_stream;
use axum::{
    extract::State,
    response::{sse::Event, Sse},
    Json,
};
use chrono::NaiveDateTime;
use futures::Stream;
use serde_json::json;
use sqlx::{query, query_as};
use tokio::sync::broadcast::{self};
use tracing::error;

use crate::{
    error::AppError,
    models::{patients::PatientModel, queues::RegQueueParams, wearables::WearableModel},
    queue::{Queue, QueuePriority},
    states::SharedAppState,
    AppState,
};

pub async fn queue_status(
    State(state): State<SharedAppState>,
) -> Sse<impl Stream<Item = Result<Event, Infallible>>> {
    let init_queue_no = state
        .queue
        .queue
        .read()
        .unwrap()
        .peek()
        .map(|x| x.1.queue_no);
    let mut rx = state.queue.status.subscribe();

    Sse::new(try_stream! {
        if let Some(num) = init_queue_no {
            yield Event::default().data(json!({"queue_no": num}).to_string());
        } else {
            yield Event::default().data(json!({}).to_string());
        }

        loop {
            let recv = rx.recv().await;
            if let Ok(recv) = recv {
                if recv.is_none() {
                    yield Event::default().data(json!({}).to_string());
                } else if let Some(recv) = recv {
                    yield Event::default().data(json!({"queue_no": recv.0}).to_string());
                }
            } else {
                error!("Something's wrong with receiver");
                break;
            }
        }
    })
}

fn update_queue(
    state: Arc<AppState>,
    uuid: uuid::Uuid,
    age: usize,
    scheduled_at_utc: NaiveDateTime,
    wearables: Vec<WearableModel>,
) -> Option<usize> {
    let tx = state.queue.verifier.read().unwrap();
    let tx = tx.get(&uuid);

    if let Some(tx) = tx {
        let mut priority_queue = state.queue.queue.write().unwrap();
        if priority_queue
            .iter()
            .any(|x| x.0.appointment_uuid.eq(&uuid))
        {
            return None;
        }

        let queue_no = state.queue.next_queue_no.load(Ordering::Relaxed);
        let wearable_uuid = state
            .iot
            .wearables
            .read()
            .unwrap()
            .iter()
            .filter(|x| x.1.is_none())
            .map(|x| *x.0)
            .collect::<Vec<_>>()
            .first()
            .copied()
            .and_then(|x| {
                if age > 65 {
                    return Some(x);
                }
                None
            });

        if let Some(uuid) = wearable_uuid {
            state
                .iot
                .wearables
                .write()
                .unwrap()
                .insert(uuid, Some(queue_no));
        }

        priority_queue.push(
            Queue {
                appointment_uuid: uuid,
                wearable_uuid,
            },
            QueuePriority {
                current: state.queue.curr_queue.is_none()
                    || state.queue.curr_queue == Some(queue_no),
                queue_no,
                age,
                appointment_time_utc: scheduled_at_utc,
            },
        );

        if tx
            .send((
                format!("{}", queue_no),
                wearables
                    .iter()
                    .find(|x| wearable_uuid == Some(x.uuid))
                    .map(|x| x.device_name.clone())
                    .unwrap_or_default(),
            ))
            .is_ok()
        {
            if priority_queue.len() == 1 {
                state
                    .queue
                    .status
                    .send(Some((queue_no, wearable_uuid.map(|x| x.to_string()))))
                    .unwrap();
            }
            state.queue.next_queue_no.fetch_add(1, Ordering::Relaxed);
            return Some(queue_no);
        } else {
            error!("Unable to send queue number");
        }
    }

    return None;
}

pub async fn verify_queue(
    State(state): State<SharedAppState>,
    Json(params): Json<RegQueueParams>,
) -> Result<String, AppError> {
    let res = query!(
        "SELECT appointment_id, patient_id, scheduled_at_utc, uuid as 'uuid: uuid::Uuid'
        FROM appointments
        WHERE uuid = ?",
        params.uuid
    )
    .fetch_one(&state.db)
    .await?;

    let patient: PatientModel = query_as(
        "SELECT * FROM patients
        WHERE patient_id = ?",
    )
    .bind(res.patient_id)
    .fetch_one(&state.db)
    .await?;

    let wearables: Vec<WearableModel> = query_as("SELECT * FROM wearables")
        .fetch_all(&state.db)
        .await?;

    if wearables.is_empty() {
        return Err("No wearables found!".into());
    }

    wearables.iter().for_each(|x| {
        if !state.iot.wearables.read().unwrap().contains_key(&x.uuid) {
            state.iot.wearables.write().unwrap().insert(x.uuid, None);
        }
    });

    let queue_no = update_queue(
        state.clone(),
        res.uuid,
        patient.age(),
        res.scheduled_at_utc,
        wearables,
    );

    if queue_no.is_some() {
        query!(
            "UPDATE appointments SET is_attended = true WHERE appointment_id = ?",
            res.appointment_id
        )
        .execute(&state.db)
        .await?;

        return Ok(format!(
            "Welcome {}! Queue no.: {}",
            patient.username,
            queue_no.unwrap()
        ));
    }

    Err("No verifier running".into())
}

pub async fn register_queue(
    State(state): State<SharedAppState>,
    Json(params): Json<RegQueueParams>,
) -> Result<Sse<impl Stream<Item = Result<Event, Infallible>>>, AppError> {
    let (tx, mut rx) = broadcast::channel(2);
    state
        .queue
        .verifier
        .write()
        .unwrap()
        .insert(params.uuid, tx);

    Ok(Sse::new(try_stream! {
        let queue_no = rx.recv().await;

        if let Ok(queue_no) = queue_no {
            if queue_no.1.is_empty() {
                yield Event::default().data(json!({"queue_no": queue_no.0 }).to_string());
            } else {
                yield Event::default().data(json!({"queue_no": queue_no.0, "wearable": queue_no.1 }).to_string());
            }
            state.queue.verifier.write().unwrap().remove(&params.uuid);
        }
    }))
}

pub async fn next_queue(State(state): State<SharedAppState>) {
    let prev_queue = state.queue.queue.write().unwrap().pop();
    if let Some(q) = prev_queue {
        if let Some(uuid) = q.0.wearable_uuid {
            state.iot.wearables.write().unwrap().insert(uuid, None);
        }
    }

    let priority_queue = state.queue.queue.read().unwrap();
    let q = priority_queue.peek();
    if let Some(q) = q {
        let hash_map = state.iot.wearables.read().unwrap();
        let wearable = hash_map.get(&q.0.appointment_uuid);
        let wearable = if let Some(wearable) = wearable {
            *wearable
        } else {
            None
        };

        state
            .queue
            .status
            .send(Some((q.1.queue_no, wearable.map(|x| x.to_string()))))
            .unwrap();
    } else {
        state.queue.status.send(None).unwrap();
    }
}

pub async fn alert_queue(State(state): State<SharedAppState>) {
    let priority_queue = state.queue.queue.read().unwrap();
    let q = priority_queue.peek();
    if let Some(q) = q {
        let hash_map = state.iot.wearables.read().unwrap();
        let wearable = hash_map.get(&q.0.appointment_uuid);
        let wearable = if let Some(wearable) = wearable {
            *wearable
        } else {
            None
        };

        state
            .queue
            .status
            .send(Some((q.1.queue_no, wearable.map(|x| x.to_string()))))
            .unwrap();
    }
}
