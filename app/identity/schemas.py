"""Identity — Pydantic v2 schemas for auth endpoints."""

from __future__ import annotations

from pydantic import BaseModel, Field, field_validator


# ---------------------------------------------------------------------------
# OTP request
# ---------------------------------------------------------------------------
class OtpRequestIn(BaseModel):
    phone: str = Field(..., description="E.164 format phone number, e.g. +919876543210")
    purpose: str = Field(default="login", description="login | register")

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        import re

        if not re.match(r"^\+91[6-9]\d{9}$", v):
            raise ValueError("Phone must be a valid Indian mobile number in E.164 format")
        return v


class OtpRequestOut(BaseModel):
    message: str
    expires_in_seconds: int
    request_id: str  # opaque ID used to correlate verify call


# ---------------------------------------------------------------------------
# OTP verify
# ---------------------------------------------------------------------------
class OtpVerifyIn(BaseModel):
    request_id: str
    phone: str
    otp: str = Field(..., min_length=4, max_length=8)


class OtpVerifyOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int  # seconds
    role: str
    is_new_user: bool


# ---------------------------------------------------------------------------
# Token (staff / Keycloak exchange)
# ---------------------------------------------------------------------------
class TokenIn(BaseModel):
    grant_type: str = Field(
        default="password",
        description="password | refresh_token | keycloak_code",
    )
    username: str | None = None
    password: str | None = None
    refresh_token: str | None = None
    code: str | None = None  # Keycloak authorization code


class TokenOut(BaseModel):
    access_token: str
    refresh_token: str | None = None
    token_type: str = "bearer"
    expires_in: int
    role: str
    district: str | None = None
