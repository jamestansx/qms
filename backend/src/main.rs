use std::{
    collections::HashMap,
    str::FromStr,
    sync::{atomic::AtomicUsize, Arc, RwLock},
    time::Duration,
};

use axum::{
    extract::{MatchedPath, Request},
    Router,
};
use priority_queue::PriorityQueue;
use queue::QueuePriority;
use routes::make_routes;
use rumqttc::v5::{
    mqttbytes::{v5::Packet::Publish, QoS},
    AsyncClient, Event, EventLoop, MqttOptions,
};
use sqlx::{sqlite::SqliteConnectOptions, SqlitePool};
use tokio::{net::TcpListener, sync::broadcast, task};
use tower_http::trace::TraceLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod error;
mod handlers;
mod models;
mod queue;
mod routes;

struct AppState {
    db: SharedDb,
    queue: QueueState,
}

type SharedDb = sqlx::Pool<sqlx::Sqlite>;
type SharedAppState = Arc<AppState>;
type SharedQueue = Arc<RwLock<PriorityQueue<String, QueuePriority>>>;
type SharedVerifier = Arc<RwLock<HashMap<uuid::Uuid, broadcast::Sender<String>>>>;

// TODO: determine the type of broadcast sender
#[derive(Debug)]
struct QueueState {
    next_queue_no: AtomicUsize,
    verifier: SharedVerifier,
    queue: SharedQueue,
    status: broadcast::Sender<String>,
}

impl AppState {
    fn new(db: SharedDb, tx: broadcast::Sender<String>) -> AppState {
        AppState {
            db,
            queue: QueueState::new(tx),
        }
    }
}

impl QueueState {
    fn new(tx: broadcast::Sender<String>) -> QueueState {
        QueueState {
            next_queue_no: AtomicUsize::new(1),
            verifier: Arc::new(RwLock::new(HashMap::new())),
            queue: SharedQueue::new(RwLock::new(PriorityQueue::default())),
            status: tx,
        }
    }
}

async fn init_db(db_uri: &str) -> Result<SqlitePool, sqlx::Error> {
    let opts = SqliteConnectOptions::from_str(db_uri)?.create_if_missing(true);
    let pool = SqlitePool::connect_with(opts).await?;
    sqlx::migrate!("./migrations").run(&pool).await?;
    Ok(pool)
}

async fn init_mqtt_client() -> Result<(AsyncClient, EventLoop), rumqttc::v5::ClientError> {
    let mut mqtt_opts = MqttOptions::new("ble32", "192.168.0.7", 1883);
    mqtt_opts.set_keep_alive(Duration::from_secs(5));
    let (cl, event_loop) = AsyncClient::new(mqtt_opts, 10);
    cl.subscribe("heartRate/BPM", QoS::AtMostOnce).await?;
    cl.subscribe("accelerometer/accMag", QoS::AtMostOnce)
        .await?;

    Ok((cl, event_loop))
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::registry()
        .with(tracing_subscriber::fmt::layer())
        .init();

    let pool = init_db("sqlite://qms.db").await?;

    let (tx, mut rx) = broadcast::channel(100);
    let state = Arc::new(AppState::new(pool, tx));

    // mqtt client
    let (cl, mut event_loop) = init_mqtt_client().await?;
    let mqtt_client = task::spawn(async move {
        loop {
            if let Ok(recv) = rx.try_recv() {
                cl.publish("server/queue", QoS::AtLeastOnce, false, recv).await.ok();
            }

            let notif = event_loop.poll().await;
            if let Ok(notif) = notif {
                match notif {
                    Event::Incoming(packet) => {
                        if let Publish(publish) = packet {
                            // TODO: process the payload
                            println!("[{:?}] {:?}", publish.topic, publish.payload);
                        }
                    }
                    _ => {}
                }
            }
        }
    });

    let app = Router::new().nest("/api/v1", make_routes(state)).layer(
        TraceLayer::new_for_http()
            .make_span_with(|req: &Request| {
                let method = req.method();
                let uri = req.uri();

                let matched_path = req
                    .extensions()
                    .get::<MatchedPath>()
                    .map(|matched_path| matched_path.as_str());

                tracing::debug_span!("request", %method, %uri, matched_path)
            })
            .on_failure(()),
    );

    let listener = TcpListener::bind("127.0.0.1:3000").await?;
    tracing::debug!("listening on {}", listener.local_addr()?);
    let server = task::spawn(async { axum::serve(listener, app).await });

    let _ = tokio::join!(server, mqtt_client);

    Ok(())
}
