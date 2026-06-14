use axum::Json;
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
