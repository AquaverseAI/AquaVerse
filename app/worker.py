"""ARQ worker process entrypoint (P3.2).

`infra/docker-compose.yml` has always run `python -m arq
app.worker.WorkerSettings`, but this module didn't exist — the container
crashed on start. This wires it to the one real background job so far:
report export generation (`app/reporting/jobs.py`).
"""

from __future__ import annotations

from typing import Any, ClassVar

import structlog
from arq.connections import RedisSettings

from app.config import get_settings
from app.db.session import close_db, init_db
from app.reporting.jobs import generate_report_job

log = structlog.get_logger(__name__)


async def startup(ctx: dict[str, Any]) -> None:
    await init_db()
    log.info("worker.started")


async def shutdown(ctx: dict[str, Any]) -> None:
    await close_db()
    log.info("worker.stopped")


class WorkerSettings:
    functions: ClassVar = [generate_report_job]
    on_startup = startup
    on_shutdown = shutdown
    redis_settings = RedisSettings.from_dsn(get_settings().redis_url)
