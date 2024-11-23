use std::{net::SocketAddr, str::FromStr};

use axum::{
    extract::State,
    response::Result,
    routing::post,
    Json, Router,
};
use serde::{Deserialize, Serialize};
use sqlx::{
    migrate, query,
    sqlite::SqliteConnectOptions,
    types::chrono::{DateTime, Utc},
    FromRow, SqlitePool,
};
use tower_http::catch_panic::CatchPanicLayer;

static DB_HOST: &str = "sqlite://database.db";
static PORT: u16 = 3000;

#[derive(Clone)]
struct AppState {
    db: sqlx::Pool<sqlx::Sqlite>,
}

#[derive(Debug, Serialize, Deserialize, FromRow)]
struct Patient {
    id: u16,
    username: String,
    first_name: String,
    last_name: String,
    #[serde(alias = "birth_of_date")]
    bod: DateTime<Utc>,
}

async fn init_db(db_uri: &str) -> Result<SqlitePool, sqlx::Error> {
    let opts = SqliteConnectOptions::from_str(db_uri)?.create_if_missing(true);

    let pool = SqlitePool::connect_with(opts).await?;

    migrate!("./migrations").run(&pool).await?;

    Ok(pool)
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    let pool = init_db(DB_HOST).await?;
    let app_state = AppState { db: pool };

    let api_routes = Router::new().route("/patients/register", post(register_patient));
    // .route("/queue", get(ws));

    let app = Router::new()
        .nest("/api/v1", api_routes)
        .with_state(app_state)
        .layer(CatchPanicLayer::new());

    let addr = SocketAddr::from(([0, 0, 0, 0], PORT));
    let listener = tokio::net::TcpListener::bind(addr).await?;
    tracing::info!("Listening on {}", listener.local_addr()?);

    axum::serve(
        listener,
        app.into_make_service_with_connect_info::<SocketAddr>(),
    )
    .await?;

    Ok(())
}

async fn register_patient(
    State(state): State<AppState>,
    Json(user): Json<Patient>,
) -> Result<Json<Patient>> {
    query!(
        r#"
        INSERT INTO patients (first_name, last_name, username, birth_of_date)
        VALUES (?, ?, ?, ?)
        "#,
        user.first_name,
        user.last_name,
        user.username,
        user.bod
    )
    .execute(&state.db)
    .await
    .expect("Failed to insert new patient value in sqlite");

    Ok(Json(user))
}
