use std::time::Duration;

use rumqttc::v5::{
    mqttbytes::{v5::Packet::Publish, QoS},
    AsyncClient, Event, MqttOptions,
};
use tokio::{task, time};

#[tokio::main]
async fn main() {
    let mut mqtt_opts = MqttOptions::new("test", "0.0.0.0", 1884);
    mqtt_opts.set_keep_alive(Duration::from_secs(5));

    let (cl, mut eventloop) = AsyncClient::new(mqtt_opts, 10);
    cl.subscribe("hello/rumqtt", QoS::AtMostOnce).await.unwrap();

    task::spawn(async move {
        for _ in 0..10 {
            cl.publish("hello/rumqtt", QoS::AtLeastOnce, false, "Hello")
                .await
                .unwrap();
            time::sleep(Duration::from_secs(1)).await;
        }
    });

    loop {
        let notif = eventloop.poll().await.unwrap();
        match notif {
            Event::Incoming(packet) => {
                if let Publish(publish) = packet {
                    println!("{:#?}", publish.topic);
                }
            }
            _ => {}
        }
    }
}
