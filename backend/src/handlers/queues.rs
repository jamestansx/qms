use std::{convert::Infallible, sync::atomic::Ordering};

use async_stream::try_stream;
use axum::{
    extract::State,
    response::{sse::Event, Sse},
    Json,
};
use futures::Stream;
use sqlx::{query, query_as};
use tokio::sync::broadcast;

use crate::{
    error::AppError,
    models::{patients::PatientModel, queues::RegQueueParams},
    queue::QueuePriority,
    SharedAppState,
};

pub async fn queue_status(
    State(state): State<SharedAppState>,
) -> Sse<impl Stream<Item = Result<Event, Infallible>>> {
    let mut rx = state.queue.status.subscribe();

    Sse::new(try_stream! {
        yield Event::default().data(format!("{:?}", state.queue.queue.read().unwrap()));
        loop {
            let recv = rx.recv().await;
            if let Ok(recv) = recv {
                yield Event::default().data(recv);
            } else {
                break;
            }
        }
    })
}

pub async fn verify_queue(
    State(state): State<SharedAppState>,
    Json(params): Json<RegQueueParams>,
) -> Result<(), AppError> {
    let res = query!(
        "SELECT patient_id, scheduled_at_utc, uuid as 'uuid: uuid::Uuid'
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

    let tx = state.queue.verifier.read().unwrap();
    let tx = tx.get(&res.uuid);

    if let Some(tx) = tx {
        let queue_no = state.queue.next_queue_no.load(Ordering::Relaxed);
        state.queue.queue.write().unwrap().push(
            params.uuid.to_string(),
            QueuePriority {
                queue_no,
                age: patient.age(),
                appointment_time_utc: res.scheduled_at_utc,
            },
        );
        if let Ok(_) = tx.send(format!("{}", queue_no)) {
            state.queue.next_queue_no.fetch_add(1, Ordering::Relaxed);
        };
    }

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
        yield Event::default();
        let queue_no = rx.recv().await;

        if let Ok(queue_no) = queue_no {
            yield Event::default().data(queue_no);
            state.queue.verifier.write().unwrap().remove(&params.uuid);
        }
    }))
}

pub async fn next_queue(State(state): State<SharedAppState>) {
    state.queue.queue.write().unwrap().pop();
    state
        .queue
        .status
        .send(format!("{:?}", state.queue.queue.read().unwrap()))
        .unwrap();
}
