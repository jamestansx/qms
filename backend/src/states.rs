use std::collections::BTreeMap;
use std::sync::atomic::AtomicUsize;

use std::collections::HashMap;
use std::sync::Arc;
use std::sync::RwLock;

use crate::queue::QueuePriority;
use priority_queue::PriorityQueue;
use serde::Deserialize;
use serde::Serialize;
use tokio::sync::broadcast;

pub struct AppState {
    pub db: SharedDb,
    pub queue: QueueState,
    pub iot: IotState,
}

pub type SharedDb = sqlx::Pool<sqlx::Sqlite>;

pub type SharedAppState = Arc<AppState>;

pub type SharedQueue = Arc<RwLock<PriorityQueue<String, QueuePriority>>>;

pub type SharedVerifier = Arc<RwLock<HashMap<uuid::Uuid, broadcast::Sender<String>>>>;

#[derive(Debug)]
pub struct QueueState {
    pub next_queue_no: AtomicUsize,
    pub verifier: SharedVerifier,
    pub queue: SharedQueue,
    pub status: broadcast::Sender<String>,
}

impl AppState {
    pub fn new(db: SharedDb, tx: broadcast::Sender<String>, iot: IotState) -> AppState {
        AppState {
            db,
            queue: QueueState::new(tx),
            iot,
        }
    }
}

impl QueueState {
    pub fn new(tx: broadcast::Sender<String>) -> QueueState {
        QueueState {
            next_queue_no: AtomicUsize::new(1),
            verifier: Arc::new(RwLock::new(HashMap::new())),
            queue: SharedQueue::new(RwLock::new(PriorityQueue::default())),
            status: tx,
        }
    }
}

pub struct IotState {
    pub tx_subscribe: broadcast::Sender<MqttPayload>,
}

//  {
//      "uuid": "<generated-uuid>", // uuid of the wearables
//      "topic": "<topic of the publisher>",
//      "data": {
//          // any data published
//          "bpm": 123,
//          "fell_down": true,
//          "location": "<location-uuid>",
//      },
//  }
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct MqttPayload {
    pub uuid: uuid::Uuid,

    #[serde(skip_deserializing, skip_serializing)]
    pub topic: String,

    pub data: BTreeMap<String, String>,
}
