use axum::Router;

pub mod v0 {
    use axum::{Json, Router, routing::get};
    use serde::Deserialize;

    #[derive(Deserialize)]
    struct RegisterParams {
        pub username: String,
        pub password: String,
    }

    async fn register(Json(params): Json<RegisterParams>) {}

    pub fn routes() -> Router {
        Router::new().route("/register", get(register))
    }
}

pub fn routes() -> Router {
    Router::new().nest("/v0", v0::routes())
}
