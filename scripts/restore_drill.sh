#!/usr/bin/env bash
# =============================================================================
# AquaVerse AI — Backup Restore Drill
#
# Purpose: Verify that the last backup can be successfully restored.
# Run this monthly and before any major deployment.
#
# Usage: ./scripts/restore_drill.sh [backup_file.sql.gz]
# =============================================================================

set -euo pipefail

BACKUP_FILE="${1:-}"
DRILL_DB="aquaverse_restore_drill_$$"
PG_HOST="${POSTGRES_HOST:-localhost}"
PG_PORT="${POSTGRES_PORT:-5432}"
PG_USER="${POSTGRES_USER:-aquaverse}"
PGPASSWORD="${POSTGRES_PASSWORD:-aquaverse}"
export PGPASSWORD

echo "================================================================"
echo "AquaVerse AI — Database Restore Drill"
echo "================================================================"
echo "Target DB: $DRILL_DB (will be dropped after drill)"
echo "Source:    ${BACKUP_FILE:-<latest backup>}"
echo ""

# Find the most recent backup if not specified
if [ -z "$BACKUP_FILE" ]; then
    BACKUP_FILE=$(ls -t /backups/*.sql.gz 2>/dev/null | head -1 || echo "")
    if [ -z "$BACKUP_FILE" ]; then
        echo "ERROR: No backup file specified and no .sql.gz found in /backups/"
        echo "Run a backup first: pg_dump -h $PG_HOST -U $PG_USER aquaverse | gzip > /backups/aquaverse_\$(date +%Y%m%d_%H%M%S).sql.gz"
        exit 1
    fi
fi

echo "Using backup: $BACKUP_FILE"
echo ""

# Create drill database
echo "1. Creating drill database: $DRILL_DB..."
psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d postgres \
    -c "CREATE DATABASE $DRILL_DB;" 2>&1

# Enable required extensions
echo "2. Enabling extensions..."
psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$DRILL_DB" \
    -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;" 2>&1
psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$DRILL_DB" \
    -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2>&1

# Restore
echo "3. Restoring from backup..."
if [[ "$BACKUP_FILE" == *.gz ]]; then
    gunzip -c "$BACKUP_FILE" | psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$DRILL_DB" 2>&1
else
    psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$DRILL_DB" -f "$BACKUP_FILE" 2>&1
fi

# Verify
echo "4. Verifying restore..."
TABLE_COUNT=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$DRILL_DB" -At \
    -c "SELECT COUNT(*) FROM pg_tables WHERE schemaname='public';")
POND_COUNT=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$DRILL_DB" -At \
    -c "SELECT COUNT(*) FROM ponds;" 2>/dev/null || echo "0")

echo "   Tables restored: $TABLE_COUNT"
echo "   Ponds in restore: $POND_COUNT"

if [ "$TABLE_COUNT" -lt 4 ]; then
    echo "FAIL: Expected at least 4 tables, found $TABLE_COUNT"
    DROP_RESULT=0
else
    echo "PASS: Restore verification succeeded"
    DROP_RESULT=0
fi

# Cleanup
echo "5. Dropping drill database..."
psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d postgres \
    -c "DROP DATABASE IF EXISTS $DRILL_DB;" 2>&1

echo ""
echo "================================================================"
if [ "$DROP_RESULT" -eq 0 ]; then
    echo "DRILL COMPLETE — backup restore successful"
else
    echo "DRILL FAILED — investigate before next deployment"
    exit 1
fi
echo "================================================================"
