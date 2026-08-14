# =============================================================================
# AquaVerse AI — Multi-stage Dockerfile with uv
# =============================================================================

# ---------------------------------------------------------------------------
# Stage 1: builder  (uses uv for fast, reproducible installs)
# ---------------------------------------------------------------------------
FROM python:3.11-slim AS builder

WORKDIR /build

# Install uv — the fast Python package manager
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# System dependencies for asyncpg, shapely, geoalchemy2, reportlab, etc.
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libpq-dev \
    libgdal-dev \
    gdal-bin \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency specs first (cache layer — only reinstalls when these change)
COPY pyproject.toml requirements.txt requirements-dev.txt ./

# Create venv and install production deps via uv
RUN uv venv /opt/venv --python 3.11
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN uv pip install -r requirements.txt

# Copy app and install it in editable mode (picks up app/ package)
COPY . .
RUN uv pip install -e . --no-deps

# ---------------------------------------------------------------------------
# Stage 2: runtime  (minimal image — no build tools, no uv binary)
# ---------------------------------------------------------------------------
FROM python:3.11-slim AS runtime

# Non-root user for security
RUN groupadd -r aquaverse && useradd -r -g aquaverse -d /app aquaverse

WORKDIR /app

# Runtime system deps only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    libgdal32 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy venv from builder
COPY --from=builder /opt/venv /opt/venv

# Copy application code
COPY app/ ./app/
COPY alembic/ ./alembic/
COPY alembic.ini .
COPY ml/artifacts/ ./ml/artifacts/

# Set ownership
RUN chown -R aquaverse:aquaverse /app

USER aquaverse

ENV VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/app

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD curl -f http://localhost:8000/v1/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
