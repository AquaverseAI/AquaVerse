"""add_alert_feedback_columns

Revision ID: e4f5a6b7c8d9
Revises: d3e4f5a6b7c8
Create Date: 2026-08-19 09:00:00.000000+00:00

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "e4f5a6b7c8d9"
down_revision: Union[str, None] = "d3e4f5a6b7c8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # POST /v1/alerts/{id}/feedback used to accept AlertFeedbackIn and
    # discard it. These columns give it somewhere real to land. Nullable,
    # additive-only: existing alert rows just have no feedback yet.
    op.add_column("alerts", sa.Column("feedback_useful", sa.Boolean(), nullable=True))
    op.add_column("alerts", sa.Column("feedback_comment", sa.Text(), nullable=True))
    op.add_column(
        "alerts",
        sa.Column(
            "feedback_false_positive", sa.Boolean(), nullable=False, server_default=sa.false()
        ),
    )
    op.add_column("alerts", sa.Column("feedback_at", sa.DateTime(timezone=True), nullable=True))
    # POST /v1/alerts/{id}/ack's optional AlertAckIn.note had nowhere real to
    # land either (the alternative — appending it into `message` — would
    # mutate the original alert text). Own column instead.
    op.add_column("alerts", sa.Column("ack_note", sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column("alerts", "ack_note")
    op.drop_column("alerts", "feedback_at")
    op.drop_column("alerts", "feedback_false_positive")
    op.drop_column("alerts", "feedback_comment")
    op.drop_column("alerts", "feedback_useful")
