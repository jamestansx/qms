use std::sync::{Arc, RwLock};

use priority_queue::PriorityQueue;
use tokio::sync::broadcast;

use crate::{models::Patient, queue::QueuePriority};

pub type Queue = Arc<RwLock<PriorityQueue<Patient, QueuePriority>>>;

#[derive(Clone)]
pub struct AppState {
    pub db: sqlx::Pool<sqlx::Sqlite>,
    pub queue: Queue,
    pub tx: broadcast::Sender<String>,
    pub queue_no: Arc<RwLock<usize>>,
}
