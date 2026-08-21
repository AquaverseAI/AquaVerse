"""add_report_jobs_table

Revision ID: a6b7c8d9e0f1
Revises: f5a6b7c8d9e0
Create Date: 2026-08-20 09:00:00.000000+00:00

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "a6b7c8d9e0f1"
down_revision: Union[str, None] = "f5a6b7c8d9e0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # GET /v1/reports/export (P3.2) used to return a hardcoded job_id that
    # never progressed — there was no table for a real ARQ worker to read
    # from or write to.
    op.create_table(
        "report_jobs",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("requested_by", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column(
            "pond_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("ponds.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("district", sa.String(length=100), nullable=True),
        sa.Column("format", sa.String(length=10), nullable=False),
        sa.Column("status", sa.String(length=20), nullable=False, server_default="queued"),
        sa.Column("from_date", sa.Date(), nullable=True),
        sa.Column("to_date", sa.Date(), nullable=True),
        sa.Column("s3_key", sa.String(length=500), nullable=True),
        sa.Column("error_message", sa.Text(), nullable=True),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        # No FK to users.id — same convention as advisories.issued_by /
        # logs.recorded_by; JWT identity doesn't guarantee a matching
        # seeded `users` row.
    )
    op.create_index("ix_report_jobs_requested_by", "report_jobs", ["requested_by"])


def downgrade() -> None:
    op.drop_index("ix_report_jobs_requested_by", table_name="report_jobs")
    op.drop_table("report_jobs")
