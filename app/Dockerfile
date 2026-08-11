# Multi-stage build. Security properties:
#   - Base image pinned by digest: the build is reproducible and immune to
#     tag-repoint attacks on 'python:3.12-slim'.
#   - Build stage compiles wheels; runtime stage contains no pip cache,
#     no build toolchain — smaller attack surface, smaller CVE surface.
#   - Runs as a dedicated non-root UID (10001) that also matches the
#     runAsUser pinned in the Kubernetes manifests.
#   - No secrets are baked in at any layer; config arrives at runtime via
#     the Key Vault CSI mount.

FROM python:3.12-slim@sha256:229a2c5bfa27522db7815ea81f9bed70af17ccb9de9fc7ad142b1877b5830d36 AS build

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim@sha256:229a2c5bfa27522db7815ea81f9bed70af17ccb9de9fc7ad142b1877b5830d36

# Non-root, no shell login, fixed UID for K8s runAsUser pinning.
RUN groupadd --gid 10001 app \
    && useradd --uid 10001 --gid app --no-create-home --shell /usr/sbin/nologin app

COPY --from=build /install /usr/local
WORKDIR /app
COPY src/ ./src/

USER 10001:10001
EXPOSE 8000

# --no-server-header: don't advertise the server stack to clients.
ENTRYPOINT ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000", "--no-server-header"]
