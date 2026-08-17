"""add_users_table

Revision ID: b1c2d3e4f5a6
Revises: a84e6d55c7b4
Create Date: 2026-08-14 06:00:00.000000+00:00

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "b1c2d3e4f5a6"
down_revision: Union[str, None] = "a84e6d55c7b4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.dialects.postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("phone", sa.String(20), unique=True, nullable=True),
        sa.Column("username", sa.String(100), unique=True, nullable=True),
        sa.Column("password_hash", sa.String(255), nullable=True),
        sa.Column("role", sa.String(50), nullable=False, server_default="farmer"),
        sa.Column("name", sa.String(200), nullable=False),
        sa.Column("district", sa.String(100), nullable=True),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default="true"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )
    op.create_index("ix_users_phone", "users", ["phone"])
    op.create_index("ix_users_username", "users", ["username"])
    op.create_index("ix_users_district", "users", ["district"])


def downgrade() -> None:
    op.drop_index("ix_users_district", table_name="users")
    op.drop_index("ix_users_username", table_name="users")
    op.drop_index("ix_users_phone", table_name="users")
    op.drop_table("users")
