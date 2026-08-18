"""AquaVerse AI backend — FastAPI application factory."""

from __future__ import annotations

import sys
import time
from contextlib import asynccontextmanager
from typing import TYPE_CHECKING

import structlog
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest
from starlette.responses import PlainTextResponse

# ---------------------------------------------------------------------------
# Routers
# ---------------------------------------------------------------------------
from app.advisory.router import router as advisory_router
from app.alerts.router import router as alerts_router
from app.config import get_settings
from app.core.errors import register_exception_handlers
from app.db.session import close_db, init_db
from app.geo.router import router as geo_router
from app.i18n.router import router as i18n_router
from app.identity.router import router as identity_router
from app.ingest.router import router as ingest_router
from app.ml_inference.router import router as ml_router
from app.reporting.router import router as reporting_router
from app.twin.router import router as twin_router

if TYPE_CHECKING:
    from collections.abc import AsyncGenerator, Awaitable, Callable

log = structlog.get_logger(__name__)

# ---------------------------------------------------------------------------
# Prometheus metrics
# ---------------------------------------------------------------------------
REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "path", "status_code"],
)
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "path"],
    buckets=[0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0],
)


# ---------------------------------------------------------------------------
# Lifespan
# ---------------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Manage startup / shutdown of shared resources."""
    settings = get_settings()
    log.info("aquaverse_backend.starting", env=settings.app_env, version=settings.app_version)

    await init_db()

    log.info("aquaverse_backend.ready")
    yield

    log.info("aquaverse_backend.shutting_down")
    await close_db()
    log.info("aquaverse_backend.stopped")


# ---------------------------------------------------------------------------
# App factory
# ---------------------------------------------------------------------------
def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(
        title="AquaVerse AI",
        description=(
            "Predictive analytics platform for fish/shrimp aquaculture in Tamil Nadu. "
            "Two-layer architecture: quantitative core (LightGBM/EBM + temporal models) "
            "and reasoning layer (Qwen3-8B + LoRA adapters via vLLM). "
            "All numbers originate from the quantitative layer; the reasoning layer "
            "is architecturally forbidden from emitting any numeral it did not receive."
        ),
        version=settings.app_version,
        openapi_url="/openapi.json",
        docs_url="/docs",
        redoc_url="/redoc",
        lifespan=lifespan,
        contact={
            "name": "AquaVerse AI Engineering",
            "email": "engineering@aquaverse.example.com",
        },
        license_info={"name": "Proprietary"},
    )

    # -----------------------------------------------------------------------
    # Middleware
    # -----------------------------------------------------------------------
    _configure_middleware(app, settings)

    # -----------------------------------------------------------------------
    # Exception handlers
    # -----------------------------------------------------------------------
    register_exception_handlers(app)

    # -----------------------------------------------------------------------
    # Routers
    # -----------------------------------------------------------------------
    _mount_routers(app)

    # -----------------------------------------------------------------------
    # Utility endpoints
    # -----------------------------------------------------------------------
    _add_utility_endpoints(app)

    return app


def _configure_middleware(app: FastAPI, settings: object) -> None:
    """Register middleware in the correct order (outermost first)."""
    from app.config import Settings

    assert isinstance(settings, Settings)
    s = settings

    # CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=s.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Correlation ID + structlog context
    @app.middleware("http")
    async def correlation_id_middleware(
        request: Request, call_next: Callable[[Request], Awaitable[Response]]
    ) -> Response:
        import uuid

        correlation_id = request.headers.get("X-Correlation-ID", str(uuid.uuid4()))
        structlog.contextvars.clear_contextvars()
        structlog.contextvars.bind_contextvars(
            correlation_id=correlation_id,
            method=request.method,
            path=request.url.path,
        )

        start = time.perf_counter()
        response: Response = await call_next(request)
        elapsed = time.perf_counter() - start

        REQUEST_COUNT.labels(
            method=request.method,
            path=request.url.path,
            status_code=response.status_code,
        ).inc()
        REQUEST_LATENCY.labels(
            method=request.method,
            path=request.url.path,
        ).observe(elapsed)

        response.headers["X-Correlation-ID"] = correlation_id
        log.info(
            "http.request",
            status_code=response.status_code,
            duration_ms=round(elapsed * 1000, 2),
        )
        return response


def _mount_routers(app: FastAPI) -> None:
    prefix = "/v1"
    app.include_router(identity_router, prefix=prefix)
    app.include_router(ingest_router, prefix=prefix)
    app.include_router(ml_router, prefix=prefix)
    app.include_router(alerts_router, prefix=prefix)
    app.include_router(advisory_router, prefix=prefix)
    app.include_router(twin_router, prefix=prefix)
    app.include_router(geo_router, prefix=prefix)
    app.include_router(i18n_router, prefix=prefix)
    app.include_router(reporting_router, prefix=prefix)


def _add_utility_endpoints(app: FastAPI) -> None:
    from fastapi.responses import HTMLResponse

    from app.config import get_settings as _gs

    @app.get("/", tags=["Utility"], summary="Landing Page", response_class=HTMLResponse)
    async def root() -> str:
        s = _gs()
        return f"""
        <!DOCTYPE html>
        <html>
            <head>
                <title>AquaVerse AI</title>
                <style>
                    body {{ font-family: system-ui, -apple-system, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background-color: #f3f4f6; color: #1f2937; }}
                    .container {{ text-align: center; background: white; padding: 3rem; border-radius: 1rem; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1); max-width: 500px; }}
                    h1 {{ color: #0284c7; margin-bottom: 0.5rem; }}
                    p {{ color: #4b5563; line-height: 1.5; margin-bottom: 1.5rem; }}
                    .btn {{ display: inline-block; background-color: #0284c7; color: white; padding: 0.75rem 1.5rem; border-radius: 0.5rem; text-decoration: none; font-weight: 500; transition: background-color 0.2s; margin: 0.25rem; }}
                    .btn:hover {{ background-color: #0369a1; }}
                    .version {{ margin-top: 2rem; font-size: 0.875rem; color: #9ca3af; }}
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>🌊 AquaVerse AI</h1>
                    <p>The predictive analytics backend is running successfully in <strong>{s.app_env}</strong> mode.</p>
                    <a href="/docs" class="btn">Swagger Docs</a>
                    <a href="/redoc" class="btn">ReDoc</a>
                    <div class="version">Version {s.app_version}</div>
                </div>
            </body>
        </html>
        """

    @app.get("/v1/health", tags=["Utility"], summary="Health check")
    async def health() -> dict[str, str]:
        s = _gs()
        return {
            "status": "ok",
            "version": s.app_version,
            "env": s.app_env,
        }

    @app.get(
        "/metrics",
        tags=["Utility"],
        summary="Prometheus metrics scrape endpoint",
        include_in_schema=False,
    )
    async def metrics() -> PlainTextResponse:
        return PlainTextResponse(
            generate_latest().decode(),
            media_type=CONTENT_TYPE_LATEST,
        )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
app = create_app()


def export_openapi() -> None:
    """Write openapi.json to stdout — used by CI to commit openapi.yaml."""
    import json

    print(json.dumps(app.openapi(), indent=2))


if __name__ == "__main__":
    if "--export-openapi" in sys.argv:
        export_openapi()
    else:
        import uvicorn

        uvicorn.run(
            "app.main:app",
            host="0.0.0.0",
            port=8000,
            reload=True,
            log_config=None,  # structlog handles logging
        )
