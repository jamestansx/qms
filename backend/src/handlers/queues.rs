use std::{
    convert::Infallible,
    sync::atomic::{AtomicUsize, Ordering},
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
use tokio::sync::broadcast::{self, Sender};
use tracing::error;

use crate::{
    error::AppError,
    models::{patients::PatientModel, queues::RegQueueParams},
    queue::QueuePriority,
    SharedAppState, SharedQueue, SharedVerifier,
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
        .and_then(|x| Some(x.1.queue_no));
    let mut rx = state.queue.status.subscribe();

    Sse::new(try_stream! {
        if let Some(num) = init_queue_no {
            yield Event::default().data(format!("{}", json!({"queue_no": num}).to_string()));
        } else {
            yield Event::default().data(json!({}).to_string());
        }

        loop {
            let recv = rx.recv().await;
            if let Ok(recv) = recv {
                if recv.is_empty() {
                    yield Event::default().data(json!({}).to_string());
                } else {
                    yield Event::default().data(format!("{}", json!({"queue_no": recv.parse::<usize>().unwrap()}).to_string()));
                }
            } else {
                error!("Something's wrong with receiver");
                break;
            }
        }
    })
}

fn update_queue(
    verifier: SharedVerifier,
    uuid: uuid::Uuid,
    next_queue_no: &AtomicUsize,
    queue: SharedQueue,
    age: usize,
    scheduled_at_utc: NaiveDateTime,
    status: &Sender<String>,
) {
    let tx = verifier.read().unwrap();
    let tx = tx.get(&uuid);

    if let Some(tx) = tx {
        let mut priority_queue = queue.write().unwrap();
        if priority_queue.get(&uuid.to_string()).is_some() {
            return;
        }
        let queue_no = next_queue_no.load(Ordering::Relaxed);
        priority_queue.push(
            uuid.to_string(),
            QueuePriority {
                queue_no,
                age,
                appointment_time_utc: scheduled_at_utc,
            },
        );
        if tx.send(format!("{}", queue_no)).is_ok() {
            if priority_queue.len() == 1 {
                status.send(format!("{}", queue_no)).unwrap();
            }
            next_queue_no.fetch_add(1, Ordering::Relaxed);
        } else {
            error!("Unable to send queue number");
        }
    }
}

pub async fn verify_queue(
    State(state): State<SharedAppState>,
    Json(params): Json<RegQueueParams>,
) -> Result<(), AppError> {
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

    update_queue(
        state.queue.verifier.clone(),
        params.uuid,
        &state.queue.next_queue_no,
        state.queue.queue.clone(),
        patient.age(),
        res.scheduled_at_utc,
        &state.queue.status,
    );

    query!(
        "UPDATE appointments SET is_attended = true WHERE appointment_id = ?",
        res.appointment_id
    )
    .execute(&state.db)
    .await?;

    Ok(())
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
            yield Event::default().data(queue_no);
            state.queue.verifier.write().unwrap().remove(&params.uuid);
        }
    }))
}

pub async fn next_queue(State(state): State<SharedAppState>) {
    state.queue.queue.write().unwrap().pop();
    let priority_queue = state.queue.queue.read().unwrap();
    let q = priority_queue.peek();
    if let Some(q) = q {
        state
            .queue
            .status
            .send(format!("{}", q.1.queue_no))
            .unwrap();
    } else {
        state
            .queue
            .status
            .send("".into())
            .unwrap();
    }
}
