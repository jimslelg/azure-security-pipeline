from fastapi.testclient import TestClient

from src.main import app, _items

client = TestClient(app)


def setup_function() -> None:
    _items.clear()


def test_healthz() -> None:
    resp = client.get("/healthz")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_readyz_fails_without_secret_volume() -> None:
    # In CI there is no CSI mount, so readiness must report 503 — this also
    # pins the contract that the app refuses traffic without its secrets.
    resp = client.get("/readyz")
    assert resp.status_code == 503


def test_upsert_and_get_item() -> None:
    resp = client.put("/api/items/widget", json={"name": "widget", "quantity": 3})
    assert resp.status_code == 200

    resp = client.get("/api/items/widget")
    assert resp.status_code == 200
    assert resp.json() == {"name": "widget", "quantity": 3}


def test_name_mismatch_rejected() -> None:
    resp = client.put("/api/items/widget", json={"name": "other", "quantity": 1})
    assert resp.status_code == 400


def test_input_validation_rejects_hostile_names() -> None:
    resp = client.put(
        "/api/items/x", json={"name": "<script>alert(1)</script>", "quantity": 1}
    )
    assert resp.status_code == 422


def test_quantity_bounds_enforced() -> None:
    resp = client.put("/api/items/widget", json={"name": "widget", "quantity": -1})
    assert resp.status_code == 422
