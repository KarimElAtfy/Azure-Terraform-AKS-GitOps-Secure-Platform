import os
import socket
from pathlib import Path
from typing import Any

from fastapi import FastAPI, HTTPException, status


APP_NAME = os.getenv("APP_NAME", "devsecops-api")
APP_VERSION = os.getenv("APP_VERSION", "0.1.0")
GIT_SHA = os.getenv("GIT_SHA", "local")
ENVIRONMENT = os.getenv("ENVIRONMENT", "local")
CONFIG_MESSAGE = os.getenv("CONFIG_MESSAGE", "Hello from KayStack AKS GitOps platform")
LOG_LEVEL = os.getenv("LOG_LEVEL", "info")

SECRET_FILE_PATH = os.getenv("APP_SECRET_FILE", "/mnt/secrets-store/app-demo-secret")


app = FastAPI(
    title="DevSecOps API",
    description="Kubernetes-aware FastAPI service for the AKS GitOps Secure Platform project.",
    version=APP_VERSION,
)


def get_secret_status() -> dict[str, Any]:
    """
    Check whether the application can access a secret.

    Important:
    This function NEVER returns the secret value.
    It only reports whether a secret is available and where it came from.
    """

    env_secret = os.getenv("APP_SECRET")

    if env_secret:
        return {
            "loaded": True,
            "source": "environment_variable",
        }

    secret_path = Path(SECRET_FILE_PATH)

    if secret_path.is_file():
        try:
            value = secret_path.read_text(encoding="utf-8").strip()

            return {
                "loaded": bool(value),
                "source": "mounted_file",
                "path": SECRET_FILE_PATH,
            }
        except OSError:
            return {
                "loaded": False,
                "source": "mounted_file",
                "path": SECRET_FILE_PATH,
                "error": "secret_file_read_failed",
            }

    return {
        "loaded": False,
        "source": "none",
    }


@app.get("/")
def root() -> dict[str, str]:
    return {
        "service": APP_NAME,
        "message": "AKS GitOps Secure Platform API is running.",
        "environment": ENVIRONMENT,
    }


@app.get("/health")
def health() -> dict[str, str]:
    """
    Liveness endpoint.

    Kubernetes uses this to check whether the process is alive.
    If this fails repeatedly, Kubernetes can restart the container.
    """

    return {
        "status": "healthy",
    }


@app.get("/ready")
def ready() -> dict[str, str]:
    """
    Readiness endpoint.

    Kubernetes uses this to check whether the pod should receive traffic.
    """

    force_not_ready = os.getenv("FORCE_NOT_READY", "false").lower() == "true"

    if force_not_ready:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Application forced into not-ready state.",
        )

    return {
        "status": "ready",
    }


@app.get("/version")
def version() -> dict[str, str]:
    return {
        "app_name": APP_NAME,
        "app_version": APP_VERSION,
        "git_sha": GIT_SHA,
        "environment": ENVIRONMENT,
    }


@app.get("/config")
def config() -> dict[str, str]:
    """
    Return non-secret configuration only.

    Never expose secrets here.
    """

    return {
        "app_name": APP_NAME,
        "environment": ENVIRONMENT,
        "config_message": CONFIG_MESSAGE,
        "log_level": LOG_LEVEL,
    }


@app.get("/secret-status")
def secret_status() -> dict[str, Any]:
    """
    Prove that the app can see a secret without exposing the secret value.
    """

    return get_secret_status()


@app.get("/pod-info")
def pod_info() -> dict[str, str]:
    """
    Kubernetes will inject these values later through env vars.

    Locally, fallback values are used.
    """

    return {
        "pod_name": os.getenv("POD_NAME", socket.gethostname()),
        "pod_namespace": os.getenv("POD_NAMESPACE", "local"),
        "node_name": os.getenv("NODE_NAME", "local"),
    }


@app.get("/error-test")
def error_test() -> None:
    """
    Intentional error endpoint.

    This is useful later for testing logs, alerts and troubleshooting.
    """

    raise HTTPException(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        detail="Intentional test error for observability validation.",
    )