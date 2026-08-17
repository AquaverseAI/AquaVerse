# AquaVerse AI — Simulator, Feature Store & M1/M3 Baselines

Phase 1-3 of the MVP plan (PRD-AV-05 §8, weeks 1-4), built and validated.
Raw per-cycle hourly data (1.2GB, 2,000 files) is excluded from this package —
regenerate it in ~15 min with the command below. Everything else — code,
training tables, trained models, results — is included.

## What's here

```
sim/                    Pond physics simulator (constants, species, weather, faults, features)
generate_dataset.py     Batch generator: N crop cycles -> data/raw/*.parquet + manifest
build_training_tables.py  Point-in-time snapshot tables for the two numeric baselines
train_baseline.py        LightGBM + SHAP + MLflow, both targets
train_growth_only.py     Same, growth model only, SHAP capped for speed on large corpora
build_m2_table.py        M2 mortality-risk snapshot table (environmental-stress signal, NOT disease)
train_m2_baseline.py     M2 classifier: AUC-PR + Brier + operating-point precision/recall
m3_decision_engine.py    M3 decision engine: wraps the trained models into the actual
                          farmer-facing payload (feed qty, feed-hold, harvest projection,
                          FCR, cost/kg). This is what the eventual LLM narrates — build
                          this into aquaverse-backend's ml-inference module. No GPU, no
                          training — pure Python + LightGBM inference, any IDE.
training/
  kaggle_train_m3_qlora.py  Ready-to-paste Kaggle notebook: QLoRA fine-tune of the
                             M3 adapter on Qwen3-8B via Unsloth. Needs the Phase 4
                             SFT corpus (not yet built — needs Vishi's digitized
                             manufacturer feeding tables per PRD §4).
  m3_sft_placeholder.jsonl        40 synthetic examples, 3-field schema (instruction/reasoning/output)
  m3_sft_placeholder_alpaca.jsonl Same, 2-field (instruction/output) — used for the Unsloth Studio
                                   smoke test that validated an RTX 5070 can run this QLoRA config.
                                   NOT real training data — replace before any real fine-tune.
data/
  manifest.parquet         2,000 simulated crop cycles: params, split, outcomes
  do_forecast_table.parquet   284k pond-night snapshots for the DO model
  growth_table.parquet        282k pond-day snapshots for the growth model
  m2_health_table.parquet     268k pond-day snapshots for the mortality-risk model
models/
  do_overnight_min_baseline.txt + results.json + shap_importance.csv + calibration csv
  m3_daily_growth_baseline.txt + results.json + shap_importance.csv + calibration csv
  m2_mortality_risk_baseline.txt + results.json + shap_importance.csv
```

## Reproduce the raw corpus

```bash
pip install numpy pandas pyarrow tqdm lightgbm shap mlflow scikit-learn --break-system-packages
python3 generate_dataset.py --n_cycles 2000 --out data --seed 42   # ~15 min, resumable
python3 build_training_tables.py --data_dir data
python3 train_baseline.py --data_dir data --out_dir models         # DO model + starts growth
python3 train_growth_only.py                                       # growth model (SHAP capped)
```

Resumable: if interrupted, re-run the same `generate_dataset.py` command — it
checkpoints every 50 cycles and skips completed ones by index.

## Scaling to the full 5,000-cycle target

Just raise `--n_cycles 5000`. At the observed throughput (~3/s single-core)
that's ~30 min. Runs fine unattended on Kaggle CPU or any spare machine —
no GPU needed for Phases 1-3, only for Phase 5 (the LoRA fine-tune).

## Current baseline results (2,000-cycle corpus, held-out test ponds)

| Model | MAE | RMSE | R\u00b2 |
|---|---|---|---|
| Overnight DO minimum forecast | 0.083 mg/L | 0.115 | 0.988 |
| Daily weight gain (M3) | 0.246 g/animal | 1.05 | 0.974 |

| M2 classifier (elevated mortality, next 24h) | AUC-PR | AUC-ROC | Brier |
|---|---|---|---|
| Test set | 0.656 | 0.907 | 0.120 |

At the operating point tuned for 80% recall on val: **48% precision on test** —
roughly half of alerts at that sensitivity are false alarms. Read this as a
real signal, not a bug: it's the honest ceiling of what's learnable from
environmental stress alone, in a simulator with no disease/pathogen model.
Top SHAP drivers (`stress_hours_lt3_7d`, `night_do_min`, `biomass_est_kg`,
`salinity_ppt`) match what a fisheries officer already reasons with.

**M2 naming caveat, important:** this baseline predicts "elevated mortality
risk from water-quality stress," NOT disease. The simulator has no WSSV/EHP/
AHPND pathogen model. Real M2 (per PRD) needs the Tier-2 disease datasets
(WSD farmer survey, WSSV spatial susceptibility) integrated — those aren't
wired in yet. Don't present this baseline's numbers as a disease-outbreak
classifier in any report; it isn't one.

## What's NOT done yet

- Full 5,000-cycle corpus (currently 2,000; script supports scaling)
- Phase 4: M3 SFT corpus (~5k reasoning pairs) — blocked on manufacturer
  feeding tables (Vishi's workstream, PRD-AV-05 §4)
- Phase 5: actual QLoRA fine-tune — script is ready in `training/`, needs
  the Phase 4 corpus and a Kaggle T4 session to run
- Phase 6: vLLM multi-LoRA serving + number-hallucination validator
- M1 (water chemistry) baseline — DO forecast model above covers the core
  M1 signal; a dedicated ammonia/nitrite risk model isn't built yet
- M2 disease classifier — the mortality-risk baseline above is a real but
  partial substitute; needs Tier-2 disease data (WSSV/WSD surveys) to become
  an actual disease-risk model
- Unsloth Studio smoke test completed on local RTX 5070 hardware — confirmed
  Qwen3-8B QLoRA runs without OOM at context 2048, batch 2\u00d74. Adapter from
  that run (`m3_production-lora-0.1.0`) was trained on the 40-example
  placeholder set only \u2014 do not use it for anything beyond confirming the
  pipeline works.

## M3 decision engine — known limitations, read before using

- **Feed quantity is a placeholder curve**, not a real manufacturer table.
  Flagged explicitly in every payload's `feed_source` field. Swap
  `estimate_feed_pct_bw()` once Phase 4 data lands — nothing else changes.
- **Feed cost and market price are placeholder constants** (Rs.90/kg feed,
  Rs.350/kg market) passed into `PondSnapshot` — replace with real inputs.
- **Harvest projection holds today's environmental snapshot constant**
  across the whole forward walk. Validated on real corpus data: a
  healthy-looking day-40 catfish pond projected 358 days to harvest
  (typical cycle ~150 days) — directionally usable, but should not be
  shown to farmers as a firm date yet. Needs either a seasonal-average
  trajectory or an actual weather forecast feed to fix properly.
- **Feed-hold logic is real and tested**: fires correctly against actual
  stressed-pond data from the corpus (DO forecast below species threshold
  -> hold, cites compensatory-growth evidence). This part is trustworthy
  today.
- **Still needed: the number-hallucination validator** (R1) that checks
  eventual LLM output against this payload's numbers. Zero data
  dependency, ready to build next.

## Phase 4 — M3 SFT corpus (grounded payloads ready, narration pending)

`generate_m3_payloads.py` samples real (pond, day) snapshots from the 2,000-cycle
corpus, deliberately over-weighting the late-cycle + high-DO-stress bucket
(3x) since that's where the accuracy audit found the growth model struggles
most. Each sample runs through the tested `m3_decision_engine.py` to produce
a fully grounded payload — no invented numbers, everything is a real model
output or deterministic calculation.

**`training/m3_payloads_final_50k.jsonl`** — 50,000 grounded payloads, ready
for narration. Known imbalances (see main convo/report): vannamei
under-represented (~19% vs ~40% each for tilapia/catfish — smaller stressed
pool), feed-hold is majority class (61%) due to the deliberate oversampling.

**Next step — you do this part:** run these payloads through Kimi following
`training/kimi_prompt_template.md` (strict grounding rules, output schema,
batching guidance), producing one JSONL file of `{instruction, output}` pairs
in the same order as the payloads.

**Then, mandatory before touching Unsloth:**
```bash
python3 training/validate_sft_corpus.py \
    --payloads training/m3_payloads_final_50k.jsonl \
    --narrated <your_kimi_output.jsonl> \
    --out training/m3_sft_validated.jsonl
```
This checks every example for invented numbers, missing manufacturer-table
citations, missing feed-hold reasoning, and scope violations (disease
diagnosis language, which is M2's job not M3's) — programmatically, not by
trusting Kimi to have followed the rules. If >5% of examples show suspected
number hallucination, it warns you to fix the prompt and regenerate rather
than train on bad data. Only `m3_sft_validated.jsonl`'s output goes into
Unsloth — never the raw Kimi output directly.

## Decision engine performance note (relevant if you extend generate_m3_payloads.py)

The harvest-projection walk was rewritten from per-day sequential model
calls (2s/payload, ~11.5hr for 50k) to a batched grid + interpolation
approach (0.018s/payload, ~12min for 50k) — see `_growth_curve_grid()` in
`m3_decision_engine.py`. Verified interpolation error is exactly 0 against
sequential ground truth at 20+ test weights. An earlier raw-numpy attempt at
this same speedup was WRONG (silently mispredicted by treating the
categorical species feature as numeric) — kept the correct pandas-based
batching instead. If you modify this code, re-run the correctness check in
that function's docstring before trusting any speedup.

## Phase 4 — COMPLETE: m3_sft_final_corpus.jsonl (47,638 examples)

All 50,000 grounded payloads processed through Kimi in 10 batches of 4,776,
validated with `training/validate_sft_corpus.py` after every batch.

**Results:** 47,638 / 50,000 survived validation (95.3%). Every exclusion was
a `MISSING_CONFIDENCE_FLAG` case (low-data-health payloads where Kimi's
narration didn't mention reduced forecast confidence) — evenly distributed
across species and feed-hold classes, not concentrated in one bucket.
Zero confirmed number-hallucinations in the final corpus.

**One validator bug found and fixed mid-run:** batch 8 initially flagged
368/4,776 examples (7.7%) as hallucinated. Manual audit found all 368 were
legitimate arithmetic — Kimi correctly computing "X mg/L below threshold"
from two real payload numbers (DO forecast, species stress threshold), which
the original pure-membership check couldn't recognize as valid. Fixed by
adding `explainable_by_arithmetic()` — checks sums/differences/ratios of any
two payload numbers before flagging. Re-ran all 10 batches after the fix;
batches 1-7, 9, 10 were unaffected (only batch 8 used that phrasing
pattern). This is now a permanent, general improvement to the validator.

**Corpus stats:** output length 33-167 words (mean 78, median 76) — real
variation, not template repetition. Species/feed-hold proportions match the
original payload generation design (tilapia ~41%, catfish ~40%, vannamei
~19%; feed-hold ~61% due to the deliberate late-cycle/stress oversampling).

**Next: real Unsloth training run**, different from the earlier 30-step
smoke test:
- Upload `m3_sft_final_corpus.jsonl` (not the placeholder file)
- Switch to epoch-based training (3 epochs per PRD spec, not Max Steps)
- Set an actual eval split this time (5-10%) — skipped for the smoke test,
  shouldn't be skipped for a real run
- Project name: `m3_production-lora-0.2.0`
- After training: spot-check the fine-tuned model's own outputs for number
  hallucination (different check from the one above — that validated
  training DATA, this validates the trained MODEL's behavior on fresh
  payloads it never saw), then the PRD's 200-item human eval before calling
  the adapter done.

## Phase 5 finding: root cause of hallucination, and the v2 corpus fix

The first full-scale trained adapter (`m3_production-lora-0.2.0`) showed a
real, serious problem in batch evaluation: ~45% of outputs stated a feed
quantity or harvest projection that didn't match the real payload -- in one
case a feed amount 12x too high. Generation-hyperparameter tuning (grid
search over max_new_tokens/repetition_penalty/temperature) reduced
rambling and self-contradiction substantially, but did NOT fix the core
number-fidelity problem, because it isn't a decoding problem.

**Root cause, confirmed by inspecting the actual training data:** the
original corpus's `instruction` field was a compressed natural-language
question ("Pond X, species Y, day Z. DO forecast N. What should feeding
be?") containing only 3-4 data points. The paired `output` (from Kimi)
correctly cited feed_kg, table name, harvest projection, and cost figures
-- because Kimi was given the FULL structured payload during generation.
But the model only ever saw the compressed question as input during
training. It was never taught to copy numbers from its input, because the
numbers it needed to report weren't IN its input. It learned to
confabulate plausible-looking numbers conditioned on species/day/DO
instead of reciting real ones.

**Fix:** `rebuild_corpus_full_payload.py` rejoins the SAME (already-correct)
Kimi outputs with a new instruction containing the FULL payload -- every
number the output is expected to cite is now present in the input. No new
Kimi calls needed. Produced `m3_sft_final_corpus_v2.jsonl` (47,638
examples, same content, fixed grounding) and `eval_set_200_v2.jsonl` (same
held-out ponds, reformatted).

**IMPORTANT -- if you retrain on this:** the serving-time prompt (in
`m3_decision_engine.py` and wherever this ships to production) MUST build
its prompt the same way `payload_to_instruction()` does here, i.e. give the
model the full payload at inference time too. Training the model to expect
a full-payload input and then serving it a compressed question would
recreate the exact same train/serve mismatch this fix addresses.

**Next step:** retrain as `m3_production-lora-0.3.0` on
`m3_sft_final_corpus_v2.jsonl`, using the grid-search-winning generation
settings (max_new_tokens=100, repetition_penalty=1.2, temperature=0.1)
for evaluation, then re-run the full batch-eval pipeline against
`eval_set_200_v2.jsonl` to get a real, trustworthy accuracy number.

## Phase 6 — Serving layer: serve_m3.py

FastAPI endpoint (`POST /v1/reason/m3`), per the MVP spec's internal API
design. Wraps everything validated tonight into one request/response cycle:

1. `PondSnapshotRequest` (JSON) -> `M3DecisionEngine.decide()` -> structured payload
2. `payload_to_instruction()` -> full-payload prompt (the Phase 5 fix)
3. LLM generates narration using the grid-search-winning config
   (max_new_tokens=90, repetition_penalty=1.1, temperature=0.05 -- confirmed
   98.5%+ clean on the full 200-example held-out eval)
4. **Hard number-hallucination gate before responding** (R1) -- same check
   used in offline eval, not a separate/weaker one. Regenerates up to 2x on
   failure; if still failing, returns HTTP 503 with the structured payload
   alone rather than an unverified narration.

**Real bug caught while wiring this up:** `M3DecisionEngine.decide()` never
actually populated `manufacturer_table` in its output -- that field only
existed because `generate_m3_payloads.py` bolted it on separately after
calling `decide()`. Calling `payload_to_instruction()` directly on a
`decide()` result (the real serving path) crashed with a KeyError. Fixed by
moving `FEED_TABLES` into `m3_decision_engine.py` as the canonical source
and adding `manufacturer_table` as a proper field on `M3Payload`, populated
inside `decide()` itself. Also moved `payload_to_instruction()` itself into
`m3_decision_engine.py` as the single source of truth between training-data
generation and serving -- `training/rebuild_corpus_full_payload.py` now
imports it rather than keeping its own copy, closing the exact
train/serve-mismatch risk this document already warned about.

**Run it:**
```bash
pip install fastapi uvicorn torch transformers peft accelerate bitsandbytes --break-system-packages
uvicorn serve_m3:app --host 0.0.0.0 --port 8001
```
Edit `ADAPTER_PATH` at the top of `serve_m3.py` first if your export path
differs from `/home/techpark-6/Pictures`.

**Test:**
```bash
curl -X POST http://localhost:8001/v1/reason/m3 \
    -H "Content-Type: application/json" \
    -d @example_request.json
```
`example_request.json` is a real vannamei feed-hold scenario (DO 2.74mg/L,
below the 4.0 threshold) -- expect `feed_hold_recommended: true` in the
payload and a narration citing the compensatory-growth evidence.

**Not done yet:** this loads the model directly via transformers+peft --
fine for one adapter and low concurrency, but the MVP spec's real target is
vLLM with `--enable-lora`, serving M1/M2/M3 off one loaded base model,
hot-swapped per request. Migrate once M1/M2 adapters exist; only
`generate_narration()`'s internals change, everything else (decision
engine, prompt format, hallucination gate) carries over unchanged.
