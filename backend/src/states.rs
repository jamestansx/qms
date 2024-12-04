use std::sync::{Arc, RwLock};

use priority_queue::PriorityQueue;

use crate::{models::Patient, queue::QueuePriority};

pub type Queue = Arc<RwLock<PriorityQueue<Patient, QueuePriority>>>;

#[derive(Clone)]
pub struct AppState {
    pub db: sqlx::Pool<sqlx::Sqlite>,
    pub queue: Queue,
}
