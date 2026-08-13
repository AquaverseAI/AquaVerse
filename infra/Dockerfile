# =============================================================================
# AquaVerse AI — Multi-stage Dockerfile
# =============================================================================

# ---------------------------------------------------------------------------
# Stage 1: builder
# ---------------------------------------------------------------------------
FROM python:3.11-slim AS builder

WORKDIR /build

# System dependencies for asyncpg, shapely, reportlab, etc.
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libpq-dev \
    libgdal-dev \
    gdal-bin \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency spec first (cache layer)
COPY pyproject.toml .
RUN pip install --upgrade pip \
    && pip install --no-cache-dir build \
    && pip install --no-cache-dir -e ".[dev]" 2>/dev/null || \
       pip install --no-cache-dir \
           fastapi uvicorn[standard] pydantic pydantic-settings \
           sqlalchemy[asyncio] asyncpg alembic geoalchemy2 \
           redis arq python-jose passlib python-multipart httpx \
           structlog prometheus-client sentry-sdk \
           boto3 lightgbm interpret shap numpy pandas scikit-learn mlflow \
           langdetect reportlab openpyxl jinja2 \
           shapely pyproj python-dateutil pytz orjson tenacity anyio \
           sse-starlette

# ---------------------------------------------------------------------------
# Stage 2: runtime
# ---------------------------------------------------------------------------
FROM python:3.11-slim AS runtime

# Non-root user for security
RUN groupadd -r aquaverse && useradd -r -g aquaverse -d /app aquaverse

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Runtime system deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    libgdal32 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy application code
COPY app/ ./app/
COPY alembic/ ./alembic/
COPY alembic.ini .
COPY ml/artifacts/ ./ml/artifacts/

# Set ownership
RUN chown -R aquaverse:aquaverse /app

USER aquaverse

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/app

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD curl -f http://localhost:8000/v1/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
