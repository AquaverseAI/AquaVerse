"""init_db

Revision ID: a84e6d55c7b4
Revises: None
Create Date: 2026-08-10 10:10:13.488686+00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
import geoalchemy2

# revision identifiers, used by Alembic.
revision: str = 'a84e6d55c7b4'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Enable Extensions & Schemas (PostgreSQL only)
    bind = op.get_bind()
    if bind.dialect.name == "postgresql":
        op.execute("CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE")
        op.execute("CREATE EXTENSION IF NOT EXISTS postgis")
        op.execute("CREATE SCHEMA IF NOT EXISTS features")

    # 2. Create Ponds Table
    op.create_table(
        'ponds',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('owner_user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('name', sa.String(length=200), nullable=False),
        sa.Column('district', sa.String(length=100), nullable=False),
        sa.Column('taluk', sa.String(length=100), nullable=True),
        sa.Column('village', sa.String(length=200), nullable=True),
        sa.Column('area_hectares', sa.Float(), nullable=True),
        sa.Column('depth_meters', sa.Float(), nullable=True),
        sa.Column('species', sa.String(length=100), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('geom', geoalchemy2.types.Geometry(geometry_type='GEOMETRY', srid=4326, from_text='ST_GeomFromEWKT', name='geometry'), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_ponds_district', 'ponds', ['district'], unique=False)
    op.create_index('ix_ponds_owner_user_id', 'ponds', ['owner_user_id'], unique=False)
    op.create_index('ix_ponds_created_at', 'ponds', ['created_at'], unique=False)

    # 3. Create Crops Table
    op.create_table(
        'crops',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('pond_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('species', sa.String(length=100), nullable=False),
        sa.Column('stocking_date', sa.Date(), nullable=False),
        sa.Column('stocking_density_per_sqm', sa.Float(), nullable=True),
        sa.Column('post_larvae_count', sa.Integer(), nullable=True),
        sa.Column('target_harvest_date', sa.Date(), nullable=True),
        sa.Column('actual_harvest_date', sa.Date(), nullable=True),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='active'),
        sa.Column('feed_brand', sa.String(length=200), nullable=True),
        sa.Column('notes', sa.String(length=1000), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['pond_id'], ['ponds.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_crops_pond_id', 'crops', ['pond_id'], unique=False)
    op.create_index('ix_crops_created_at', 'crops', ['created_at'], unique=False)

    # 4. Create Logs Table (TimescaleDB hypertable target)
    op.create_table(
        'logs',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('pond_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('crop_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('recorded_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('recorded_by', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('temperature_c', sa.Float(), nullable=True),
        sa.Column('dissolved_oxygen_mgl', sa.Float(), nullable=True),
        sa.Column('ph', sa.Float(), nullable=True),
        sa.Column('salinity_ppt', sa.Float(), nullable=True),
        sa.Column('ammonia_nh3_mgl', sa.Float(), nullable=True),
        sa.Column('turbidity_ntu', sa.Float(), nullable=True),
        sa.Column('nitrite_mgl', sa.Float(), nullable=True),
        sa.Column('nitrate_mgl', sa.Float(), nullable=True),
        sa.Column('alkalinity_mgl', sa.Float(), nullable=True),
        sa.Column('hardness_mgl', sa.Float(), nullable=True),
        sa.Column('source', sa.String(length=20), nullable=False, server_default='manual'),
        sa.Column('client_log_id', sa.String(length=200), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['pond_id'], ['ponds.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['crop_id'], ['crops.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id', 'recorded_at')  # MUST include partitioning column
    )
    op.create_index('ix_logs_pond_id', 'logs', ['pond_id'], unique=False)
    op.create_index('ix_logs_recorded_at', 'logs', ['recorded_at'], unique=False)
    op.create_index('ix_logs_client_log_id', 'logs', ['client_log_id'], unique=False)
    op.create_index('ix_logs_created_at', 'logs', ['created_at'], unique=False)

    # Convert logs table to hypertable
    op.execute("SELECT create_hypertable('logs', 'recorded_at')")

    # 5. Create Alerts Table
    op.create_table(
        'alerts',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('pond_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('alert_type', sa.String(length=100), nullable=False),
        sa.Column('severity', sa.String(length=20), nullable=False),
        sa.Column('title', sa.String(length=500), nullable=False),
        sa.Column('message', sa.Text(), nullable=False),
        sa.Column('parameter', sa.String(length=100), nullable=True),
        sa.Column('measured_value', sa.Float(), nullable=True),
        sa.Column('threshold_value', sa.Float(), nullable=True),
        sa.Column('suppressed', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('suppression_reason', sa.Text(), nullable=True),
        sa.Column('acked', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('acked_by', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('acked_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('fcm_sent', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('sms_sent', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('retry_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('risk_score', sa.Float(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['pond_id'], ['ponds.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_alerts_pond_id', 'alerts', ['pond_id'], unique=False)
    op.create_index('ix_alerts_alert_type', 'alerts', ['alert_type'], unique=False)
    op.create_index('ix_alerts_created_at', 'alerts', ['created_at'], unique=False)

    # 6. Create Media Table
    op.create_table(
        'media',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('pond_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('log_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('uploaded_by', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('filename', sa.String(length=500), nullable=False),
        sa.Column('mime_type', sa.String(length=100), nullable=False),
        sa.Column('size_bytes', sa.BigInteger(), nullable=True),
        sa.Column('s3_key', sa.String(length=1000), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='pending'),
        sa.Column('client_log_id', sa.String(length=200), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['pond_id'], ['ponds.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_media_pond_id', 'media', ['pond_id'], unique=False)
    op.create_index('ix_media_client_log_id', 'media', ['client_log_id'], unique=True)
    op.create_index('ix_media_created_at', 'media', ['created_at'], unique=False)

    # 7. Create Model Registry Table
    op.create_table(
        'model_registry',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('name', sa.String(length=200), nullable=False),
        sa.Column('model_type', sa.String(length=50), nullable=False),
        sa.Column('version', sa.String(length=100), nullable=False),
        sa.Column('artifact_path', sa.String(length=1000), nullable=False),
        sa.Column('dataset_hash', sa.String(length=64), nullable=False),
        sa.Column('adapter_version', sa.String(length=100), nullable=True),
        sa.Column('mlflow_run_id', sa.String(length=200), nullable=True),
        sa.Column('metrics', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('hyperparameters', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('promoted_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('promoted_by', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_model_registry_name', 'model_registry', ['name'], unique=False)
    op.create_index('ix_model_registry_is_active', 'model_registry', ['is_active'], unique=False)
    op.create_index('ix_model_registry_created_at', 'model_registry', ['created_at'], unique=False)

    # 8. Set up Daily Continuous Aggregate
    op.execute("""
        CREATE MATERIALIZED VIEW daily_water_quality
        WITH (timescaledb.continuous) AS
        SELECT
            pond_id,
            time_bucket(INTERVAL '1 day', recorded_at) AS bucket,
            AVG(temperature_c) AS avg_temp,
            MIN(temperature_c) AS min_temp,
            MAX(temperature_c) AS max_temp,
            AVG(dissolved_oxygen_mgl) AS avg_do,
            MIN(dissolved_oxygen_mgl) AS min_do,
            MAX(dissolved_oxygen_mgl) AS max_do,
            AVG(ph) AS avg_ph,
            AVG(salinity_ppt) AS avg_salinity,
            AVG(ammonia_nh3_mgl) AS avg_ammonia,
            AVG(turbidity_ntu) AS avg_turbidity
        FROM logs
        GROUP BY pond_id, bucket;
    """)

    op.execute("""
        SELECT add_continuous_aggregate_policy('daily_water_quality',
            start_offset => INTERVAL '1 month',
            end_offset => INTERVAL '1 hour',
            schedule_interval => INTERVAL '1 hour');
    """)

    # 9. Set up daily_features_mv in features schema
    op.execute("""
        CREATE MATERIALIZED VIEW IF NOT EXISTS features.daily_features_mv AS
        SELECT
            dwq.pond_id,
            dwq.bucket AS day,
            p.district,
            p.species,
            dwq.avg_temp,
            dwq.min_temp,
            dwq.max_temp,
            dwq.avg_do,
            dwq.min_do,
            dwq.max_do,
            dwq.avg_ph,
            dwq.avg_salinity,
            dwq.avg_ammonia,
            dwq.avg_turbidity
        FROM daily_water_quality dwq
        JOIN ponds p ON p.id = dwq.pond_id;
    """)

    op.execute("""
        CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_features_mv_pond_day 
        ON features.daily_features_mv (pond_id, day);
    """)



def downgrade() -> None:
    # 0. Drop daily features materialized view
    op.execute("DROP MATERIALIZED VIEW IF EXISTS features.daily_features_mv CASCADE")

    # 1. Drop Continuous Aggregate and Policy
    op.execute("SELECT remove_continuous_aggregate_policy('daily_water_quality')")
    op.execute("DROP MATERIALIZED VIEW IF EXISTS daily_water_quality CASCADE")


    # 2. Drop Tables
    op.drop_table('model_registry')
    op.drop_table('media')
    op.drop_table('alerts')
    op.drop_table('logs')
    op.drop_table('crops')
    op.drop_table('ponds')

    # 3. Drop Extensions & Schemas
    op.execute("DROP SCHEMA IF EXISTS features CASCADE")
