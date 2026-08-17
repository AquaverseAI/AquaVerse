# Backend Sync Notes — AquaVerse AI

**Status: LOCKED 19-Endpoint API Contract Alignment.**
Last updated: 2026-08-17

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

- **`POST /v1/logs`**: Deprecated for log creation writes per contract. Photos use `/v1/media/upload-url` + `/v1/media/{media_id}/commit`. Manual observations (Feed, Mortality, Feed Tray Check, Water Appearance) are cached locally in Drift (`LogsTable`) with `TODO(contract)` marker for future sync endpoint. `GET /v1/logs` remains active for reading log history.
- **`GET /v1/ponds/{pond_id}/forecast/do`**: Fully removed.
- **`GET /v1/forecast/*`**, **`GET /v1/geo/*`**, **`GET /v1/twin/*`**, **`GET /v1/models/*`**, **`GET /v1/reports/*`**: Fully removed.

---

## 3. Log Screen Architecture (Scope C)

- **Read-Only Top Card**: Live sensor readings (DO, pH, Temp, Salinity) auto-synced from IoT backend, displayed with `StalenessBadge`.
- **"What sensors can't see" Section**: Manual inputs for Feed Given (kg), Mortality Count, Feed Tray Check (Empty/Some/Lots), and Water Appearance (Good/Average/Bad).
- **Photos Section**: Two-phase media upload via `/v1/media/upload-url` and `/v1/media/{media_id}/commit`.
- **Drift Caching**: Local database handles offline queueing (`LogsTableCompanion`).
