"""add_advisories_table

Revision ID: f5a6b7c8d9e0
Revises: e4f5a6b7c8d9
Create Date: 2026-08-20 07:00:00.000000+00:00

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "f5a6b7c8d9e0"
down_revision: Union[str, None] = "e4f5a6b7c8d9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # GET /v1/advisories and POST /v1/advisories/broadcast (P2.4) used to
    # return a hardcoded fixture and echo-without-persisting, respectively
    # — there was no table for either to read from or write to.
    op.create_table(
        "advisories",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("title", sa.String(length=500), nullable=False),
        sa.Column("body", sa.Text(), nullable=False),
        sa.Column("language", sa.String(length=10), nullable=False, server_default="ta"),
        sa.Column("target_district", sa.String(length=100), nullable=True),
        sa.Column("target_species", sa.String(length=100), nullable=True),
        sa.Column("severity", sa.String(length=20), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("issued_by", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("fcm_sent", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("sms_sent", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        # No FK to users.id — same convention as logs.recorded_by; JWT
        # identity in this system doesn't guarantee a matching seeded
        # `users` row (see app/db/models/advisory.py).
    )
    op.create_index("ix_advisories_target_district", "advisories", ["target_district"])
    op.create_index("ix_advisories_created_at", "advisories", ["created_at"])


def downgrade() -> None:
    op.drop_index("ix_advisories_created_at", table_name="advisories")
    op.drop_index("ix_advisories_target_district", table_name="advisories")
    op.drop_table("advisories")
