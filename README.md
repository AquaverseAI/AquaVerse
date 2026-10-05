# AquaVerse AI

> Predictive analytics backend + offline-first Flutter mobile app for aquaculture farmers and extension officers in Tamil Nadu.

---

## Frontend — Flutter Mobile Application

AquaVerse AI mobile is an offline-first, voice-guided Flutter application that enables seamless pond management, daily water parameter logging, AI voice assistance, automated risk alerts, and extension officer supervision.

### 🌟 Tech Stack

- **Framework**: Flutter 3.8 / Dart SDK `^3.8.0`
- **State Management**: `flutter_riverpod` (`^2.5.1`) with `riverpod_annotation`
- **Routing**: `go_router` (`^14.2.0`)
- **Database & Offline Queue**: `drift` (`^2.34.3`) + `sqlite3_flutter_libs` (SQLite outbox pattern)
- **Secure Secret Storage**: `flutter_secure_storage` (`^9.2.2`)
- **Simple Launch Gating**: `shared_preferences` (`^2.3.2`) — restricted strictly to `has_onboarded` flag
- **Networking**: `dio` (`^5.7.0`) + `retrofit` (`^4.4.1`)
- **Audio & Media**: `just_audio` (`^0.9.40`) for TTS voice guidance
- **Push Notifications**: `firebase_messaging` (`^15.1.3`) + `flutter_local_notifications` (`^17.2.3`)

### 🔒 3-Layer Storage Contract

| Storage Layer | Allowed Usage | Constraints |
|---|---|---|
| **Drift (SQLite)** | Structured data (ponds, water logs, risk alerts, sync outbox) | Offline-first, reactive query streams |
| **`flutter_secure_storage`** | Auth tokens, refresh tokens, API credentials | Encrypted device keychain/keystore |
| **`shared_preferences`** | Simple launch-gating flag (`has_onboarded`) | Strictly restricted to `has_onboarded` only |

### 🔀 Onboarding & Routing Matrix

| `has_onboarded` | Valid/refreshable Token | Navigation Target |
|---|---|---|
| `false` | — | Full Onboarding (`/onboarding/language` ➔ `/mobile` ➔ `/otp` ➔ `/role`) |
| `true` | Yes | Today Dashboard (`/today` for Farmers, `/officer/dashboard` for Officers) |
| `true` | No | Re-login (`/login` — OTP only, no language/role pickers) |

### 📁 Directory Structure

```
lib/
├── app/                  # Application root & Riverpod config
├── core/                 # Core utilities & cross-cutting concerns
│   ├── config/           # App config & environment constants
│   ├── database/         # Drift SQLite database, tables, & connections
│   ├── errors/           # Failure & exception handling
│   ├── network/          # Dio HTTP client, Retrofit services, & auth API
│   ├── repositories/     # Offline-first repository implementations
│   ├── router/           # GoRouter route definitions & auth guards
│   ├── services/         # Audio TTS, connectivity monitoring, push notifications
│   ├── storage/          # SharedPreferences flag store & SecureStorage
│   ├── sync/             # Offline queue manager & auto-sync worker
│   └── theme/            # AquaVerse design system tokens & colors
├── features/             # Feature modules
│   ├── alerts/           # Risk alerts & warning center
│   ├── ask/              # Voice-first AI assistant & speech queries
│   ├── crop/             # Crop cycle management & stocking history
│   ├── help/             # Help center & FAQ resources
│   ├── log/              # Offline-first pond parameter logging
│   ├── notifications/    # Broadcast & targeted alert history
│   ├── officer/          # Extension officer dashboard & farmer list
│   ├── onboarding/       # Language selection, mobile entry, OTP, role picker
│   ├── ponds/            # Pond management & parameter thresholds
│   ├── profile/          # User profile & farm setup
│   ├── settings/         # App preferences & offline sync status
│   ├── splash/           # Animated splash screen & route guard
│   └── today/            # Farmer daily summary & task action cards
└── shared/               # Reusable UI widgets & components
    ├── models/           # Shared domain entities & enums
    └── widgets/          # AppCard, ActionCard, SpeakerButton, StatusDisc, StalenessBadge
```

### 🚀 Getting Started

```bash
# 1. Clone the repository
git clone -b farmer-application https://github.com/AquaverseAI/AquaVerse.git
cd AquaVerse

# 2. Install dependencies
flutter pub get

# 3. Run code generation (if updating Drift / Retrofit / Freezed schemas)
dart run build_runner build --delete-conflicting-outputs

# 4. Lint & test
flutter analyze
flutter test

# 5. Run the app
flutter run
```

---

## Backend — FastAPI Service

Predictive analytics backend for fish/shrimp aquaculture. Modular monolith: FastAPI + PostgreSQL 16 + TimescaleDB + PostGIS + Redis + vLLM.

### Requirements

- Docker with Compose v2 (full stack and infrastructure dependencies)
- Python 3.11 and `uv` (host backend development)
- Node.js 20 and npm (web frontend development)

Copy `.env.example` to `.env` and replace every `CHANGE_ME` value. Local `.env` files are
ignored by Git. The real FastAPI backend is the default; MSW is enabled only when
`VITE_USE_MSW=true` is set explicitly.

### Full Docker Stack

```bash
cp .env.example .env
docker compose -f infra/docker-compose.yml up -d --build
docker compose -f infra/docker-compose.yml exec app python scripts/seed_db.py
docker compose -f infra/docker-compose.yml ps
curl http://localhost:8000/v1/health
```

The app container runs `alembic upgrade head` before FastAPI starts. The seed is idempotent.

### Local Development

```bash
# Infrastructure
cp .env.example .env
docker compose -f infra/docker-compose.yml up -d db redis minio minio-init

# Backend terminal
make install
make migrate
make seed
make run

# Worker terminal
source .venv/bin/activate
python -m arq app.worker.WorkerSettings

# Frontend terminal (Vite proxies /v1 to localhost:8000)
cd frontend
cp .env.example .env
npm ci
npm run dev
```

Seeded development logins:

- Admin: `aquaverse_admin` / `AquaAdmin@2026!`
- Staff: `priya_officer` / `Officer@Nagapattinam2026`
- Farmer OTP: use the seeded farmer phone printed by `make seed`; development mode returns
  `dev_otp` from `POST /v1/auth/otp/request`.

### Validation

```bash
make lint
make typecheck
make test-unit
make test-integration
make test-cov
make smoke

cd frontend
npm ci
npm run build
npm run lint
npm run test:contract

# Against a running, migrated, seeded stack
cd ..
python scripts/e2e_smoke.py
```

Override smoke credentials with `AQUAVERSE_SMOKE_USERNAME`,
`AQUAVERSE_SMOKE_PASSWORD`, and `AQUAVERSE_BASE_URL`.

Local URLs: frontend `http://localhost:5173`, FastAPI `http://localhost:8000`, Swagger
`http://localhost:8000/docs`, ReDoc `http://localhost:8000/redoc`, MinIO console
`http://localhost:9001`, Prometheus `http://localhost:9090`, and Grafana
`http://localhost:3000`.

If migrations fail because extensions are unavailable, use the Compose `db` image; it bundles
TimescaleDB and PostGIS. If reports remain queued, verify Redis and the `worker` service are
healthy. Translation and outbound notification delivery require their external credentials;
the base application does not require them.

### Architecture

```
Client
  │
  ▼
Caddy (TLS termination)
  │
  ▼
FastAPI (uvicorn, async)
  ├── /v1/auth/*          ← identity (OTP + Keycloak RBAC)
  ├── /v1/ponds/*         ← pond CRUD, timeseries, events
  ├── /v1/logs            ← water-quality log ingestion
  ├── /v1/media/*         ← presigned upload / commit
  ├── /v1/risk/*          ← ML risk scores (LightGBM/EBM)
  ├── /v1/ponds/*/forecast/do ← empirical seasonal DO baseline
  ├── /v1/geo/*           ← GeoJSON endpoints, space-time clustering
  ├── /v1/twin/*          ← digital twin state + what-if simulation
  ├── /v1/reason          ← internal-only: Qwen3-8B + LoRA advisory
  ├── /v1/ask             ← farmer-facing conversational Q&A
  ├── /v1/alerts/*        ← alert rules, suppression, ack, feedback
  ├── /v1/advisories/*    ← broadcast advisories
  ├── /v1/models/*        ← model registry, metrics, drift
  ├── /v1/translate       ← IndicTrans2 / Bhashini + TTS
  ├── /v1/data-quality    ← sensor/data quality signals
  └── /v1/reports/*       ← PDF/XLSX exports
  │
  ├── PostgreSQL 16 + TimescaleDB + PostGIS (single DB)
  ├── Redis (cache + ARQ broker + rate limiting)
  ├── MinIO / R2 (object storage)
  └── vLLM (Qwen3-8B + 3 LoRA adapters) / llama.cpp fallback
```

### Two-Layer Architecture (Non-Negotiable)

```
┌─────────────────────────────────────────────────────┐
│  Quantitative Core                                   │
│  LightGBM / EBM / TCN / TFT / PatchTST              │
│  → produces ALL numbers: scores, forecasts, SHAP     │
└─────────────────────────────────────────────────────┘
           │  tool-call payload (scores + SHAP)
           ▼
┌─────────────────────────────────────────────────────┐
│  Reasoning Layer (Qwen3-8B + LoRA)                  │
│  → explains, diagnoses, converses                   │
│  → FORBIDDEN from emitting any numeral it didn't    │
│    receive in the tool-call payload                 │
│  → number_validator.py enforces this server-side    │
└─────────────────────────────────────────────────────┘
```

### Project Structure

```
aquaverse-backend/
├── app/               # FastAPI application
│   ├── core/          # security, rbac, errors, pagination, timezones
│   ├── db/            # SQLAlchemy models, session, base
│   ├── identity/      # OTP, Keycloak, audit
│   ├── ingest/        # log + media ingestion
│   ├── ml_inference/  # numeric models + vLLM client
│   ├── advisory/      # LLM guardrail lives here
│   ├── alerts/        # rules, suppression, fan-out
│   ├── twin/          # digital twin
│   ├── geo/           # geospatial endpoints
│   ├── i18n/          # translation + TTS
│   ├── reporting/     # PDF/XLSX exports
│   └── features/      # point-in-time feature views
├── alembic/           # DB migrations
├── ml/                # training configs, dataset manifest
├── tests/             # unit, integration, contract (schemathesis)
├── scripts/           # seed, restore drill, validator smoke test
├── infra/             # Docker Compose, Dockerfile, Caddy, Prometheus, Grafana
└── .github/workflows/ # CI: lint, mypy, pytest, openapi-diff; sdk-gen
```

### CI / CD

Every pull request runs:
1. `ruff check` + `ruff format --check`
2. `mypy --strict app/`
3. `pytest tests/unit tests/integration` (testcontainers)
4. `schemathesis run openapi.yaml` (contract tests)
5. `openapi-diff` — fails on unversioned breaking changes

Merges to `main` additionally run:
6. SDK regeneration (`.github/workflows/sdk-gen.yml`)

### Free Tier Compliance

Every infrastructure component runs on a single VPS with no paid cloud services required:
- PostgreSQL 16 + TimescaleDB + PostGIS: self-hosted
- Redis: self-hosted
- MinIO: self-hosted (or Cloudflare R2 free tier)
- Caddy: free, open source
- Grafana + Prometheus: free, open source
- MLflow: self-hosted
- vLLM / llama.cpp: self-hosted
