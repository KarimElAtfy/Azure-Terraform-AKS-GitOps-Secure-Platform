from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_root_endpoint_returns_service_info() -> None:
    response = client.get("/")

    assert response.status_code == 200

    body = response.json()

    assert body["service"] == "devsecops-api"
    assert body["environment"] == "local"


def test_health_endpoint_returns_healthy() -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}


def test_ready_endpoint_returns_ready() -> None:
    response = client.get("/ready")

    assert response.status_code == 200
    assert response.json() == {"status": "ready"}


def test_version_endpoint_returns_version_metadata() -> None:
    response = client.get("/version")

    assert response.status_code == 200

    body = response.json()

    assert body["app_name"] == "devsecops-api"
    assert body["app_version"] == "0.1.0"
    assert body["git_sha"] == "local"
    assert body["environment"] == "local"


def test_config_endpoint_does_not_expose_secrets() -> None:
    response = client.get("/config")

    assert response.status_code == 200

    body = response.json()

    assert "config_message" in body
    assert "secret" not in body
    assert "password" not in body
    assert "token" not in body


def test_secret_status_without_secret_returns_loaded_false() -> None:
    response = client.get("/secret-status")

    assert response.status_code == 200

    body = response.json()

    assert body["loaded"] is False
    assert body["source"] == "none"


def test_pod_info_endpoint_returns_runtime_metadata() -> None:
    response = client.get("/pod-info")

    assert response.status_code == 200

    body = response.json()

    assert "pod_name" in body
    assert "pod_namespace" in body
    assert "node_name" in body


def test_error_test_returns_500() -> None:
    response = client.get("/error-test")

    assert response.status_code == 500
    assert response.json()["detail"] == "Intentional test error for observability validation."