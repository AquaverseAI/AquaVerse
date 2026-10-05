# Non-Negotiable Rules — AquaVerse AI Frontend

## Rule 1: Three-Layer Storage Contract
1. **Drift (SQLite)** ➔ Structured application data only (Ponds, Water Logs, Alerts, Sync Outbox).
2. **`flutter_secure_storage`** ➔ Authentication tokens, refresh tokens, secrets.
3. **`shared_preferences`** ➔ Simple launch-gating flags only (`has_onboarded`). No other key allowed without explicit architectural review.

## Rule 2: Routing Decision Table
Must adhere strictly to splash route resolution:

| `has_onboarded` | Valid/refreshable token? | Route destination |
|---|---|---|
| `false` | — | Full Onboarding (`/onboarding/language`) |
| `true` | Yes | Today Dashboard (`/today` or `/officer/dashboard`) |
| `true` | No | Re-login (`/login` — OTP verification only, no language/role pickers) |

## Rule 3: PRD-AV-04 Rule Discipline
Rule numbers R1–R9 refer exclusively to the nine numbered rules in PRD-AV-04 §7. Do not invent or assign arbitrary R-numbers to other app constraints or guidelines.

## Rule 4: Locked Tech Stack & Explicit Exclusions
- **Approved Stack**: Flutter, Riverpod, Drift (SQLite), GoRouter, Dio, Retrofit, `flutter_secure_storage`, `shared_preferences`, `just_audio`.
- **Explicit Exclusions**: No Hive, Bloc/Provider/GetX, SSL pinning, root detection, Play Integrity, Redis, or Celery in this client application.

## Rule 5: Zero-Capex, 12-Week MVP Framing
Before introducing any new library or abstraction layer, verify it is explicitly required by PRD-AV-04 §5–§6. Avoid speculative enterprise-grade scope creep.
