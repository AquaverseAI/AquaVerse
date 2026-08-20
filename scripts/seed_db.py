#!/usr/bin/env python3
"""
Database seed script — inserts sample data for local development.

Creates 3 test users:
  1. Farmer  : Karthik (+919876543210) — login via OTP
  2. Staff   : Priya  (+919876543211) — login via OTP (Executive Officer)
  3. Admin   : aquaverse_admin        — login via password only (hidden)

Run: python scripts/seed_db.py
"""

from __future__ import annotations

import asyncio
import os
import sys
import uuid
from datetime import UTC, datetime, timedelta

sys.path.insert(0, ".")

# Ensure env before importing app
os.environ.setdefault(
    "DATABASE_URL", "postgresql+asyncpg://aquaverse:aquaverse@localhost:5432/aquaverse"
)
os.environ.setdefault("APP_SECRET_KEY", "dev_secret_key_minimum_32_characters_ok")
os.environ.setdefault("INTERNAL_API_TOKEN", "dev_internal_token_minimum_32_chars_ok")


def _hash_password(password: str) -> str:
    import bcrypt

    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")


async def seed() -> None:
    from sqlalchemy import text
    from sqlalchemy.ext.asyncio import create_async_engine

    from app.config import get_settings

    settings = get_settings()
    engine = create_async_engine(settings.database_url, echo=False)

    # -----------------------------------------------------------------------
    # Admin password — read from env or use dev default
    # -----------------------------------------------------------------------
    admin_password = os.environ.get("ADMIN_PASSWORD", "AquaAdmin@2026!")
    admin_hash = _hash_password(admin_password)

    # Staff (executive officer) test password — for future staff password login
    officer_password = os.environ.get("OFFICER_PASSWORD", "Officer@Nagapattinam2026")
    officer_hash = _hash_password(officer_password)

    now = datetime.now(UTC)

    # Fixed UUIDs so re-running the script is idempotent
    farmer_id = uuid.UUID("00000000-0000-0000-0000-000000000001")
    officer_id = uuid.UUID("00000000-0000-0000-0000-000000000002")
    admin_id = uuid.UUID("00000000-0000-0000-0000-000000000003")
    pond_id = uuid.UUID("00000000-0000-0000-0001-000000000001")

    async with engine.begin() as conn:
        tables_result = await conn.execute(
            text("SELECT tablename FROM pg_tables WHERE schemaname='public'")
        )
        tables = [row[0] for row in tables_result]
        print(f"Tables found: {tables}")

        if "users" not in tables:
            print("ERROR: Run 'alembic upgrade head' first to create tables.")
            await engine.dispose()
            return

        # -------------------------------------------------------------------
        # Seed users
        # -------------------------------------------------------------------
        print("\n🌱 Seeding users...")

        users = [
            {
                "id": farmer_id,
                "phone": "+919876543210",
                "username": None,
                "password_hash": None,
                "role": "farmer",
                "name": "Karthik (Test Farmer)",
                "district": "Nagapattinam",
                "is_active": True,
            },
            {
                "id": officer_id,
                "phone": "+919876543211",
                "username": "priya_officer",
                "password_hash": officer_hash,
                "role": "staff",
                "name": "Priya (Executive Officer)",
                "district": "Nagapattinam",
                "is_active": True,
            },
            {
                "id": admin_id,
                "phone": None,
                "username": "aquaverse_admin",
                "password_hash": admin_hash,
                "role": "admin",
                "name": "AquaVerse Admin",
                "district": None,
                "is_active": True,
            },
        ]

        for u in users:
            await conn.execute(
                text("""
                    INSERT INTO users
                        (id, phone, username, password_hash, role, name, district, is_active,
                         created_at, updated_at)
                    VALUES
                        (:id, :phone, :username, :password_hash, :role, :name, :district,
                         :is_active, :created_at, :updated_at)
                    ON CONFLICT (id) DO UPDATE SET
                        name = EXCLUDED.name,
                        district = EXCLUDED.district,
                        is_active = EXCLUDED.is_active,
                        updated_at = EXCLUDED.updated_at
                """),
                {**u, "created_at": now, "updated_at": now},
            )
            role_label = f"[{str(u['role']).upper()}]"
            login = u["phone"] or u["username"]
            print(f"  ✅ {role_label} {u['name']} — login: {login}")

        # -------------------------------------------------------------------
        # Seed a pond for the farmer
        # -------------------------------------------------------------------
        if "ponds" in tables:
            print("\n🌱 Seeding sample pond for farmer...")
            await conn.execute(
                text("""
                    INSERT INTO ponds
                        (id, owner_user_id, name, district, taluk, village,
                         area_hectares, depth_meters, species, geom, created_at, updated_at)
                    VALUES
                        (:id, :owner, :name, :district, :taluk, :village,
                         :area, :depth, :species,
                         ST_SetSRID(ST_MakePoint(:lon, :lat), 4326), :created_at, :updated_at)
                    ON CONFLICT (id) DO NOTHING
                """),
                {
                    "id": pond_id,
                    "owner": farmer_id,
                    "name": "Karthik - Block A Pond",
                    "district": "Nagapattinam",
                    "taluk": "Sirkali",
                    "village": "Kilvelur",
                    "area": 2.5,
                    "depth": 1.2,
                    "species": "Litopenaeus vannamei",
                    # Approximate real-world coordinates for Kilvelur village,
                    # Nagapattinam district — real location, not a fabricated
                    # placeholder. GET /v1/geo/* (app/geo/router.py) requires a
                    # real Pond.geom to plot/cluster a pond at all.
                    "lat": 10.8934,
                    "lon": 79.7397,
                    "created_at": now,
                    "updated_at": now,
                },
            )
            print(f"  ✅ Pond seeded: {pond_id}")

            # Seed 30 days of hourly water-quality logs
            if "logs" in tables:
                print("\n🌱 Seeding 720 hourly log entries (30 days)...")
                import random

                for hours_ago in range(720, 0, -1):
                    recorded_at = now - timedelta(hours=hours_ago)
                    await conn.execute(
                        text("""
                            INSERT INTO logs
                                (id, pond_id, recorded_by, recorded_at, source,
                                 temperature_c, dissolved_oxygen_mgl, ph,
                                 salinity_ppt, ammonia_nh3_mgl, created_at, updated_at)
                            VALUES
                                (:id, :pond_id, :recorded_by, :recorded_at, :source,
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
                print("  ✅ 720 log entries seeded")

    await engine.dispose()

    print("\n" + "=" * 60)
    print("✅ SEED COMPLETE")
    print("=" * 60)
    print("\n📋 Test Credentials:")
    print("-" * 60)
    print("  FARMER  (OTP login)")
    print("    Phone  : +919876543210")
    print("    Step 1 : POST /v1/auth/otp/request  { phone }")
    print("    Step 2 : POST /v1/auth/otp/verify   { request_id, phone, otp }")
    print("    Note   : OTP appears in server log + 'dev_otp' in response")
    print()
    print("  STAFF (Executive Officer)  (OTP login)")
    print("    Phone  : +919876543211")
    print("    Same OTP flow as farmer")
    print()
    print("  ADMIN  (password login — hidden)")
    print("    Username : aquaverse_admin")
    print(f"    Password : {admin_password}")
    print("    Endpoint : POST /v1/auth/token  { grant_type=password, username, password }")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(seed())
