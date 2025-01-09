use axum::{extract::rejection::JsonRejection, http::StatusCode, response::IntoResponse, Json};
use serde::Serialize;

pub enum AppError {
    JsonRejection(JsonRejection),
    SqlxError(sqlx::Error),
    CustomError(String),
}

impl IntoResponse for AppError {
    fn into_response(self) -> axum::response::Response {
        #[derive(Serialize)]
        struct ErrResponse {
            message: String,
        }

        let (status, message) = match self {
            AppError::JsonRejection(rejection) => (rejection.status(), rejection.body_text()),
            AppError::SqlxError(error) => match error {
                sqlx::Error::Database(database_error) => (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    database_error.message().into(),
                ),
                sqlx::Error::RowNotFound => (StatusCode::NOT_FOUND, "Not Found".into()),
                _ => (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "Database went BRUHHHHH".into(),
                ),
            },
            AppError::CustomError(str) => (StatusCode::NOT_FOUND, str.into()),
        };

        (status, Json(ErrResponse { message })).into_response()
    }
}

impl From<JsonRejection> for AppError {
    fn from(value: JsonRejection) -> Self {
        Self::JsonRejection(value)
    }
}

impl From<sqlx::Error> for AppError {
    fn from(value: sqlx::Error) -> Self {
        Self::SqlxError(value)
    }
}

impl From<&str> for AppError {
    fn from(value: &str) -> Self {
        Self::CustomError(value.into())
    }
}
