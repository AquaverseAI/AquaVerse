"""add_model_registry_name_version_unique

Revision ID: b7c8d9e0f1a2
Revises: a6b7c8d9e0f1
Create Date: 2026-08-20 11:00:00.000000+00:00

"""

from typing import Sequence, Union

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "b7c8d9e0f1a2"
down_revision: Union[str, None] = "a6b7c8d9e0f1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # GET /v1/models (P2.7) get-or-creates a row per (name, version) from
    # whatever M2 bundle is actually loaded
    # (app/ml_inference/model_registry_sync.py) — without a real DB
    # constraint, two concurrent requests racing to register a brand-new
    # version could both insert, leaving duplicate rows for the same
    # model.
    op.create_unique_constraint(
        "uq_model_registry_name_version", "model_registry", ["name", "version"]
    )


def downgrade() -> None:
    op.drop_constraint("uq_model_registry_name_version", "model_registry", type_="unique")
