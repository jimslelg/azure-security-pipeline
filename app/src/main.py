"""Sample workload: a minimal inventory API.

Deliberately small — it exists so the pipeline has something real to scan,
build, sign, and deploy. The one security-relevant behaviour worth noting:
secrets are read from files (mounted by the Key Vault CSI driver), never
from environment variables, which leak into `kubectl describe`, crash dumps,
and child processes.
"""

from pathlib import Path
from typing import Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

SECRETS_DIR = Path("/mnt/secrets")

app = FastAPI(title="inventory-api", version="1.0.0", docs_url=None, redoc_url=None)


class Item(BaseModel):
    name: str = Field(min_length=1, max_length=64, pattern=r"^[\w\- ]+$")
    quantity: int = Field(ge=0, le=1_000_000)


_items: dict[str, Item] = {}


def read_secret(name: str) -> Optional[str]:
    """Return a secret mounted by the Secrets Store CSI driver, if present."""
    secret_file = SECRETS_DIR / name
    if secret_file.is_file():
        return secret_file.read_text().strip()
    return None


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/readyz")
def readyz() -> dict[str, str]:
    # Ready only when the expected secret material is mounted.
    if read_secret("api-config") is None:
        raise HTTPException(status_code=503, detail="secret volume not mounted")
    return {"status": "ready"}


@app.get("/api/items")
def list_items() -> list[Item]:
    return list(_items.values())


@app.put("/api/items/{name}")
def upsert_item(name: str, item: Item) -> Item:
    if name != item.name:
        raise HTTPException(status_code=400, detail="path/body name mismatch")
    _items[name] = item
    return item


@app.get("/api/items/{name}")
def get_item(name: str) -> Item:
    if name not in _items:
        raise HTTPException(status_code=404, detail="not found")
    return _items[name]
