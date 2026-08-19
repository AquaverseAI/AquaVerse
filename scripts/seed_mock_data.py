"""Seed mock data for AquaVerse testing (Farmers, Staff, Admin)."""

import asyncio

from passlib.context import CryptContext
from sqlalchemy import select

from app.db.models.user import User
from app.db.session import async_session_maker

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


async def seed_data():
    async with async_session_maker() as session:
        # Check if users already exist
        result = await session.execute(select(User).limit(1))
        if result.scalar_one_or_none() is not None:
            print("Database already contains users. Skipping seed.")
            return

        print("Seeding mock users...")

        # 1. Farmer (OTP Only)
        farmer = User(
            phone="+919999999999",
            name="Ramesh (Farmer)",
            role="farmer",
            district="Nagapattinam",
            is_active=True,
        )

        # 2. Executive Officer (Staff)
        executive = User(
            phone="+918888888888",
            username="exec_officer",
            password_hash=pwd_context.hash("exec123"),
            name="Karthik (Exec Officer)",
            role="staff",
            district="Nagapattinam",
            is_active=True,
        )

        # 3. Admin (Hidden, Username/Password Only)
        admin = User(
            username="admin",
            password_hash=pwd_context.hash("admin123"),
            name="Super Admin",
            role="admin",
            is_active=True,
        )

        session.add_all([farmer, executive, admin])
        await session.commit()

        print("Mock data seeded successfully!")
        print("-" * 40)
        print("TEST ACCOUNTS:")
        print("1. Farmer (OTP flow): Phone: +919999999999")
        print("2. Exec Officer (Password flow): User: exec_officer | Pass: exec123")
        print("3. Admin (Password flow): User: admin | Pass: admin123")
        print("-" * 40)


if __name__ == "__main__":
    asyncio.run(seed_data())
