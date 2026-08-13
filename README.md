# AquaVerse AI — Backend Service

Predictive analytics backend for fish/shrimp aquaculture in Tamil Nadu.
Modular monolith: FastAPI + PostgreSQL 16 + TimescaleDB + PostGIS + Redis + vLLM.

## Quick Start

```bash
# 1. Clone and configure
git clone <repo>
cd aquaverse-backend
cp .env.example .env
# Edit .env with your real secrets

# 2. Boot the full stack
docker compose -f infra/docker-compose.yml up -d

# 3. Run migrations
docker compose -f infra/docker-compose.yml exec app alembic upgrade head

# 4. Seed the database
docker compose -f infra/docker-compose.yml exec app python scripts/seed_db.py

# 5. Verify
curl http://localhost:8000/v1/health
curl http://localhost:8000/openapi.json | python -m json.tool | head -20
```

## Development Setup (without Docker)

```bash
# Python 3.11+
python -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
pre-commit install

# Run tests (testcontainers spins up PG + Redis automatically)
pytest tests/ -x --timeout=120

# Type check
mypy app/

# Lint
ruff check app/ tests/
ruff format app/ tests/
```

## Architecture

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
  ├── /v1/forecast/*      ← temporal model forecasts (TFT/TCN/PatchTST)
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

## Two-Layer Architecture (Non-Negotiable)

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

## Number Validator

Every response from the reasoning layer is checked by `app/advisory/number_validator.py`:

1. Regex-extract every numeral from LLM output
2. Check each against the tool-call payload
3. Reject + regenerate on any mismatch (server-side, in request path)
4. Increment `rejected_attempts` counter
5. `GET /v1/models/metrics` exposes this counter — must read **0** in steady state

## Key Conventions

- **Timestamps**: stored UTC, served `Asia/Kolkata`. Never naive.
- **Pagination**: cursor-based everywhere (`?cursor=&limit=` → `{items, next_cursor}`).
- **Errors**: RFC 9457 Problem Details (`{type, title, status, detail, instance}`).
- **Idempotency**: write endpoints accept `client_log_id`; replays return `200` + original record.
- **Forecasts**: always return uncertainty bands — never bare point estimates.
- **Blind-state suppression**: always visible on the response payload — never silent.

## Project Structure

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

## CI / CD

Every pull request runs:
1. `ruff check` + `ruff format --check`
2. `mypy --strict app/`
3. `pytest tests/unit tests/integration` (testcontainers)
4. `schemathesis run openapi.yaml` (contract tests)
5. `openapi-diff` — fails on unversioned breaking changes

Merges to `main` additionally run:
6. SDK regeneration (`.github/workflows/sdk-gen.yml`)

## Free Tier Compliance

Every infrastructure component runs on a single VPS with no paid cloud services required:
- PostgreSQL 16 + TimescaleDB + PostGIS: self-hosted
- Redis: self-hosted
- MinIO: self-hosted (or Cloudflare R2 free tier)
- Caddy: free, open source
- Grafana + Prometheus: free, open source
- MLflow: self-hosted
- vLLM / llama.cpp: self-hosted
