use anyhow::Context;
use axum::Router;
use tokio::net::TcpListener;

mod router;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let router = Router::new().merge(router::routes());
    let listener = TcpListener::bind("0.0.0.0:8009")
        .await
        .context("could not bind to port 8009/tcp")?;
    axum::serve(listener, router).await?;

    Ok(())
}
