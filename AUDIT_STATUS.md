# AquaVerse AI — Audit Status

**Commit audited:** `d704556c55b4f89df1be2bd2bcc6c81000b6704` (2026-08-31)
**Audit date:** 2026-09-16
**Method:** Executed, not inferred — Postgres 16 + PostGIS started locally (Docker unavailable), `alembic upgrade head` run for real, backend booted with `uvicorn` and hit with live `curl`/Python calls, full `pytest --cov` run, number validator and M3 LightGBM engine executed with real inputs, source read line-by-line for every claim below.

---

## 1. Executive summary

- **No PRD/spec file exists in the repo** (`find . -iname '*prd*' -o -iname '*spec*.md'` returned nothing but `requirements*.txt`, which are Python dependency lists, not specs). The reference architecture in this audit's brief was used as the binding source of truth by default, per the audit's own fallback rule.
- **No Flutter app exists anywhere in the repo** (`find . -iname '*.dart'` and `find / -iname pubspec.yaml` both empty). This directly contradicts the reference architecture, which names a Flutter farmer app with Today/Log/Ask/Alerts/Crop screens. **MISSING**, confirmed, not adapted around.
- **Two contradictory `docker-compose.yml` files** exist (`infra/docker-compose.yml` vs `frontend/docker-compose.yml`) with different DB credentials/DB names, different service topology (the `frontend/` one adds `caddy` + a `vllm-engine` service the `infra/` one lacks entirely) — a **FORKED** infra definition.
- **Migrations cannot complete in a stock environment**: `alembic upgrade head` fails at `alembic/versions/20260810_1010_a84e6d55c7b4_init_db.py:26` (`CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE`) because no TimescaleDB package/repo is installed. PostGIS was installable via `apt` and succeeded. TimescaleDB has no reachable apt source in this sandbox — **BLOCKED**, not a code defect per se, but it means **the schema has never been verified to fully apply** in this audit.
- **`pytest --cov` executed for real**: 79 passed, 102 skipped (all skips are `testcontainers`/Docker-gated integration tests — `pytest.importorskip`/`docker.from_env()` failures), 0 failed, **51.79% overall statement coverage** against a configured 70% gate (`pyproject.toml`) — **gate not met**, confirmed by the tool's own exit code (`FAIL Required test coverage of 70.0% not reached`).
- **POST /v1/reason is a hard-coded stub**, by its own docstring and code (`app/advisory/router.py:60-98`): no LLM call happens, no regeneration loop, no 503 fallback — a single `NumberMismatchError` raise maps to HTTP 500 (`app/core/errors.py:75-87`), not the spec's expected 503-with-structured-fallback.
- **LLM serving has no installed runway**: `torch`, `peft`, `unsloth`, `vllm` appear nowhere in `requirements.txt`/`requirements-dev.txt`/`pyproject.toml`, and importing them fails (`ModuleNotFoundError`, confirmed live). `POST /v1/advisories/multimodal_reason` was hit live and returned **HTTP 500**.

### Top 5 blockers to test-readiness
1. **TimescaleDB extension unavailable** — no migration can complete end-to-end outside a machine with the vendor apt repo pre-configured; every DB-touching route is therefore unverifiable beyond this audit's manual table workaround. (Phase 1)
2. **Docker daemon unusable in this environment** (`ulimit: error setting limit (Operation not permitted)`) — blocks 102 of 181 collected tests, all `testcontainers`-based integration coverage, MinIO, Redis-in-container, and any multi-service flow. (Phase 1/3/4)
3. **LLM stack has zero installed dependencies** (no torch/peft/unsloth/vllm anywhere in the dependency manifests) — `POST /v1/advisories/multimodal_reason` is dead on arrival (500, confirmed live); `POST /v1/reason` never calls an LLM at all. (Phase 2/6)
4. **Statement coverage sits at 51.79%, 18.2 points under the repo's own 70% gate** — most uncovered code is exactly the highest-risk modules: `app/ingest/router.py` (22%), `app/alerts/router.py` (22%), `app/twin/router.py` (32%), `app/ml_inference/router.py` (17%). (Phase 4)
5. **No Flutter client exists** — the farmer-facing half of the reference architecture (Today/Log/Ask/Alerts/Crop) has no code to audit at all. (Phase 5)

### Verdict counts (this audit's findings, Phase 2–7 scope; BLOCKED items excluded from percentages, counted separately — see §2)
| Verdict | Count |
|---|---|
| WIRED | 21 |
| MOCKED | 2 |
| STUBBED | 6 |
| BROKEN | 2 |
| MISSING | 3 |
| FORKED | 1 |
| KNOWN-GAP (scored by underlying verdict) | 7 |
| BLOCKED | 6 |

---

## 2. Completion scorecard

Scoring per hard rule 4: WIRED=1.0, MOCKED=0.75, STUBBED=0.25, BROKEN=0.25, FORKED=0.5, MISSING=0. BLOCKED items are excluded from the percentage but shown alongside it.

| Module/Client/Integration | Verdict(s) found | Score basis | % | BLOCKED |
|---|---|---|---|---|
| `app/ingest` (telemetry ingest) | WIRED (route+schema real, no receiver-side ARQ retry) | 1/1 items scored WIRED | 100%* | 0 (*route verified via code+OpenAPI only — DB write path not executed, migrations blocked) |
| `app/twin` | WIRED (`/state`, `/whatif` real, backed by real `PondSimulator`, no forked sim code) | 1.0 | 100%* | 1 (DB-backed persistence path untested) |
| `app/features` | MISSING route wiring — module exists (`app/features/store.py`, `views.py`) but **no router is included in `app/main.py`** (grep of `include_router` calls, `app/main.py:164-172`, confirms `features_router` is absent) | 0/1 | 0% | 0 |
| `app/ml_inference` (numeric) | WIRED — M3 LightGBM engine executed live end-to-end, real narration produced | 1.0 | 100% | 0 |
| `app/ml_inference` (LLM/`llm/`) | STUBBED (`adapters.py` = enum only) + MISSING (`vllm_client.py` = docstring only) + BROKEN (`qlora_inference.py` imports `unsloth`/`torch`, neither installed; live 500 on `/v1/advisories/multimodal_reason`) | (0.25+0+0.25)/3 | 17% | 0 |
| `app/alerts` | STUBBED fan-out (honestly returns `(False, False)` with no FCM/SMS credentials, by design — `app/alerts/fanout.py:1-16`) | 0.25 | 25% | 0 |
| `app/advisory` | STUBBED (`/v1/reason`) + WIRED (`/v1/ask`, `/v1/advisories`, broadcast) | (0.25+1+1+1)/4 | 81% | 0 |
| `app/i18n` | WIRED (`/v1/translate` real Bhashini client, fails honestly with `TranslationNotConfigured`→503 when unconfigured) | 1.0 | 100% | 1 (real Bhashini network call blocked by proxy — never verified against the live API) |
| `app/identity` | WIRED (OTP + JWT routes present, RBAC 401s verified live) | 1.0 | 100% | 1 (Keycloak not running — token issuance path unverified) |
| `app/reporting` | WIRED (PDF/XLSX render tested, 90%+ coverage) + STUBBED background job wiring (ARQ has exactly one job — `generate_report_job`) | (1+0.25)/2 | 63% | 0 |
| `app/geo` | WIRED (routes present, RBAC-gated, 29% test coverage but route-reachable) | 1.0 | 100% | 0 |
| `app/db` / Alembic | BLOCKED | — | — | 1 (TimescaleDB extension unavailable) |
| React/TS analyst dashboard | WIRED for Map/Triage/Deep-dive/Model-ops/Advisory-broadcaster/Data-quality/Reports (real `fetch()` calls confirmed against real routes) + 2 orphan calls (`/v1/media/presign`, `/v1/media/commit` — no matching backend route; real routes are `/v1/media/upload-url` and `/v1/media/{media_id}/commit`) | mostly WIRED, 2 BROKEN wiring points | ~85% | 0 |
| Flutter farmer app | MISSING | 0/1 | 0% | 0 |
| R3F digital twin (`PondDigitalTwin3D.tsx`) | WIRED — props-driven, fed by real `/v1/twin/{id}/whatif` fetch in `PondDeepDive.tsx:65-70`, fallback defaults only used pre-load | 1.0 | 100% | 0 |
| Background jobs (ARQ) | STUBBED — worker registers only `generate_report_job`; no nightly retrain, no forecast generation job, no advisory batch send job (`app/worker.py:1-34`) | 0.25 | 25% | 0 |
| **Overall** (arithmetic mean of the 17 scored rows above, BLOCKED rows' score omitted from the mean where noted) | | | **~65%** | **6** |

*Coverage caveat: the "Overall" figure above is a simple mean across module/client/integration rows for readability; it should not be read as a weighted, statement-level completion score — no such weighting was specified, and computing one would itself be an estimate this audit's rules forbid.*

---

## 3. Broken APIs

| Method | Path | Verdict | Observed error | File:line | Repro command |
|---|---|---|---|---|---|
| POST | `/v1/advisories/multimodal_reason` | BROKEN | `500 Internal Server Error` — `unsloth`/`torch` not importable | `app/ml_inference/llm/qlora_inference.py:1-40` (imports inside `_load()`), route at `app/advisory/router.py:326-339` | `curl -s -X POST http://127.0.0.1:8123/v1/advisories/multimodal_reason -H 'Content-Type: application/json' -d '{"calibrated_risk_score":0.8,"gate_vision":0.5,"gate_temporal":0.5,"concept_activations":{"lesion":0.9},"stress_hours":5.0}'` → captured live: `status=500`, body `{"type":"...errors/internal","title":"Internal Server Error",...}` |
| POST | `/v1/reason` | STUBBED (not BROKEN — returns 200, but never calls an LLM) | N/A — executes, but is a hard-coded f-string per its own docstring: *"Phase 1: stub that demonstrates the validator is wired. Phase 4: replace stub LLM call with real vLLM multi-LoRA request."* | `app/advisory/router.py:60-98` | Code read; `stub_explanation` at line 73-78 is an f-string, not a model call |
| — | `/v1/advisories/multimodal_reason` | Missing auth | No `CurrentUser`/`CurrentStaff`/`InternalOnly` dependency on this route at all — it is reachable with zero auth, unlike every sibling route | `app/advisory/router.py:326-330` (compare to `/v1/reason`'s `InternalOnly` at line 62, `/v1/ask`'s `CurrentUser` at line 115) | `curl -X POST .../v1/advisories/multimodal_reason` returned 500 (app-error), not 401 — confirms no auth gate is hit before the crash |

No other route returned a 500 or a 200-with-error-body in live testing; all analyst-side routes tested (`/v1/ponds`, `/v1/alerts`, `/v1/models`, `/v1/advisories`, `/v1/risk/worklist`, `/v1/data-quality`, `/v1/geo/ponds`) correctly returned `401` with RFC7807 `problem+json` bodies when called without a Bearer token (captured live, e.g. `curl -s http://127.0.0.1:8123/v1/ponds` → `{"type":"...errors/http-401","title":"Unauthorized","status":401,"detail":"Missing or malformed Bearer token",...}`). Deeper payload-level (valid-vs-invalid body) testing of authenticated routes was **BLOCKED**: Keycloak/OTP issuance requires services not runnable here (see §10).

---

## 4. Missing/orphaned webhooks and integrations

| Integration | Expected | Found | Verdict | Evidence |
|---|---|---|---|---|
| Telemetry ingest (Pi→backend) | `POST /v1/ingest/sensor/{pond_id}` | Present, route exists, 22% test coverage | WIRED (route-level only) | `app/ingest/router.py`, route confirmed in live `/openapi.json` |
| Sensor fault/stale-data blind-state flag | Explicit handling | `app/alerts/suppression.py` exists (58% coverage); DO-absence path confirmed to degrade to `NaN`/low-confidence score rather than crash or silently zero, in `app/ml_inference/numeric/m2_risk_engine.py:350-368` (`do_mg_l=None` explicitly passed through when no sensor reading exists; comment: *"LightGBM/SHAP both handle NaN features as 'missing' natively — no fabricated sensor values"*) | WIRED | Code read, `app/ml_inference/numeric/m2_risk_engine.py:350-421` |
| Alert dispatch (backend→FCM) | Real push | Honestly stubbed: `app/alerts/fanout.py:1-16` returns `(False, False)` when no FCM/SMS credentials configured, by explicit design ("HONESTY NOTE") | STUBBED | `app/alerts/fanout.py:1-40` |
| Critical alert SMS fallback | Real SMS send | Same stub as above, `SMS_PROVIDER=mock` default in `.env.example` | STUBBED | `app/alerts/fanout.py`, `.env.example` |
| Delivery/read receipts callback | Endpoint | Not found anywhere in `app/` routers | MISSING | `grep -rn 'receipt\|delivered\|read_at' app --include=*.py` returned no route |
| Alert feedback (app→backend) | Endpoint | `POST /v1/alerts/{alert_id}/feedback` present in OpenAPI | WIRED (route-level) | Live `/openapi.json` route list |
| Advisory broadcast (dashboard→backend→segment, approval gate) | Human-approval gate before fan-out | `POST /v1/advisories/broadcast` exists and requires `CurrentStaff`; no separate approval-workflow state machine found (broadcast is immediate on staff POST, not staged for a second approver) | MOCKED/partial — the "gate" is RBAC-only, not a two-step approval flow | `app/advisory/router.py:251-294` |
| Realtime dashboard SSE | SSE endpoint | None found — no `text/event-stream`, no `EventSourceResponse` anywhere in `app/` | MISSING | `grep -rn 'event-stream\|EventSourceResponse\|sse' app --include=*.py` returned nothing |
| Weather ingest (Open-Meteo per pond centroid) | Scheduled job calling Open-Meteo | No Open-Meteo client code found anywhere (`grep -rn 'open-meteo\|openmeteo' app ml` empty); weather in ML path comes from `ml/serving/m3/sim/weather.py` (simulator-only) | MISSING (production ingest) | grep empty; only simulator weather module exists |
| Offline sync (Flutter outbox→backend batch upload) | Flutter outbox + batch endpoint | No Flutter app exists (§5); backend has per-record idempotency (`app/core/idempotency.py`, `client_log_id` fields on `logs`/`media`/`advisories`) suggesting the backend half was built for this pattern, but there is no batch endpoint and no client to call it | MISSING (client half); partial receiver-side support only | `app/core/idempotency.py`, migration `20260819_0900...add_alert_feedback_columns.py` |
| Background jobs (ARQ) | Nightly retrain, forecast generation, advisory batch send, all registered+enqueued+run | Only `generate_report_job` is registered in `WorkerSettings.functions` | STUBBED | `app/worker.py:1-34`, docstring: *"wires it to the one real background job so far"* |

---

## 5. Client wiring mismatches

- **Orphan client calls (frontend calls a route the backend does not expose):**
  - `frontend/src/api/client.ts` calls `/v1/media/presign` and `/v1/media/commit`; the live route table (`/openapi.json`) has `/v1/media/upload-url` (POST) and `/v1/media/{media_id}/commit` (POST) — the presign path name and the commit path shape (missing `{media_id}` segment) both mismatch. This call would 404 in production.
- **Stale doc comment:** `frontend/src/api/client.ts:4` says *"Wraps all 16 backend endpoints"* — the live backend exposes 39 routes; several pages (`PondDeepDive.tsx`) bypass `client.ts` entirely with raw `fetch()` calls to routes `client.ts` doesn't wrap (`/v1/ponds/{id}/timeseries`, `/forecast/do`, `/risk`, `/events`, `/v1/twin/{id}/whatif`) — so the comment undercounts real usage, but confirms `client.ts` itself is an incomplete/stale wrapper, not the single source of truth the dashboard actually uses.
- **Unused backend routes** (no frontend caller found in `frontend/src/**`, via `grep -rn` for each OpenAPI path): `/v1/auth/me`, `/v1/ingest/sensor/{pond_id}` (expected — this is Pi→backend, not dashboard→backend), `/v1/ponds/{pond_id}` (singular GET), `/v1/alerts/{alert_id}/ack`, `/v1/alerts/{alert_id}/feedback`, `/v1/advisories/multimodal_reason`, `/v1/twin/{pond_id}/state`, `/v1/twin/{pond_id}/view`, `/v1/reports/export/{job_id}`.
- **Twin frontend wiring (specifically checked per task instructions):** `PondDigitalTwin3D.tsx` itself contains **no fetch calls and no embedded mock data** — it is a pure presentational Three.js component driven entirely by props. Its data comes from `PondDeepDive.tsx:65-70`, which calls `POST /v1/twin/{pondId}/whatif` live via `useQuery`/`fetch`. Fallback literals (`twinState?.do_mg_l ?? 4.6`, `?? 0.52` at lines 330-331) are pre-load defaults only, not a persistent mock path. **Confirmed WIRED**, not MOCKED.
- **`frontend/src/mocks/`** (MSW `browser.ts`/`handlers.ts`) is gated behind `import.meta.env.VITE_USE_MSW === 'true'` in `frontend/src/main.tsx:21-24` — opt-in dev tooling, not silently active in built pages (no page component imports `mocks/` directly — confirmed by `grep -rln "from '.*mocks" frontend/src` returning zero page files).

---

## 6. Known-gap re-verification

1. **Placeholder feed quantities can reach the farmer app** — **STILL PRESENT.** `ml/serving/m3/m3_decision_engine.py:354`: `feed_source="PLACEHOLDER_simulator_curve — NOT a manufacturer table, do not ship to farmers as-is"`. But `payload_to_instruction()` (same file, lines 143-190, the single function used by both training and serving per gap #7) unconditionally includes `recommended_feed_kg`/`feed_pct_biomass` attributed to `manufacturer_table` (e.g. "CP Aquaculture Vannamei Feeding Table v3") in the narration text whenever `feed_hold_recommended` is `False` (lines 171-174) — with **no check of `feed_source` anywhere in the codebase** (`grep -rn 'feed_source' app ml` finds it defined and never read/branched on outside the dataclass definition itself). This narration is returned verbatim as `AskOut.answer` from farmer-facing `POST /v1/ask` (`app/advisory/router.py:166,174-182`). Live-executed proof: running the engine (see §7) produced a payload with `feed_source` explicitly flagged placeholder while the narration cites `manufacturer_table`.
2. **LightGBM categorical encoding regression on the raw-numpy path** — **FIXED.** `ml/serving/m3/README.md:166-169` documents the regression was found and reverted: *"An earlier raw-numpy attempt at this same speedup was WRONG (silently mispredicted by treating the categorical species feature as numeric) — kept the correct pandas-based batching instead."* Current code (`m3_decision_engine.py:204,215,235`) consistently uses `df["species"].astype("category")` before every `.predict()` call, confirmed by direct code read of all three prediction call sites plus `m2_risk_engine.py:417`.
3. **Translation before/after number validation, wrong order** — **STILL PRESENT** (as a missing-integration variant). `validate_llm_output()` and `translate_text()` are never called in the same function anywhere in `app/` (`grep -rln 'translate_text\|TranslationNotConfigured' app` returns only `app/i18n/router.py` and `app/i18n/translate.py`; `/v1/reason`, `/v1/ask`, `/v1/advisories/multimodal_reason` never import `translate_text`). This means number-validated advisory text, once translated via the separate `POST /v1/translate` endpoint, is **never re-validated** for numeral integrity post-translation — the guardrail only ever covers the English/source text.
4. **No DO sensor handling** — **FIXED / handled honestly.** `app/ml_inference/numeric/m2_risk_engine.py:350-368`: when no DO reading exists, `do_mg_l=None` is passed through explicitly (not defaulted to 0), and the surrounding comment states LightGBM/SHAP treat this as "missing" natively — "no fabricated sensor values." No crash path found; this is a deliberate `NaN`-passthrough, not a `sensor_capability` flag system, but it does not silently zero or crash.
5. **Simulator divergence, twin vs standalone M3 scripts** — **FIXED.** Only one `simulator.py` exists in the entire repo (`ml/serving/m3/sim/simulator.py`; confirmed via `find . -iname 'simulator.py'`). `app/twin/simulator_adapter.py:87-88` imports it directly (`from sim.simulator import PondSimulator, compute_running_fcr`) rather than forking it — same engine, same file, both callers.
6. **Hardcoded adapter path; single-adapter transformers+peft instead of vLLM multi-LoRA** — **STILL PRESENT.** `app/ml_inference/llm/vllm_client.py` is a one-line docstring, no code (`"""vLLM multi-LoRA adapter client. Phase 4."""`). `app/ml_inference/llm/adapters.py` is only a 3-value enum, no routing logic. `app/ml_inference/llm/qlora_inference.py` hardcodes a single adapter path (`self.adapter_path = repo_root / "ml" / "artifacts" / "m2_health" / "m2_health-lora-0.1.0"`) via Unsloth `FastLanguageModel`, with no adapter-selection parameter anywhere in `generate_advisory()`. Confirmed non-functional live (500 on the only route that calls it).
7. **Training/serving symmetry — single shared `payload_to_instruction()`** — **FIXED.** Defined once, `ml/serving/m3/m3_decision_engine.py:143`. Imported identically by serving (`app/ml_inference/numeric/m3_engine.py:80`, `ml/serving/m3/serve_m3.py:36`) and training (`ml/serving/m3/training/rebuild_corpus_full_payload.py:35`, comment: *"single source of truth, see that module's docstring"*).

---

## 7. ML/LLM layer findings

- **M3 LightGBM engine executed live, end-to-end**, no mocking: `get_m3_engine_bundle()` loaded two real `.txt` boosters from `ml/serving/m3/models/`, `decide()` ran real inference on a hand-built `PondSnapshot`, and `payload_to_instruction()` produced real narration text (captured output in transcript; e.g. `overnight_do_forecast_mg_l=2.64`, `running_fcr=0.683`). Not MLflow-registered at load time — `get_m3_engine_bundle()` reads `.txt` files straight off disk via `Settings.m3_engine_dir`, with no MLflow model-registry lookup in the hot path (`app/ml_inference/model_registry_sync.py` exists separately at 33% coverage but is not called from `m3_engine.py`).
- **Number validator executed live** with a crafted hallucinated numeral: payload `{'do_mgl': 4.2, 'temp_c': 28.5, 'ph': 7.1}`, output containing an extra `"0.85 mg/L"` not in the payload → correctly raised `NumberMismatchError` listing `['0.85']`; a matching clean output was correctly accepted. (`app/advisory/number_validator.py`, executed via `/tmp/audit/venv/bin/python3`, captured output in transcript.)
- **Adapters**: only M2 has any real inference code (`qlora_inference.py`, Unsloth-based), and it is not importable in this environment (`torch`/`unsloth` absent from all three dependency manifests: `requirements.txt`, `requirements-dev.txt`, `pyproject.toml` — confirmed by `grep -iE 'torch|transformers|peft|vllm|unsloth'` returning nothing). M1 and M3 have no LLM adapter code at all — M3's "reasoning" is template text (`payload_to_instruction`), not an LLM call. No multi-LoRA serving exists; vLLM is referenced only in `frontend/docker-compose.yml`'s `vllm-engine` service definition and `.env.example`, never actually wired to a Python client that calls it (`app/ml_inference/llm/vllm_client.py` is empty).
- **Hallucination-rate eval**: `training/validate_sft_corpus.py` (referenced in `ml/serving/m3/README.md:151-157`) checks SFT training data for invented numbers before training, and the README documents a real result — 47,638/50,000 examples survived validation (95.3%), with 100% of the 4.7% failures attributed to a specific, named cause (`MISSING_CONFIDENCE_FLAG`). This is a documented training-data QA result, not a live inference-time hallucination rate — no live eval script producing a runtime hallucination rate was found or run in this audit.
- **Post-translation number safety**: confirmed NOT guaranteed — see Known Gap #3 above. No code path validates numerals after translation.

---

## 8. Environment and migration issues

- **`alembic heads`**: single head, `b7c8d9e0f1a2` — no branching detected. Command: `alembic heads` → `b7c8d9e0f1a2 (head)`.
- **`alembic upgrade head`**: **fails**, real captured traceback: `sqlalchemy.exc.DBAPIError: ... asyncpg.exceptions.FeatureNotSupportedError: extension "timescaledb" is not available ... [SQL: CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE]` at `alembic/versions/20260810_1010_a84e6d55c7b4_init_db.py:26`. PostGIS installed successfully via `apt-get install postgresql-16-postgis-3` and its `CREATE EXTENSION` succeeded standalone; TimescaleDB has no apt source configured in this sandbox and the vendor's install script (`packagecloud.io/install/.../script.deb.sh`) was not completed (network/time constraints) — **BLOCKED**, not a repo defect confirmed either way; **the migration was never verified to complete in this audit**, so downstream claims about `logs` hypertable, continuous aggregates, and `features.daily_features_mv` are unverified beyond static code read.
- **Docker**: `docker ps` fails — `failed to connect to the docker API at unix:///var/run/docker.sock`; attempting `dockerd` directly fails with `ulimit: error setting limit (Operation not permitted)`. **BLOCKED** — no container runtime available in this sandbox at all.
- **`.env.example` vs code**: `app/config.py` requires (`Field(...)`, no default) `app_secret_key` and `internal_api_token`, both present in `.env.example` as `CHANGE_ME` placeholders — consistent. No env var referenced via `os.environ`/`settings.` in `app/` was found undefined in `.env.example` (spot-checked `BHASHINI_*`, `VLLM_*`, `M3_ENGINE_DIR`, `FCM_SERVICE_ACCOUNT_PATH` — all present).
- **`pytest --cov` gate**: repo's own `pyproject.toml` sets `fail-under=70`; actual run produced **51.79%**, and the tool itself reported `FAIL Required test coverage of 70.0% not reached`.
- **Two divergent `docker-compose.yml` files** (see §1) — a real, unresolved fork in infra config, not just a naming inconsistency: different DB user/password/dbname pairs (`aquaverse`/`aquaverse`/`aquaverse` vs `aquaverse`/`aquapass123`/`aquaversedb`), different service sets.

---

## 9. Prioritised fix list

**P0 — blocks testing**
- Get TimescaleDB installed/reachable in a real dev/CI environment (or document the exact vendor repo + version pin) so `alembic upgrade head` can be verified end-to-end. *(Owning module: `app/db` / infra)*
- Reconcile the two `docker-compose.yml` files into one canonical definition — current state means "spin up the stack" is ambiguous and neither file may reflect production. *(Owning module: infra)*
- Pin and install `torch`/`peft`/`unsloth` (or drop the Unsloth path for real vLLM) so `app/ml_inference/llm/qlora_inference.py` is importable at all — currently every code path that touches it 500s. *(Owning module: `app/ml_inference`)*

**P1 — blocks pilot**
- Implement `POST /v1/reason`'s real LLM call, regeneration loop, and 503 structured-fallback-on-final-failure — current behavior is a single-shot stub that 500s on any mismatch with no retry. *(Owning module: `app/advisory`)*
- Add auth (`CurrentUser`/`CurrentStaff`/`InternalOnly`) to `POST /v1/advisories/multimodal_reason` — currently reachable with zero authentication. *(Owning module: `app/advisory`)*
- Fix the frontend's `/v1/media/presign` / `/v1/media/commit` orphan calls to match the real `/v1/media/upload-url` / `/v1/media/{media_id}/commit` routes. *(Owning module: `frontend`)*
- Either gate `recommended_feed_kg`/`feed_pct_biomass` behind `feed_source` before they reach `AskOut.answer`, or stop citing `manufacturer_table` in the narration until Vishi's real digitized tables land — currently a farmer-facing text string attributes a placeholder number to a named commercial feed table. *(Owning module: `app/ml_inference` / `ml/serving/m3`)*
- Register the missing ARQ jobs (nightly retrain, forecast generation, advisory batch send) — only report-export exists today. *(Owning module: `app/worker` / `app/reporting`)*
- Decide and build (or explicitly descope) the Flutter farmer app — it does not exist in this repo at all. *(Owning module: none — new)*

**P2 — quality**
- Re-validate numerals after translation (`POST /v1/translate`) or document that the guardrail is source-language-only. *(Owning module: `app/i18n` / `app/advisory`)*
- Raise statement coverage toward the repo's own 70% gate, prioritizing `app/ml_inference/router.py` (17%), `app/ingest/router.py` (22%), `app/alerts/router.py` (22%), `app/twin/router.py` (32%). *(Owning module: all named)*
- Update `frontend/src/api/client.ts`'s stale "16 backend endpoints" comment and either consolidate all pages onto it or document the raw-`fetch()` pattern as intentional. *(Owning module: `frontend`)*
- Add a Delivery/read-receipt callback route and a realtime SSE endpoint, or explicitly descope them — reference architecture implies both, neither exists. *(Owning module: `app/alerts` / `app/main`)*

---

## 10. Could not verify (BLOCKED)

| Item | What's needed to unblock |
|---|---|
| Full `alembic upgrade head` (hypertable/continuous-aggregate creation, `features.daily_features_mv`) | A Postgres instance with the TimescaleDB extension actually installed (vendor apt repo `packagecloud.io/timescale/timescaledb` reachable and configured), or a container runtime + the project's own `timescale/timescaledb-ha:pg16` image |
| All 102 `testcontainers`-gated integration tests (`tests/integration/*`) | A working Docker daemon — this sandbox cannot start `dockerd` (`ulimit: error setting limit (Operation not permitted)`) |
| Keycloak-issued JWT flow, `/v1/auth/token` end-to-end, RBAC payload-level testing beyond the 401-without-token check | A running Keycloak instance at the configured realm/client, per `.env.example`'s `KEYCLOAK_*` vars |
| Real Bhashini `/v1/translate` call against the live API | Outbound network access — the sandbox's proxy returned `403 Forbidden` on the real Bhashini endpoint (`httpx.ProxyError: 403 Forbidden` from `app/i18n/translate.py:84`) |
| MinIO-backed media upload/commit flow | A running MinIO (or S3-compatible) instance — requires Docker or a separate object-storage service |
| vLLM multi-LoRA serving, GPU-backed adapter inference (M1/M2/M3) | A GPU host, `torch`/`peft`/`unsloth`/`vllm` installed, and either a running vLLM server or the Unsloth adapter files actually present under `ml/artifacts/m2_health/m2_health-lora-0.1.0` (existence not confirmed in this audit) |
| ARQ worker actually running/enqueuing/executing jobs live | A running Redis (started successfully in this audit) **plus** a running `arq app.worker.WorkerSettings` process, which was not started — only static code review of `app/worker.py` was performed |
| Weather ingest against real Open-Meteo API | No client code exists to test at all (see §4 — MISSING, not BLOCKED, but confirming its total absence required checking network-dependent behavior was not simply hidden behind an untested code path) |
