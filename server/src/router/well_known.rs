use axum::{Json, Router, routing::get};
use serde_json::{Value, json};

pub async fn support() -> Json<Value> {
    Json(json!({
        "contacts": [
            {
                "email_address": "vpopp@proton.me",
                "role": "admin"
            }
        ]
    }))
}

pub fn routes() -> Router {
    Router::new().route("/isotope/support", get(support))
}
