# syntax=docker/dockerfile:1.7
ARG FLUTTER_VERSION=3.44.6
ARG FLUTTER_SHA256=a6320fd72e9a2690c08e2a6a70874a30cb120dee7c78f49d2c628bd7c9e20525
FROM debian:bookworm-slim AS web-builder

ARG FLUTTER_VERSION
ARG FLUTTER_SHA256
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git xz-utils \
    && curl -fsSL \
      "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
      -o /tmp/flutter.tar.xz \
    && echo "${FLUTTER_SHA256}  /tmp/flutter.tar.xz" | sha256sum -c - \
    && tar -xJf /tmp/flutter.tar.xz -C /opt \
    && chown -R root:root /opt/flutter \
    && rm -f /tmp/flutter.tar.xz \
    && rm -rf /var/lib/apt/lists/*
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"
RUN git config --global --add safe.directory /opt/flutter \
    && flutter precache --web

WORKDIR /src/sle_prep
COPY sle_prep/pubspec.yaml sle_prep/pubspec.lock ./
RUN flutter pub get
COPY sle_prep/ ./
RUN flutter build web --no-pub --release --no-web-resources-cdn --no-wasm-dry-run

FROM ghcr.io/astral-sh/uv:0.9.4 AS uv
FROM python:3.12.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    STATIC_DIR=/app/web \
    DATABASE_PATH=/var/data/broker.db

COPY --from=uv /uv /usr/local/bin/uv
WORKDIR /app/broker
COPY broker/pyproject.toml broker/uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project
COPY broker/app ./app
COPY --from=web-builder /src/sle_prep/build/web /app/web

RUN addgroup --system sleprep \
    && adduser --system --ingroup sleprep sleprep \
    && mkdir -p /var/data \
    && chown -R sleprep:sleprep /app /var/data
USER sleprep

EXPOSE 10000
CMD ["/bin/sh", "-c", "exec .venv/bin/uvicorn app.asgi:app --host 0.0.0.0 --port ${PORT:-10000} --workers 1"]
