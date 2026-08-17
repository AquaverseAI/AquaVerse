# AquaVerse Backend — Prioritized Fix List

Derived from the endpoint audit on 2026-08-17 (36 routes checked against the frontend at
`Documents/Aquaverse demo`). Summary of that audit: 27 of 36 endpoints are hardcoded stubs,
the frontend makes zero API calls, auth is enforced on 3 of 36 routes, pagination is fake
everywhere, and the real "M3" quantitative engine lives unused in a sibling sandbox
(`m3_eval/aquaverse-sim/m3_decision_engine.py`) while the backend calls a hardcoded mock.

Priority order = what blocks the most downstream work, not what's most visible. Items within
a tier are also roughly ordered.

---

## P0 — Critical (blocks everything else)

### P0.1 — No auth/RBAC enforced on 33 of 36 endpoints
**Wrong:** Only `POST /v1/logs`, `GET /v1/auth/me`, and `POST /v1/reason` (internal token) check
identity. Endpoints explicitly documented as staff/admin-only — `GET /v1/risk/worklist`,
`POST /v1/advisories/broadcast` — have no dependency injected at all. `app/core/rbac.py` and
the `CurrentStaff`/`CurrentFarmer`/`require_district_claim` helpers in `app/deps.py` are fully
written and correct, just never attached to a route.
**Why it matters:** Any real data wired in behind these routes (ponds, alerts, advisories) is
immediately exposed with no ownership or district scoping. Every other item on this list
("implement the stub with real DB data") is unsafe to do until this is in place — you'd be
building real endpoints with no access control the same day.
**Fix:** Add `user: CurrentUser` (or `CurrentStaff`/`CurrentFarmer`) to every route per the
role implied by its docstring; call `require_role`/`require_district`/`require_pond_scope`
from `core/rbac.py` where farmer-vs-staff-vs-admin or district scoping applies. No new code
needed — just wiring the existing module in.

### P0.2 — Pagination is fake on every list endpoint
**Wrong:** `CursorPage[...]` is the declared response shape everywhere, but every stub
hardcodes `next_cursor=None`, and the one DB-backed list (`GET /v1/logs`) accepts a `cursor`
query param and silently ignores it, using a bare `LIMIT` instead.
**Why it matters:** Pagination is baked into the response *contract* (`CursorPage[T]`), which
every future real implementation and the frontend will both code against. Fixing the cursor
semantics after real data and a frontend already depend on the fake contract means a breaking
change everywhere at once. This is cheapest to fix before anything else consumes it.
**Fix:** Implement real keyset pagination in `core/pagination.py` (encode `(sort_key, id)` as
the cursor, typically base64), apply it in `GET /v1/logs` first since it's already DB-backed,
then use the same helper in every endpoint as it's un-stubbed.

### P0.3 — Real M3 quantitative engine not connected; hardcoded network config
**Wrong:** `POST /v1/ask` calls `http://172.17.0.1:8001/v1/reason/m3` — a hardcoded Docker-host
IP pointing at `mock_m3.py`, a placeholder that returns a canned narration string regardless of
input. The actual trained engine (`m3_eval/aquaverse-sim/m3_decision_engine.py`, LightGBM,
"real and usable today" per its own docstring) exists but was never merged in. Separately,
`app/twin/router.py` hardcodes a link to `http://10.20.18.183:5173/` and `config.py` hardcodes
`cors_origins` to specific LAN addresses — none of this is env-driven.
**Why it matters:** This is the product's core differentiator (numeric-grounded LLM
explanations) and it's currently faking its own core input. It also blocks `GET
/v1/ponds/{id}/risk` and `GET /v1/ponds/{id}/forecast/do` from ever being real, since those are
supposed to be produced by the same quantitative layer. The hardcoded IPs mean none of this
works outside the one dev machine it was built on.
**Fix:** (1) Move `m3_decision_engine.py` (and its trained model artifacts) into
`app/ml_inference/numeric/`, replacing the unused `loader.py`/`predict.py` stubs. (2) Replace
the `httpx` call in `advisory/router.py` with a direct in-process call (it's pure Python +
LightGBM inference per its own docs, no need for a network hop) or, if it must stay a service,
put its URL behind `Settings.m3_engine_url` in `config.py`. (3) Move `10.20.18.183:5173` and
`cors_origins` into env vars / `.env.example`. (4) Delete or clearly quarantine `mock_m3.py`
(rename to `tests/fixtures/mock_m3.py` — it's useful for local dev, just shouldn't look like
part of the app).

---

## P1 — High (core product value; needs P0 done first)

### P1.1 — Frontend has zero integration with the backend
**Wrong:** `Documents/Aquaverse demo` is a static marketing page — no `fetch`/`axios`, no
`VITE_API_*` env var, no HTTP client dependency at all. Every metric shown ("+34% Growth
Rate", "99.8% Mortality Shield") is a hardcoded string in `DemoModal.jsx`.
**Why it matters:** This is the most visible gap in the whole system — there is currently no
way for a user to see real backend data. It's P1 rather than P0 because it depends on P0.1
(auth) being in place before it's safe to point a real UI at real user data, and it depends on
P0.2 (pagination) so the UI isn't built against a contract that changes later.
**Fix:** Stand up a minimal authenticated flow first — OTP login (`/v1/auth/otp/*`) → pond list
(`/v1/ponds`) → pond detail with risk/timeseries — as a new app or a new route tree in the
existing Vite project, using the already-published `openapi.yaml` to generate a typed client
(the CI already has an `sdk-gen` workflow — use its output). Treat the current landing page as
the public marketing shell and add an authenticated app behind it, not a rewrite of it.

### P1.2 — Ponds domain is entirely stub (`GET /v1/ponds`, `/{id}`, `/{id}/timeseries`, `/{id}/events`)
**Wrong:** All four return the same single hardcoded "Kalaiselvi Pond - Block A" regardless of
the requesting user or `pond_id` in the URL. There's a real `Pond` model in `db/models/pond.py`
that's never queried.
**Why it matters:** Ponds are the root entity everything else hangs off — risk, forecast, twin,
geo, alerts, and logs (which *is* real) all reference `pond_id`. Nothing downstream can be
meaningfully real while pond identity itself is fake, and this is why it's ordered ahead of
risk/forecast below.
**Fix:** Replace stub bodies with real SQLAlchemy queries against `db/models/pond.py`, scoped
by the requesting user's `pond_ids`/district (via P0.1's RBAC), with `timeseries`/`events`
reading from `Log`/an events table using the P0.2 pagination helper.

### P1.3 — Risk scoring is stub (`GET /v1/ponds/{id}/risk`, `GET /v1/risk/worklist`)
**Wrong:** Fixed `risk_score=0.72` and canned SHAP values for any pond.
**Why it matters:** This is the headline ML feature of the product; right now it's decorative.
**Fix:** Once P0.3 lands the real M3/LightGBM engine in-process, call it here with the pond's
actual latest feature snapshot (built from `Log` rows via `app/features/views.py`, which
already exists and is partially wired). Return real SHAP contributions from the model instead
of the hardcoded pair.

### P1.4 — Forecast is stub (`GET /v1/ponds/{id}/forecast/do`)
**Wrong:** Linear-decay fake numbers (`6.0 - i * 0.04`), no TCN/TFT/PatchTST model involved.
**Why it matters:** Advertised as a headline feature ("uncertainty bands, never bare point
estimates") but produces arithmetic, not a forecast.
**Fix:** Lowest priority of the three ML endpoints since no temporal model currently exists
anywhere in the repo (unlike the M3 engine, which at least exists in the sandbox) — this needs
model training first, then a `ml_inference/numeric/forecast.py` module analogous to the risk
path above.

---

## P2 — Medium (remaining stub domains — can proceed in parallel once P0 lands)

### P2.1 — Alerts domain (`GET /v1/alerts`, `POST /{id}/ack`, `POST /{id}/feedback`)
**Wrong:** List returns one hardcoded alert; ack/feedback accept input but don't persist.
`app/alerts/rules.py`, `suppression.py`, and `fanout.py` are fully written and unused.
**Why it matters:** Alerting is the main way this product is supposed to reach farmers
proactively; right now nothing is ever actually raised, suppressed, or acknowledged.
**Fix:** Add an `Alert` DB model (one doesn't currently exist alongside `db/models/alert.py` —
verify/extend it), have `rules.py` evaluate on log ingestion (hook into `POST /v1/logs`),
`suppression.py` gate on sensor-staleness per the README's "blind-state suppression" rule, and
wire ack/feedback to real updates.

### P2.2 — Digital Twin domain (`GET /{id}/state`, `GET /{id}/view`, `POST /{id}/whatif`)
**Wrong:** All three return fixed numbers; `whatif` does simple addition instead of calling
`twin/simulator_adapter.py` (written, unused). Additionally, `get_twin_view`'s HTML template has
a literal bug — `<title>...{{ state.pond_id }}</title>` renders the literal text `{ state.pond_id
}` instead of interpolating, because the f-string escapes the braces incorrectly.
**Why it matters:** Functionally decorative today; the template bug is a quick, independent fix
worth doing regardless of when the rest of this domain gets real data.
**Fix:** Fix the f-string brace bug immediately (cheap, no dependencies). Wire `state`/`whatif`
to `simulator_adapter.py` and real sensor data once P1.2 (ponds) and P1.3 (risk, for
`risk_delta`) are real. Move the hardcoded `10.20.18.183:5173` visualizer link to config (see
P0.3).

### P2.3 — Geo domain (`GET /v1/geo/ponds`, `GET /v1/geo/clusters`)
**Wrong:** Both return one fixed GeoJSON fixture near Nagapattinam; `geo/clustering.py`
(space-time scan statistic) is written and unused; no PostGIS query is ever issued despite it
being provisioned in the stack.
**Why it matters:** Outbreak clustering is called out in the README as a differentiator
("space-time scan statistic... <200ms"); currently there's no spatial query at all.
**Fix:** `geo_ponds` first (straightforward `ST_DWithin`/`ST_AsGeoJSON` query once P1.2 ponds
are real), `geo_clusters` second since it depends on `clustering.py` being connected to real
alert/risk history.

### P2.4 — Advisories domain (`GET /v1/advisories`, `POST /advisories/broadcast`)
**Wrong:** List returns a fixed advisory; broadcast accepts and echoes input without persisting
or fanning out to anyone.
**Why it matters:** "Broadcast" implies farmers actually receive something; today it's a no-op
that returns 201 and does nothing.
**Fix:** Add persistence (advisory table), and connect broadcast to whatever fan-out channel is
intended (SMS/push/in-app) — check `alerts/fanout.py`, which may be reusable here.

### P2.5 — Media upload/commit (`POST /v1/media/upload-url`, `POST /v1/media/{id}/commit`)
**Wrong:** Returns a fake presigned URL string (`?X-Amz-Signature=stub`) and a fixture on
commit; nothing is verified against actual object storage.
**Why it matters:** Lower urgency than the domains above — no other endpoint depends on media
yet — but it's a real security gap-in-waiting: a fake "commit" that always returns
`status=committed` with no verification, if wired to anything downstream later, would trust
uploads that never happened.
**Fix:** Generate real presigned PUT URLs against MinIO/R2 (already provisioned in
`infra/docker-compose.yml`); on commit, HEAD the object to confirm it exists before marking
`committed`.

### P2.6 — Idempotency helper unused
**Wrong:** `app/core/idempotency.py` (Redis-backed, TTL'd replay cache) is fully written but
`POST /v1/logs` reimplements idempotency inline via a DB lookup on `client_log_id` instead of
using it.
**Why it matters:** Not broken today, but the README promises idempotency "everywhere," and the
DB-lookup approach won't extend cleanly to non-DB-backed write endpoints (e.g., once P2.1's
alert ack, or P2.4's broadcast, need the same guarantee).
**Fix:** Either standardize all write endpoints on `core/idempotency.py`'s Redis pattern, or
explicitly document the DB-lookup pattern as the standard and delete the Redis module — pick
one so it's not two half-used approaches.

### P2.7 — Model registry & drift (`GET /v1/models`, `GET /v1/models/metrics`, `GET /v1/models/drift`)
**Wrong:** `list_models` and `drift` are fixed fixtures; `metrics` is the one honest partial —
`rejected_attempts` is real, everything else (`total_requests`, latency percentiles, cache hit
rate) is hardcoded `0.0`.
**Why it matters:** Once P0.3/P1.3 land a real model, this becomes the operational dashboard for
whether the number-validator guardrail is actually working in production — the README states
`rejected_attempts` "must read 0 in steady state," which is only meaningful once real traffic
flows through `/v1/reason`.
**Fix:** Back `list_models` with the real model registry table (`db/models/model_registry.py`
exists, unused); populate `metrics`'s remaining fields from the Prometheus counters already
being recorded in `main.py`'s middleware instead of hardcoding them.

---

## P3 — Low (secondary features, hygiene, coverage)

### P3.1 — Translation is a literal stub (`POST /v1/translate`)
**Wrong:** Returns `f"[STUB TRANSLATION to {target_lang}] {text}"`. `i18n/translate.py`,
`tts.py`, and `cache.py` are all written and unused.
**Why it matters:** Needed for farmer-facing multilingual use, but nothing else in the system
depends on it, so it can wait.
**Fix:** Wire `translate.py` to Bhashini/IndicTrans2 per the README, with `cache.py`'s Redis
caching in front of it.

### P3.2 — Reporting export is a stub (`GET /v1/reports/export`)
**Wrong:** Returns a fake `job_id` and `status: queued` that never progresses; `reporting/pdf.py`
and `xlsx.py` are unused.
**Why it matters:** Nice-to-have export feature, no other endpoint depends on it.
**Fix:** Wire to the ARQ job queue already provisioned (Redis is in the stack) with `pdf.py`/
`xlsx.py` as the worker implementation; add an SSE or polling endpoint for job status as the
docstring describes.

### P3.3 — Data quality is a stub (`GET /v1/data-quality`)
**Wrong:** Fixed numbers for `total_logs_last_7d`, `missing_parameter_rates`, etc.
**Why it matters:** Useful operational signal, but low urgency — depends on P1.2/P2.1 being
real first for the numbers to mean anything.
**Fix:** Compute from real `Log` rows once ponds/logs are fully wired.

### P3.4 — Test coverage doesn't reach any of the business endpoints
**Wrong:** `tests/` only covers health, pagination helpers, the number-validator unit logic,
feature views, and the OpenAPI contract shape — none of the 36 routes have an integration test
asserting real behavior (unsurprising, since most return static fixtures today).
**Why it matters:** As each item above moves from stub to real, there's currently nothing to
catch a regression.
**Fix:** Add an integration test alongside each item as it's un-stubbed, not as a separate pass
at the end — cheapest to write while the real logic is fresh, and it prevents a P1/P2 fix from
silently reverting to fixture behavior later.

### P3.5 — No way to tell stub vs. real from the API surface itself
**Wrong:** Only some stub handlers have a `"Phase N: ..."` comment; the OpenAPI
descriptions read identically for real and fake endpoints, so a consumer (or this audit) has to
read source to know which is which.
**Why it matters:** Pure maintainability/legibility issue — becomes actively confusing as some
endpoints flip to real and others don't, mid-migration through this list.
**Fix:** Until an endpoint is real, prefix its OpenAPI `summary` with `[STUB]` (cheap, visible in
`/docs`, and easy to grep for and remove as items in this list are closed out).

---

## Suggested execution order

1. **P0.1 → P0.2 → P0.3** (auth, pagination, real M3 + config) — do these first and roughly in
   this order; each is foundational infrastructure the rest of the list assumes exists.
2. **P1.2 (ponds) → P1.3 (risk) → P1.1 (frontend, can start once ponds/auth work) → P1.4
   (forecast)** — ponds unblocks risk, twin, geo, and alerts; frontend work can begin against
   ponds + auth without waiting for the rest of P1/P2.
3. **P2 items** can proceed in parallel across owners once P0 and P1.2 are done — they don't
   block each other.
4. **P3 items** are cleanup/polish — fold P3.4 (tests) into each P1/P2 item as it lands rather
   than doing it as a separate pass; do P3.5 (`[STUB]` markers) immediately since it's nearly
   free and makes the state of everything else in this list visible in `/docs` the whole time.
