"""RFC 9457 Problem Details exception handlers."""

from __future__ import annotations

import structlog
from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from starlette.exceptions import HTTPException as StarletteHTTPException

log = structlog.get_logger(__name__)

PROBLEM_MEDIA_TYPE = "application/problem+json"


# ---------------------------------------------------------------------------
# Problem Detail schema (RFC 9457)
# ---------------------------------------------------------------------------
class ProblemDetail(BaseModel):
    """RFC 9457 Problem Details for HTTP APIs."""

    type: str = "about:blank"
    title: str
    status: int
    detail: str
    instance: str | None = None
    # Extension members
    correlation_id: str | None = None
    errors: list[dict[str, object]] | None = None  # for validation errors


# ---------------------------------------------------------------------------
# Custom app exceptions
# ---------------------------------------------------------------------------
class AppError(Exception):
    """Base class for domain-specific application errors."""

    def __init__(
        self,
        status_code: int,
        title: str,
        detail: str,
        error_type: str = "about:blank",
    ) -> None:
        self.status_code = status_code
        self.title = title
        self.detail = detail
        self.error_type = error_type
        super().__init__(detail)


class NotFoundError(AppError):
    def __init__(self, detail: str = "Resource not found.") -> None:
        super().__init__(404, "Not Found", detail, "https://aquaverse.example.com/errors/not-found")


class ConflictError(AppError):
    def __init__(self, detail: str = "Conflict.") -> None:
        super().__init__(409, "Conflict", detail, "https://aquaverse.example.com/errors/conflict")


class UnauthorizedError(AppError):
    def __init__(self, detail: str = "Authentication required.") -> None:
        super().__init__(
            401, "Unauthorized", detail, "https://aquaverse.example.com/errors/unauthorized"
        )


class ForbiddenError(AppError):
    def __init__(self, detail: str = "Access denied.") -> None:
        super().__init__(403, "Forbidden", detail, "https://aquaverse.example.com/errors/forbidden")


class NumberMismatchError(AppError):
    """
    Raised by number_validator.py when the LLM output contains a numeral
    that was not present in the quantitative tool-call payload.
    """

    def __init__(self, detail: str = "LLM output numeral mismatch — rejected.") -> None:
        super().__init__(
            500,
            "LLM Number Mismatch",
            detail,
            "https://aquaverse.example.com/errors/number-mismatch",
        )


# ---------------------------------------------------------------------------
# Register exception handlers
# ---------------------------------------------------------------------------
def register_exception_handlers(app: FastAPI) -> None:
    """Attach all RFC 9457 exception handlers to the FastAPI app."""

    @app.exception_handler(StarletteHTTPException)
    async def http_exception_handler(request: Request, exc: StarletteHTTPException) -> JSONResponse:
        from structlog.contextvars import get_contextvars

        correlation_id = get_contextvars().get("correlation_id")
        problem = ProblemDetail(
            type=f"https://aquaverse.example.com/errors/http-{exc.status_code}",
            title=_status_title(exc.status_code),
            status=exc.status_code,
            detail=str(exc.detail),
            instance=str(request.url),
            correlation_id=correlation_id,
        )
        log.warning("http.exception", status=exc.status_code, detail=exc.detail)
        return JSONResponse(
            status_code=exc.status_code,
            content=problem.model_dump(exclude_none=True),
            media_type=PROBLEM_MEDIA_TYPE,
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(
        request: Request, exc: RequestValidationError
    ) -> JSONResponse:
        from structlog.contextvars import get_contextvars

        correlation_id = get_contextvars().get("correlation_id")
        errors = [{"loc": list(e["loc"]), "msg": e["msg"], "type": e["type"]} for e in exc.errors()]
        problem = ProblemDetail(
            type="https://aquaverse.example.com/errors/validation",
            title="Unprocessable Entity",
            status=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Request body or parameters failed validation.",
            instance=str(request.url),
            correlation_id=correlation_id,
            errors=errors,
        )
        log.warning("http.validation_error", errors=errors)
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content=problem.model_dump(exclude_none=True),
            media_type=PROBLEM_MEDIA_TYPE,
        )

    @app.exception_handler(AppError)
    async def app_error_handler(request: Request, exc: AppError) -> JSONResponse:
        from structlog.contextvars import get_contextvars

        correlation_id = get_contextvars().get("correlation_id")
        problem = ProblemDetail(
            type=exc.error_type,
            title=exc.title,
            status=exc.status_code,
            detail=exc.detail,
            instance=str(request.url),
            correlation_id=correlation_id,
        )
        log.error("app.error", title=exc.title, detail=exc.detail)
        return JSONResponse(
            status_code=exc.status_code,
            content=problem.model_dump(exclude_none=True),
            media_type=PROBLEM_MEDIA_TYPE,
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
        from structlog.contextvars import get_contextvars

        correlation_id = get_contextvars().get("correlation_id")
        log.exception("unhandled.exception", exc_info=exc)
        problem = ProblemDetail(
            type="https://aquaverse.example.com/errors/internal",
            title="Internal Server Error",
            status=500,
            detail="An unexpected error occurred. The team has been notified.",
            instance=str(request.url),
            correlation_id=correlation_id,
        )
        return JSONResponse(
            status_code=500,
            content=problem.model_dump(exclude_none=True),
            media_type=PROBLEM_MEDIA_TYPE,
        )


def _status_title(code: int) -> str:
    titles = {
        400: "Bad Request",
        401: "Unauthorized",
        403: "Forbidden",
        404: "Not Found",
        405: "Method Not Allowed",
        409: "Conflict",
        429: "Too Many Requests",
        500: "Internal Server Error",
        503: "Service Unavailable",
    }
    return titles.get(code, "HTTP Error")
