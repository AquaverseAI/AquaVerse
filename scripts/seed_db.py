#!/usr/bin/env python3
"""
Database seed script — inserts sample data for local development.
Run: python scripts/seed_db.py
"""

from __future__ import annotations

import asyncio
import os
import sys
import uuid
from datetime import UTC, datetime, timedelta

sys.path.insert(0, ".")

# Ensure env
os.environ.setdefault(
    "DATABASE_URL", "postgresql+asyncpg://aquaverse:aquaverse@localhost:5432/aquaverse"
)
os.environ.setdefault("APP_SECRET_KEY", "dev_secret_key_change_me_in_production_32chars")
os.environ.setdefault("INTERNAL_API_TOKEN", "dev_internal_token_change_me_32chars_here")


async def seed() -> None:
    from sqlalchemy import text
    from sqlalchemy.ext.asyncio import create_async_engine

    from app.config import get_settings

    settings = get_settings()
    engine = create_async_engine(settings.database_url, echo=True)

    async with engine.begin() as conn:
        # Check that tables exist
        result = await conn.execute(
            text("SELECT tablename FROM pg_tables WHERE schemaname='public'")
        )
        tables = [row[0] for row in result]
        print(f"Tables found: {tables}")

        if "ponds" not in tables:
            print("ERROR: Run 'alembic upgrade head' first to create tables.")
            return

        # Seed a sample pond
        pond_id = uuid.uuid4()
        farmer_id = uuid.uuid4()
        now = datetime.now(UTC)

        await conn.execute(
            text("""
                INSERT INTO ponds (id, owner_user_id, name, district, taluk, village,
                                   area_hectares, depth_meters, species, created_at, updated_at)
                VALUES (:id, :owner, :name, :district, :taluk, :village,
                        :area, :depth, :species, :created_at, :updated_at)
                ON CONFLICT DO NOTHING
            """),
            {
                "id": pond_id,
                "owner": farmer_id,
                "name": "Kalaiselvi Pond - Block A",
                "district": "Nagapattinam",
                "taluk": "Sirkali",
                "village": "Kilvelur",
                "area": 2.5,
                "depth": 1.2,
                "species": "Litopenaeus vannamei",
                "created_at": now,
                "updated_at": now,
            },
        )

        # Seed 30 days of hourly water quality logs
        print(f"Seeding 720 hourly log entries for pond {pond_id}...")
        import random

        for hours_ago in range(720, 0, -1):
            recorded_at = now - timedelta(hours=hours_ago)
            await conn.execute(
                text("""
                    INSERT INTO logs (id, pond_id, recorded_by, recorded_at, source,
                                     temperature_c, dissolved_oxygen_mgl, ph,
                                     salinity_ppt, ammonia_nh3_mgl, created_at, updated_at)
                    VALUES (:id, :pond_id, :recorded_by, :recorded_at, :source,
                            :temp, :do, :ph, :sal, :ammonia, :created_at, :updated_at)
                    ON CONFLICT DO NOTHING
                """),
                {
                    "id": uuid.uuid4(),
                    "pond_id": pond_id,
                    "recorded_by": farmer_id,
                    "recorded_at": recorded_at,
                    "source": "sensor",
                    "temp": round(27 + random.uniform(-2, 3), 2),
                    "do": round(6 + random.uniform(-2, 1), 2),
                    "ph": round(7.5 + random.uniform(-0.5, 0.5), 2),
                    "sal": round(15 + random.uniform(-2, 2), 2),
                    "ammonia": round(max(0, random.uniform(0, 0.5)), 3),
                    "created_at": now,
                    "updated_at": now,
                },
            )

    print(f"\nSeeded: 1 pond ({pond_id}), 720 log entries")
    print("Done.")
    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(seed())
