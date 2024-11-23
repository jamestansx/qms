use std::{net::SocketAddr, path::Path};

use axum::{
    extract::{
        ws::{Message, WebSocket},
        ConnectInfo, WebSocketUpgrade,
    },
    response::IntoResponse,
    routing::get,
    Router,
};
use sqlx::{sqlite::SqliteConnectOptions, SqlitePool};

async fn init_db(filename: impl AsRef<Path>) -> Result<SqlitePool, sqlx::Error> {
    let opts = SqliteConnectOptions::new()
        .filename(filename)
        .create_if_missing(true);

    SqlitePool::connect_with(opts).await
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    let pool = init_db("database.db").await?;

    let app = Router::new()
        .route("/", get(|| async { "hello world from qms" }))
        .route("/ws", get(ws_handler))
        .with_state(pool);

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await?;
    tracing::debug!("Listening on {}", listener.local_addr()?);

    axum::serve(
        listener,
        app.into_make_service_with_connect_info::<SocketAddr>(),
    )
    .await?;

    Ok(())
}

async fn ws_handler(
    ws: WebSocketUpgrade,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
) -> impl IntoResponse {
    tracing::debug!("{addr} has connected!");
    ws.on_upgrade(move |socket| handle_socket(socket, addr))
}

async fn handle_socket(mut socket: WebSocket, who: SocketAddr) {
    if socket.send(Message::Ping(vec![1, 2, 3])).await.is_ok() {
        tracing::info!("Pinged {who}...");
    } else {
        tracing::warn!("Could not pinged {who}!");
        return;
    }

    while let Some(msg) = socket.recv().await {
        if let Ok(msg) = msg {
            match msg {
                Message::Ping(t) => {
                    tracing::info!("{who} pinged us with {t:?}!");
                }
                Message::Pong(v) => {
                    if socket
                        .send(Message::Text(format!(
                            "Hello from websocket, this is your pong: {v:?}"
                        )))
                        .await
                        .is_err()
                    {
                        tracing::error!("Failed to send message to {who}");
                    }
                }
                Message::Text(v) => {
                    tracing::info!("Recieved message from {who}");
                    if socket
                        .send(Message::Text(format!(
                            "Hello from websocket, this is your pong: {v:?}"
                        )))
                        .await
                        .is_err()
                    {
                        tracing::error!("Failed to send message to {who}");
                    }
                }
                Message::Close(v) => {
                    tracing::info!("BYE {v:?}!");
                    return;
                }
                m => {
                    tracing::warn!("{m:?} is not implemented!");
                }
            }
        }
    }
}
