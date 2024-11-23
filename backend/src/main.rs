use std::{net::SocketAddr, str::FromStr, sync::Arc};

use axum::{routing::get, Router};
use sqlx::{sqlite::SqliteConnectOptions, SqlitePool};

static DB_HOST: &'static str = "sqlite://database.db";
static PORT: u16 = 3000;

struct AppState {
    db: sqlx::Pool<sqlx::Sqlite>,
}

async fn init_db(db_uri: &str) -> Result<SqlitePool, sqlx::Error> {
    let opts = SqliteConnectOptions::from_str(db_uri)?.create_if_missing(true);

    SqlitePool::connect_with(opts).await
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    let pool = init_db(DB_HOST).await?;
    let app_state = Arc::new(AppState { db: pool });

    let app = Router::new()
        .route("/", get(|| async { "hello world from qms" }))
        .with_state(app_state);

    let addr = SocketAddr::from(([0, 0, 0, 0], PORT));
    let listener = tokio::net::TcpListener::bind(addr).await?;
    tracing::debug!("Listening on {}", listener.local_addr()?);

    axum::serve(
        listener,
        app.into_make_service_with_connect_info::<SocketAddr>(),
    )
    .await?;

    Ok(())
}
