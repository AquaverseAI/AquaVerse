"""S3/R2/MinIO client helper (P2.5).

`POST /v1/media/upload-url` used to return a fixture URL
(`?X-Amz-Signature=stub`) and `POST /v1/media/{id}/commit` always
returned `status=committed` with no verification that anything was ever
actually uploaded. This module wraps the real boto3 S3 client against
whatever `Settings.s3_*` points at (MinIO by default per
`infra/docker-compose.yml`, R2/S3-compatible in production).

Presigned URL generation (`generate_presigned_put_url`) is a pure local
signing operation — boto3 never makes a network call for it, so it works
even if the object store is unreachable. `head_object`, by contrast,
genuinely reaches the store; callers must treat `None` (object not found
*or* store unreachable) as "cannot verify — do not mark committed",
never as a silent success.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

import structlog

from app.config import get_settings

if TYPE_CHECKING:
    from mypy_boto3_s3 import S3Client

log = structlog.get_logger(__name__)


def get_s3_client() -> S3Client:
    import boto3

    settings = get_settings()
    return boto3.client(
        "s3",
        endpoint_url=settings.s3_endpoint_url,
        aws_access_key_id=settings.s3_access_key_id,
        aws_secret_access_key=settings.s3_secret_access_key,
        # MinIO/R2 don't use AWS regions, but boto3's client requires one
        # to be set; any value is accepted.
        region_name="us-east-1",
    )


def generate_presigned_put_url(s3_key: str, mime_type: str) -> str:
    """Real presigned PUT URL — local signing only, no network call."""
    settings = get_settings()
    client = get_s3_client()
    url: str = client.generate_presigned_url(
        "put_object",
        Params={
            "Bucket": settings.s3_bucket_name,
            "Key": s3_key,
            "ContentType": mime_type,
        },
        ExpiresIn=settings.s3_presign_expiry_seconds,
    )
    return url


@dataclass(frozen=True)
class HeadObjectResult:
    size_bytes: int
    content_type: str | None


def head_object(s3_key: str) -> HeadObjectResult | None:
    """HEAD the real object. Returns None if it doesn't exist *or* the
    store couldn't be reached — callers must not distinguish "confirmed
    missing" from "couldn't check" as grounds to mark something committed.
    """
    from botocore.exceptions import BotoCoreError, ClientError

    settings = get_settings()
    client = get_s3_client()
    try:
        response = client.head_object(Bucket=settings.s3_bucket_name, Key=s3_key)
    except ClientError as exc:
        error_code = exc.response.get("Error", {}).get("Code")
        log.info("s3.head_object_not_found", s3_key=s3_key, error_code=error_code)
        return None
    except BotoCoreError as exc:
        log.warning("s3.head_object_unreachable", s3_key=s3_key, error=str(exc))
        return None

    return HeadObjectResult(
        size_bytes=int(response["ContentLength"]),
        content_type=response.get("ContentType"),
    )
