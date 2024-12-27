use serde::Deserialize;

#[derive(Deserialize)]
pub struct RegQueueParams {
    pub uuid: uuid::Uuid,
}
