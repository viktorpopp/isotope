use anyhow::Context;
use axum::{Router, routing::get};
use tokio::net::TcpListener;

mod well_known;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let router = Router::new().route("/.well-known/isotope/support", get(well_known::support));
    let listener = TcpListener::bind("0.0.0.0:8009")
        .await
        .context("could not bind to port 8009/tcp")?;
    axum::serve(listener, router).await?;

    Ok(())
}
