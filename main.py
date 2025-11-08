from fastapi import FastAPI
from typing import Dict

# Create the FastAPI application instance
app = FastAPI(
    title="Production-Ready AI Service",
    description="A template for building and deploying AI services.",
    version="0.1.0",
)

@app.get("/")
def get_root() -> Dict[str, str]:
    """
    Root endpoint for the service.
    """
    return {"message": "Welcome to the Production-Ready AI Service Template!"}


@app.get("/health")
def get_health() -> Dict[str, str]:
    """
    Health check endpoint.
    This is critical for services like AWS App Runner to know
    that your container is alive and ready to serve traffic.
    """
    return {"status": "ok"}