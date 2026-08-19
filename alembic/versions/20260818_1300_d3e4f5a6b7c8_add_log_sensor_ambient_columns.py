"""add_log_sensor_ambient_columns

Revision ID: d3e4f5a6b7c8
Revises: b1c2d3e4f5a6
Create Date: 2026-08-18 13:00:00.000000+00:00

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "d3e4f5a6b7c8"
down_revision: Union[str, None] = "b1c2d3e4f5a6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Ambient (not water-column) sensor readings — air temperature and
    # relative humidity — reported by pond-side IoT sensor units. Nullable,
    # additive-only: existing manual log rows are unaffected.
    op.add_column("logs", sa.Column("air_temperature_c", sa.Float(), nullable=True))
    op.add_column("logs", sa.Column("humidity_pct", sa.Float(), nullable=True))


def downgrade() -> None:
    op.drop_column("logs", "humidity_pct")
    op.drop_column("logs", "air_temperature_c")
