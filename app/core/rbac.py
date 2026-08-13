"""Role-based access control — role and district claim checks."""

from __future__ import annotations

from enum import StrEnum

from fastapi import HTTPException, status


class Role(StrEnum):
    FARMER = "farmer"
    FIELD_OFFICER = "field_officer"
    DISTRICT_OFFICER = "district_officer"
    ADMIN = "admin"


# Role hierarchy: higher index = more permissions
_ROLE_RANK: dict[str, int] = {
    Role.FARMER: 0,
    Role.FIELD_OFFICER: 1,
    Role.DISTRICT_OFFICER: 2,
    Role.ADMIN: 3,
}


def require_role(user_role: str, minimum_role: Role) -> None:
    """Raise 403 if the user's role is below the minimum required."""
    user_rank = _ROLE_RANK.get(user_role, -1)
    required_rank = _ROLE_RANK[minimum_role]
    if user_rank < required_rank:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Role '{minimum_role}' or higher required. Got '{user_role}'.",
        )


def require_district(user_district: str | None, requested_district: str) -> None:
    """
    Verify the user has access to the requested district.
    Admin users pass through regardless of their district claim.
    """
    if user_district is None:
        # Admin — no district restriction
        return
    if user_district != requested_district:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                f"Token is scoped to district '{user_district}'; "
                f"cannot access district '{requested_district}'."
            ),
        )


def require_pond_scope(user_pond_ids: list[object], pond_id: object) -> None:
    """Farmer tokens are pond-scoped — verify access to the specific pond."""
    if pond_id not in user_pond_ids:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your token does not have access to this pond.",
        )
