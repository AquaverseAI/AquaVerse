# Backend Sync Notes — AquaVerse AI

**Status: LOCKED 18-Endpoint API Contract Alignment (Scope A: Pure Sensor & Photo Media API).**
Last updated: 2026-08-18

This document serves as the single source of truth for backend endpoint status across both the Farmer and Extension Officer client flows.

---

## 1. Locked API Endpoint Matrix

| # | HTTP Method | Endpoint Path | Client Method (`ApiClient`) | Used By | Status |
|---|---|---|---|---|---|
| 1 | `POST` | `/v1/auth/otp/request` | `requestOtp(body)` | Farmer + Officer | `live` / `mocked` fallback |
| 2 | `POST` | `/v1/auth/otp/verify` | `verifyOtp(body)` | Farmer + Officer | `live` / `mocked` fallback |
| 3 | `GET` | `/v1/auth/me` | `getMe()` | Farmer + Officer | `live` / `mocked` fallback |
| 4 | `GET` | `/v1/ponds` | `getPonds()` | Farmer + Officer | `live` / `mocked` fallback |
| 5 | `GET` | `/v1/ponds/{pond_id}` | `getPondDetails(pondId)` | Farmer + Officer | `live` / `mocked` fallback |
| 6 | `GET` | `/v1/ponds/{pond_id}/events` | `getPondEvents(pondId)` | Farmer + Officer | `live` / `mocked` fallback |
| 7 | `GET` | `/v1/ponds/{pond_id}/risk` | `getPondRisk(pondId)` | Farmer + Officer | `live` / `mocked` fallback |
| 8 | `GET` | `/v1/data-quality` | `getDataQuality()` | Farmer + Officer | `live` / `mocked` fallback |
| 9 | `GET` | `/v1/logs` | `getLogs()` | Farmer + Officer | `live` / `mocked` fallback |
| 10 | `POST` | `/v1/media/upload-url` | `getUploadUrl(body)` | Farmer + Officer | `live` / `mocked` fallback |
| 11 | `POST` | `/v1/media/{media_id}/commit` | `commitMedia(mediaId)` | Farmer + Officer | `live` / `mocked` fallback |
| 12 | `GET` | `/v1/alerts` | `getAlerts()` | Farmer + Officer | `live` / `mocked` fallback |
| 13 | `POST` | `/v1/alerts/{alert_id}/ack` | `ackAlert(alertId)` | Farmer + Officer | `live` / `mocked` fallback |
| 14 | `POST` | `/v1/alerts/{alert_id}/feedback` | `sendAlertFeedback(alertId, body)` | Farmer | `live` / `mocked` fallback |
| 15 | `GET` | `/v1/advisories` | `getAdvisories()` | Farmer + Officer | `live` / `mocked` fallback |
| 16 | `POST` | `/v1/ask` | `askAqua(body)` | Farmer | `live` / `mocked` fallback |
| 17 | `POST` | `/v1/reason` | `getReasoning(body)` | Backend Orchestration | `backend-internal` |
| 18 | `POST` | `/v1/translate` | `translate(body)` | Farmer + Officer | `live` / `mocked` fallback |

---

## 2. Deprecated / Out-of-Scope Endpoints

- **`POST /v1/logs`**: Fully removed from client writes per contract. All manual input fields (Feed Given, Mortality, Feed Tray Check, Water Appearance chips) have been stripped from `LogEntryScreen`.
- **Photo Media API**: Water appearance, turbidity, and color checks are submitted via two-phase media upload: `POST /v1/media/upload-url` + `POST /v1/media/{media_id}/commit`.
- **`GET /v1/logs`**: Retained for reading IoT log history telemetry.
- **`GET /v1/ponds/{pond_id}/forecast/do`**, **`/v1/forecast/*`**, **`/v1/geo/*`**, **`/v1/twin/*`**, **`/v1/models/*`**, **`/v1/reports/*`**: Fully removed.

---

## 3. Log Screen Architecture (Scope A)

- **Top Full-Screen Coverage**: Live IoT sensor telemetry (DO, pH, Salinity, Temperature, Water Quality Index) auto-synced from backend with `StalenessBadge`.
- **Photo Media Capture**: 3-slot photo media upload strip for water appearance, clarity, and algal check using two-phase media API.
- **Zero Manual Input**: Eliminates schema conflicts and payload mismatch.
