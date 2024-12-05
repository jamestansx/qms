mod errors;
mod handlers;
mod models;
mod queue;
mod routes;
mod states;

use std::{str::FromStr, sync::RwLock};

use priority_queue::PriorityQueue;
use routes::create_router;
use sqlx::{migrate, sqlite::SqliteConnectOptions, SqlitePool};
use states::{AppState, Queue};
use tokio::sync::broadcast;
use tracing::info;

const DB_HOST: &str = "sqlite://database.db";

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    let db = init_db(DB_HOST).await?;
    let queue = Queue::new(RwLock::new(PriorityQueue::default()));
    let (tx, _rx) = broadcast::channel(100);
    let state = AppState {
        db,
        queue,
        tx,
        queue_no: RwLock::new(usize::default()).into(),
    };
    let app = create_router(state);

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await?;
    info!("Listening on {}", listener.local_addr()?);

    axum::serve(listener, app).await?;

    Ok(())
}

async fn init_db(db_uri: &str) -> Result<SqlitePool, sqlx::Error> {
    let opts = SqliteConnectOptions::from_str(db_uri)?.create_if_missing(true);

    let pool = SqlitePool::connect_with(opts).await?;
    migrate!("./migrations").run(&pool).await?;

    Ok(pool)
}
