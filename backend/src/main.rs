use std::{
    collections::HashMap,
    str::FromStr,
    sync::{Arc, RwLock},
    time::Duration,
};

use axum::{
    extract::{MatchedPath, Request},
    Router,
};
use routes::make_routes;
use rumqttc::{mqttbytes::QoS, AsyncClient, Event, EventLoop, MqttOptions};
use sqlx::{sqlite::SqliteConnectOptions, SqlitePool};
use states::*;
use tokio::{net::TcpListener, sync::broadcast, task};
use tower_http::{cors::CorsLayer, trace::TraceLayer};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod error;
mod handlers;
mod models;
mod queue;
mod routes;
mod states;

async fn init_db(db_uri: &str) -> Result<SqlitePool, sqlx::Error> {
    let opts = SqliteConnectOptions::from_str(db_uri)?.create_if_missing(true);
    let pool = SqlitePool::connect_with(opts).await?;
    sqlx::migrate!("./migrations").run(&pool).await?;
    Ok(pool)
}

async fn init_mqtt_client() -> Result<(AsyncClient, EventLoop), rumqttc::ClientError> {
    let mut mqtt_opts = MqttOptions::new("qms_server_mqtt", "172.20.10.3", 1883);
    mqtt_opts.set_keep_alive(Duration::from_secs(5));
    let (cl, event_loop) = AsyncClient::new(mqtt_opts, 10);
    cl.subscribe("heartRate/BPM", QoS::AtMostOnce).await?;
    cl.subscribe("accelerometer/fall", QoS::AtMostOnce).await?;

    Ok((cl, event_loop))
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::registry()
        .with(tracing_subscriber::fmt::layer())
        .init();

    let pool = init_db("sqlite://qms.db").await?;

    let (tx, mut rx) = broadcast::channel(100);
    let (tx_subs, _) = broadcast::channel::<MqttPayload>(100);
    let iot = IotState {
        tx_subscribe: tx_subs.clone(),
        wearables: Arc::new(RwLock::new(HashMap::new())),
    };
    let state = Arc::new(AppState::new(pool, tx, iot));

    // mqtt client
    let (cl, mut event_loop) = init_mqtt_client().await?;
    let mqtt_client = task::spawn(async move {
        loop {
            if let Ok(recv) = rx.try_recv() {
                if let Some(recv) = recv.map(|x| x.1).unwrap_or(None) {
                    cl.publish("server/queue", QoS::AtLeastOnce, false, recv)
                        .await
                        .ok();
                }
            }

            let notif = event_loop.poll().await;
            if let Ok(notif) = notif {
                match notif {
                    Event::Incoming(packet) => {
                        /*
                        # payload structure #
                        {
                            "uuid": "<generated-uuid>", // uuid of the wearables
                            "topic": "<topic of the publisher>",
                            "data": {
                                // any data published
                                "bpm": 123,
                                "fell_down": true,
                                "location": "<location-uuid>",
                            },
                        }
                        */
                        // if let Publish { dup: publish, qos, retain, topic, pkid, payload } = packet {
                        //     if let Some(payload) = std::str::from_utf8(&publish.payload).ok() {
                        //         tx_subs.send(payload.into()).unwrap();
                        //     }
                        // }

                        if let rumqttc::Packet::Publish(publish) = packet {
                            if let Some(payload) = std::str::from_utf8(&publish.payload).ok() {
                                let mut res: MqttPayload = serde_json::from_str(payload).unwrap();
                                res.topic = publish.topic;
                                let _ = tx_subs.send(res);
                            }
                        }
                    }
                    _ => {}
                }
            }
        }
    });

    let app = Router::new()
        .nest("/api/v1", make_routes(state))
        .layer(
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
        )
        .layer(CorsLayer::permissive());

    let listener = TcpListener::bind("172.20.10.5:8000").await?;
    tracing::debug!("listening on {}", listener.local_addr()?);
    let server = task::spawn(async { axum::serve(listener, app).await });

    let _ = tokio::join!(server, mqtt_client);

    Ok(())
}
