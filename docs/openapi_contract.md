# OpenAPI Contract Summary — AquaVerse AI

## Base URL
`https://api.aquaverse.ai/v1`

---

## 🔑 Authentication Endpoints

### `POST /auth/otp/request`
Request OTP for mobile verification.
- **Request Body**:
  ```json
  {
    "mobile_number": "+919876543210"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "message": "OTP dispatched successfully",
    "expires_in": 300
  }
  ```

### `POST /auth/otp/verify`
Verify 6-digit OTP code and obtain authentication token.
- **Request Body**:
  ```json
  {
    "mobile_number": "+919876543210",
    "otp_code": "123456"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "access_token": "jwt_access_token_string",
    "refresh_token": "jwt_refresh_token_string",
    "user": {
      "id": "usr_01H...",
      "role": "farmer",
      "preferred_language": "ta"
    }
  }
  ```

---

## 🏞 Pond & Parameter Endpoints

### `GET /ponds`
Fetch all ponds assigned to the authenticated user.
- **Response (200 OK)**:
  ```json
  {
    "ponds": [
      {
        "id": "pnd_01",
        "name": "Pond Alpha",
        "area_acres": 2.5,
        "species": "Vannamei Shrimp",
        "status": "healthy",
        "last_log_at": "2026-08-17T08:30:00Z"
      }
    ]
  }
  ```

### `POST /water-logs`
Submit water quality measurement record.
- **Request Body**:
  ```json
  {
    "client_mutation_id": "550e8400-e29b-41d4-a716-446655440000",
    "pond_id": "pnd_01",
    "ph": 7.8,
    "dissolved_oxygen": 6.2,
    "salinity_ppt": 15.0,
    "temperature_celsius": 28.5,
    "ammonia_ppm": 0.02,
    "logged_at": "2026-08-17T09:00:00Z"
  }
  ```
- **Response (201 Created)**:
  ```json
  {
    "id": "log_991",
    "status": "synced",
    "risk_level": "low"
  }
  ```
