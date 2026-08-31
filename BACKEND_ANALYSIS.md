# AquaVerse Backend — Structure, Endpoint & Model Audit

Snapshot as of **2026-08-31**, branch `claude/repo-structure-endpoints-14iz62` (HEAD `9b428d8`).
This supersedes `FIX_PRIORITY.md` (dated 2026-08-17), which described the codebase in its
mostly-stubbed state. Every item that document flagged P0–P3 has since been implemented and
merged (commits `040ab01` → `9b428d8`, 19 commits). This document reflects the **current** state,
verified by reading the live source (not the old audit) and by running the unit test suite.

---

## 1. Architecture

FastAPI modular monolith, `app/<domain>/router.py` per domain, mounted under `/v1` in
`app/main.py`. Two-layer design (README's "non-negotiable" contract):

```
Quantitative Core (LightGBM boosters, real trained artifacts)
    │  numeric scores + SHAP, in-process, no network hop
    ▼
Reasoning Layer (Qwen3-8B + LoRA via vLLM — not yet wired; /v1/reason is a
                 validator-compliant stub, /v1/ask calls the real M3 engine
                 directly and narrates its payload without an LLM in the loop yet)
    │
    ▼
app/advisory/number_validator.py — regex-extracts every numeral the reasoning
layer emits and rejects/regenerates on any value not present in the upstream
tool-call payload. Enforced today on both /v1/reason and /v1/ask.
```

Stack: PostgreSQL 16 + TimescaleDB + PostGIS, Redis, MinIO/R2, vLLM (LLM layer — not yet
integrated; see §4). 12 domain packages under `app/`, 9 routers mounted in `main.py`.

---

## 2. Endpoint inventory

**35 business endpoints** across 9 routers + 3 utility endpoints (`/`, `/v1/health`, `/metrics`).
Status column reflects what actually executes today, not the docstring's aspiration.

| Domain | Method & Path | Auth | Status |
|---|---|---|---|
| **Identity** | `POST /v1/auth/otp/request` | public | ✅ Real — OTP issuance, rate-limited |
| | `POST /v1/auth/otp/verify` | public | ✅ Real — issues JWT |
| | `POST /v1/auth/token` | public | ✅ Real — Keycloak staff/admin login |
| | `GET /v1/auth/me` | any user | ✅ Real |
| **Ingest** | `POST /v1/logs` | farmer/staff | ✅ Real — DB write, idempotent, triggers alert rules |
| | `GET /v1/logs` | any user | ✅ Real — keyset pagination |
| | `POST /v1/media/upload-url` | any user | ✅ Real — presigned MinIO/R2 PUT |
| | `POST /v1/media/{id}/commit` | any user | ✅ Real — HEADs object before marking committed |
| | `POST /v1/ingest/sensor/{pond_id}` | HMAC device auth | ✅ Real — IoT device payload path |
| **Ponds & ML** | `GET /v1/ponds` | any user | ✅ Real — role-scoped, keyset pagination |
| | `GET /v1/ponds/{id}` | any user | ✅ Real |
| | `GET /v1/ponds/{id}/timeseries` | any user | ✅ Real — from `Log` rows |
| | `GET /v1/ponds/{id}/events` | any user | ⚠️ Real but log-only — synthesizes events from `Log`; `Alert`-sourced events not wired into this feed yet |
| | `GET /v1/ponds/{id}/risk` | any user | ✅ **Real M2 LightGBM model** (§3) |
| | `GET /v1/risk/worklist` | staff/admin | ✅ Real — same M2 engine, scored live per request (documented as not scaling past demo size) |
| | `GET /v1/ponds/{id}/forecast/do` | any user | ⚠️ Real but not ML — honest empirical seasonal-quantile baseline; **no trained temporal model exists** (see §3.4) |
| | `GET /v1/models` | staff/admin | ✅ Real — backed by `model_registry` table, auto-synced |
| | `GET /v1/models/metrics` | staff/admin | ✅ Real except `cache_hit_rate` (hardcoded 0.0 — no cache exists for this layer, honestly labeled) |
| | `GET /v1/models/drift` | staff/admin | ✅ Real — PSI-based |
| | `GET /v1/data-quality` | staff/admin | ✅ Real — computed from `Log` rows |
| **Alerts** | `GET /v1/alerts` | any user | ✅ Real |
| | `POST /v1/alerts/{id}/ack` | any user | ✅ Real |
| | `POST /v1/alerts/{id}/feedback` | any user | ✅ Real |
| **Advisory** | `POST /v1/reason` | internal token | ⚠️ Validator-compliant stub — hand-built explanation string, not an LLM call (vLLM/Qwen3-8B never wired) |
| | `POST /v1/ask` | farmer/staff | ⚠️ Real M3 engine + real narration + real validator, **but the pond snapshot fed to it is a hardcoded 28-field fixture**, not a real per-pond feature aggregation (see §3.3) |
| | `GET /v1/advisories` | any user | ✅ Real |
| | `POST /v1/advisories/broadcast` | staff/admin | ✅ Real — persists + fans out via `alerts/fanout.py` |
| **Twin** | `GET /v1/twin/{id}/state` | any user | ✅ Real |
| | `GET /v1/twin/{id}/view` | any user | ✅ Real HTML dashboard (old f-string brace bug fixed) |
| | `POST /v1/twin/{id}/whatif` | any user | ✅ Real — calls `simulator_adapter.py` |
| **Geo** | `GET /v1/geo/ponds` | any user | ✅ Real — PostGIS `ST_AsGeoJSON` |
| | `GET /v1/geo/clusters` | any user | ✅ Real — space-time clustering over real alert/risk history |
| **i18n** | `POST /v1/translate` | any user | ✅ Real — wired to translation backend + Redis cache |
| **Reports** | `GET /v1/reports/export` | staff/admin | ✅ Real — ARQ job queue, PDF/XLSX workers |
| | `GET /v1/reports/export/{job_id}` | staff/admin | ✅ Real — job status polling |
| **Utility** | `GET /`, `GET /v1/health`, `GET /metrics` | public | ✅ Real |

**RBAC**: every route above now has a `CurrentUser`/`CurrentStaff`/farmer-scope dependency
(the old audit's P0.1 — "33 of 36 unauthenticated" — is fully closed). Pagination is real
keyset pagination everywhere except `/v1/risk/worklist`, which uses offset-cursor pagination
by design (documented: ranking is computed fresh per request, not against a stable sort key).

**Remaining known gaps** (all explicitly documented in source, not hidden):
- `/v1/reason` and the reasoning-layer half of `/v1/ask` — no vLLM/Qwen3-8B/LoRA integration
  exists yet; both paths produce validator-safe text without an LLM call.
- `/v1/ask`'s `PondSnapshot` is a static fixture, not built from real per-pond data.
- `/v1/ponds/{id}/forecast/do` is a real statistical baseline, not a trained temporal model.
- `feed_source` in the M3 payload is explicitly flagged `PLACEHOLDER_simulator_curve` — not a
  real manufacturer feed table.
- Several M2/M3 input fields (wind, solar, rain, feed logs, biomass, Secchi depth) have no
  ingestion pipeline yet and fall back to documented placeholder constants.

---

## 3. Working state of the 3 ML models

All three are **real, trained LightGBM boosters** (`.txt` model files under
`ml/serving/m3/models/`), loaded in-process via `lru_cache`d bundle loaders — no network hop,
no mock. Verified for this report by running the test suite:

```
tests/unit/test_m3_engine.py           — 21 tests, engine wiring + determinism
tests/unit/test_m3_model_accuracy.py   — re-scores held-out test-split parquet
                                          data through the live boosters and
                                          independently recomputes MAE/RMSE/R²
tests/unit/test_number_validator.py    — guardrail correctness
→ all pass (51/51 unit tests green, full run)
```

### 3.1 M2 — Mortality Risk (`m2_mortality_risk_baseline.txt`)
- **Serves**: `GET /v1/ponds/{id}/risk`, `GET /v1/risk/worklist`
- **Task**: binary classifier — elevated mortality risk from environmental stress in the next
  24h. **Explicitly NOT a disease/pathogen classifier** (no WSSV/EHP/AHPND signal in training
  data) — documented in the module docstring to prevent copy from mislabeling it.
- **Real test-set metrics** (`m2_mortality_risk_baseline_results.json`, n=40,126):
  AUC-ROC **0.907**, AUC-PR **0.656**, Brier **0.120**, operating threshold **0.589**
  (tuned to 79.6% recall / 48.2% precision at that point).
- **Real inputs**: DO, TAN, pH, water temp, alkalinity, NO₂, NO₃, salinity, species,
  day-of-culture (from `Log`/`Pond`/`Crop`).
- **Placeholder inputs** (no ingestion pipeline exists yet): wind, solar radiation, rainfall,
  feed logs, biomass estimate, Secchi depth, management quality — all individually documented
  with the exact placeholder value used.
- **SHAP**: real per-request `shap.TreeExplainer` attributions, top-5 features with a real
  (non-imputed) value only — imputed placeholder fields are never shown as an "explanation."
- **Feature order**: verified empirically against `booster.feature_name()` at load time
  (27 features), not hand-copied — a mismatch raises immediately rather than silently
  mis-scoring.
- **Also backs `GET /v1/models`**: `model_registry_sync.py` auto-registers this exact loaded
  bundle (real version string, real test metrics, real artifact SHA-256) on every read, so the
  registry can never drift from what's actually serving.

### 3.2 M3 — Overnight DO Minimum (`do_overnight_min_baseline.txt`)
- **Serves**: the "overnight DO forecast" field inside `/v1/ask`'s M3 decision payload (feed-hold
  logic gates on this).
- **Task**: regression — tonight's minimum dissolved oxygen (mg/L).
- **Real test-set metrics** (n=42,566): **R² = 0.988**, MAE = 0.083 mg/L, RMSE = 0.115 mg/L.
- Re-verified independently in `test_m3_model_accuracy.py` against held-out
  `do_forecast_table.parquet` (floor asserted at R² > 0.95 — well below the recorded 0.988, so
  the test has real regression-catching margin).

### 3.3 M3 — Daily Growth (`m3_daily_growth_baseline.txt`)
- **Serves**: `predicted_daily_gain_g` and the iterative harvest-date projection inside
  `/v1/ask`'s M3 payload.
- **Task**: regression — average daily weight gain (g/day) given current weight + environment.
- **Real test-set metrics** (n=42,266): **R² = 0.974**, MAE = 0.246 g/day, RMSE = 1.053 g/day.
- Independently re-verified in `test_m3_model_accuracy.py` (floor R² > 0.90).
- **Documented known limitation**: `project_harvest()` holds today's environmental snapshot
  constant across the whole forward walk. Validated against real data: a healthy day-40
  catfish pond projected 358 days to reach 120g against a typical ~150-day cycle — the
  docstring flags this as "a rough sanity check, not a farmer-facing harvest date" until the
  projection uses a seasonal/forecast trajectory instead of a frozen snapshot.
- **feed_source / manufacturer_table**: the M3 payload correctly cites a species-appropriate
  table name (e.g. "CP Aquaculture Vannamei Feeding Table v3"), but the underlying feed-quantity
  curve behind it is the simulator's own interpolation curve, explicitly flagged
  `PLACEHOLDER_simulator_curve` — not yet a digitized real manufacturer table.

### 3.4 What's *not* a trained model (for contrast)
`GET /v1/ponds/{id}/forecast/do` — despite living next to the M2/M3 boosters — is **not** one
of the three above. It's a documented empirical seasonal-quantile baseline (bucket a pond's own
historical DO readings by hour-of-day, take p10/p50/p90) because no TCN/TFT/PatchTST temporal
model exists anywhere in this repo. It's honest and useful, just not "model #4."

---

## 4. Summary

| Area | State |
|---|---|
| Auth/RBAC | ✅ Enforced on all 35 endpoints |
| Pagination | ✅ Real keyset everywhere; documented offset-cursor exception on the one live-ranked endpoint |
| Ponds/Logs/Media/Alerts/Twin/Geo/i18n/Reports domains | ✅ All real, DB- or object-store-backed |
| M2 mortality-risk model | ✅ Real, trained, tested, AUC-ROC 0.907 |
| M3 DO-overnight model | ✅ Real, trained, tested, R² 0.988 |
| M3 daily-growth model | ✅ Real, trained, tested, R² 0.974 |
| LLM reasoning layer (Qwen3-8B + LoRA / vLLM) | ❌ Not yet wired — this is the largest remaining gap |
| `/v1/ask`'s per-pond feature aggregation | ❌ Still a hardcoded snapshot, not live DB data |
| DO temporal forecasting model | ❌ No trained model exists; real baseline stands in |
| Real manufacturer feed tables | ❌ Placeholder curve, correctly labeled |

Everything the 2026-08-17 `FIX_PRIORITY.md` flagged as P0–P3 stub work has been implemented and
merged. The system's honest remaining gap is the reasoning layer itself (vLLM/Qwen3-8B/LoRA) and
turning `/v1/ask`'s input into a live per-pond feature snapshot — both called out in-repo, not
discovered by this audit.
