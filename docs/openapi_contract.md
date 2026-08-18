# OpenAPI Contract Summary — AquaVerse AI

**Base URL**: `https://api.aquaverse.ai/v1`

This document represents the **CONFIRMED endpoint contract** for the AquaVerse Farmer App. All client code must align strictly with these paths.

---

## 🚨 UNRESOLVED CONTRACT GAPS (DO NOT WORK AROUND SILENTLY)

1. **No `POST /v1/logs` write endpoint exists**
   - *Impact*: Farmer/Officer observation writes (mortality count, tray status, feed confirmation, notes) have no direct write path in this contract version.
   - *Client Handling*: All repository write operations store records in local SQLite outbox and queue network flush calls with explicit `// TODO(contract): POST /v1/logs missing from confirmed endpoint contract. See openapi_contract.md` stubs.

2. **No dedicated forecast endpoint exists (`/v1/forecast/do` or similar)**
   - *Impact*: DO 24h/7d forecast band chart cannot call a separate endpoint.
   - *Client Handling*: Today dashboard forecast chart is stubbed with a clear "Forecast Unavailable" state until response body shape inside `/v1/ponds/{pond_id}/risk` is confirmed.

3. **Extension Officer Auth Path Unconfirmed**
   - *Impact*: `POST /v1/auth/token` (username+password) is designated for "staff/admin", but Extension Officer binary role model is unconfirmed.
   - *Client Handling*: Extension Officer login flow uses OTP (`/v1/auth/otp/verify`) by default, marked with a `// TODO(contract): Revisit if staff/admin login is confirmed for Extension Officers`.

4. **No dedicated Bhashini TTS Audio endpoint exists (`POST /v1/tts` or similar)**
   - *Impact*: `POST /v1/translate` translates text string, but returning audio stream/bytes or audio URL for read-aloud is not in confirmed list.
   - *Client Handling*: `BhashiniTtsService` caches text keys locally and simulates TTS audio synthesis with `// TODO(contract): POST /v1/tts audio endpoint missing from confirmed contract. See openapi_contract.md`.

---

## 🔑 Authentication Endpoints

### `POST /v1/auth/otp/request`
Request 6-digit OTP for mobile verification (farmers/staff).
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

### `POST /v1/auth/otp/verify`
Verify 6-digit OTP code and receive JWT.
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

### `POST /v1/auth/token`
Staff/admin username + password login.
- **Request Body**:
  ```json
  {
    "username": "officer_admin",
    "password": "secret_password"
  }
  ```

### `GET /v1/auth/me`
Retrieve current authenticated user identity and role from JWT claims.
- **Headers**: `Authorization: Bearer <access_token>`
- **Response (200 OK)**:
  ```json
  {
    "id": "usr_01H...",
    "name": "M. Selvam",
    "phone": "+919876543210",
    "role": "farmer",
    "district": "Nagapattinam",
    "preferred_language": "ta"
  }
  ```

---

## 📊 Water Quality Logs & Media

### `GET /v1/logs`
List water quality logs (sensor-ingested & historical).
- **Query Params**: `?pond_id={pond_id}&limit=50`
- **Response (200 OK)**:
  ```json
  {
    "logs": [
      {
        "id": "log_101",
        "pond_id": "TN-01-001",
        "logged_at": "2026-08-18T06:00:00Z",
        "ph": 7.8,
        "dissolved_oxygen": 5.4,
        "temperature": 28.0,
        "salinity": 15.0
      }
    ]
  }
  ```

### `POST /v1/media/upload-url`
Generate presigned S3/GCS upload URL for observation photos.
- **Request Body**:
  ```json
  {
    "filename": "water_color.jpg",
    "content_type": "image/jpeg"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "media_id": "med_991",
    "upload_url": "https://storage.googleapis.com/..."
  }
  ```

### `POST /v1/media/{media_id}/commit`
Commit uploaded media object after direct upload completes.
- **Response (200 OK)**:
  ```json
  {
    "media_id": "med_991",
    "status": "committed",
    "public_url": "https://cdn.aquaverse.ai/..."
  }
  ```

---

## 🏞 Ponds & Risk Assessment

### `GET /v1/ponds`
List all accessible ponds for the authenticated user.
- **Response (200 OK)**:
  ```json
  {
    "ponds": [
      {
        "id": "TN-01-001",
        "name": "Pond Alpha",
        "species": "Vannamei Shrimp",
        "area_sq_m": 10000,
        "depth_m": 1.5,
        "liner_type": "HDPE Liner",
        "water_source": "Borewell",
        "stocking_date": "2026-05-15T00:00:00Z",
        "status": "good"
      }
    ]
  }
  ```

### `GET /v1/ponds/{pond_id}`
Retrieve full details for a specific pond.

### `GET /v1/ponds/{pond_id}/events`
Fetch event timeline (stocking, feeding, chemical dosing, alerts).
- **Response (200 OK)**:
  ```json
  {
    "events": [
      {
        "id": "ev_01",
        "type": "sensor",
        "summary": "DO Sensor calibrated",
        "timestamp": "2026-08-18T04:00:00Z"
      }
    ]
  }
  ```

### `GET /v1/ponds/{pond_id}/risk`
Get current AI risk assessment score and risk tier.
- **Response (200 OK)**:
  ```json
  {
    "score": 0.15,
    "tier": "low",
    "synced_at": "2026-08-18T07:30:00Z"
  }
  ```

---

## 📡 Data Quality Signals

### `GET /v1/data-quality`
Get cross-pond sensor trust, staleness, and blind-state signals.
- **Response (200 OK)**:
  ```json
  {
    "signals": [
      {
        "pond_id": "TN-01-001",
        "is_blind": false,
        "suppression_reason": null,
        "synced_at": "2026-08-18T07:30:00Z"
      }
    ]
  }
  ```

---

## ⚠️ Alerts

### `GET /v1/alerts`
List current alerts for accessible ponds.

### `POST /v1/alerts/{alert_id}/ack`
Acknowledge an alert.
- **Response (200 OK)**: `{"status": "acknowledged"}`

### `POST /v1/alerts/{alert_id}/feedback`
Submit labeled-data flywheel feedback (`correct` or `incorrect`).
- **Request Body**: `{"feedback": "correct"}`
- **Response (200 OK)**: `{"status": "recorded"}`

---

## 🤖 AI / LLM & Advisories

### `POST /v1/reason`
- **INTERNAL ONLY**. Do not call directly from client.

### `POST /v1/ask`
Submit farmer Q&A query (text/voice).
- **Request Body**: `{"question": "How to handle drop in pH?", "language": "ta"}`

### `GET /v1/advisories`
Fetch extension officer / AI published advisories.

---

## 🌐 I18N Translation

### `POST /v1/translate`
Translate text using IndicTrans2 / Bhashini backend.
- **Request Body**: `{"text": "Hello", "source": "en", "target": "ta"}`
