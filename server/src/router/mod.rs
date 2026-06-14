use axum::Router;

pub mod client;
pub mod well_known;

pub fn routes() -> Router {
    Router::new()
        .nest("/.well-known", well_known::routes())
        .nest("/client", client::routes())
}
