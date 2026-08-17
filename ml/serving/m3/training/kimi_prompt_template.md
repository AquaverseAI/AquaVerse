# Kimi Generation Spec — M3 SFT Corpus (Phase 4)

## What Kimi's job is, precisely

You are given a JSON payload — the output of an already-tested, already-correct
pond decision engine. Every number in it is real (either a trained model's
prediction, or a deterministic calculation from one). **Your only job is to
write natural-sounding advisory prose that reports these numbers accurately.**
You are NOT deciding the feed amount, NOT deciding whether to hold feed, NOT
projecting the harvest date — all of that is already decided. You are the
narration layer, not the reasoning layer, even though the output should
read as if it reasons.

## Hard rules — violating any of these makes the example unusable

1. **Every number in your output must appear in the input payload.** Do not
   invent, round differently in a way that changes the value, or compute a
   new number not present in the payload (e.g. don't calculate "that's
   Rs.X profit over the whole harvest" unless total harvest weight × margin
   is itself something you're literally just multiplying two given numbers
   and stating clearly as a derived total — if you do this, show the
   arithmetic doesn't introduce a new unverifiable figure).
2. **If `feed_hold_recommended` is true, you MUST cite the reason** given in
   `feed_hold_reason` — don't just say "hold feed today," explain why,
   using the DO forecast number and threshold logic already given.
3. **Always name the `manufacturer_table`** when discussing feed quantity —
   never say "based on standard feeding practice," name the actual table.
4. **If `do_forecast_confidence` is "low_data"**, mention that the forecast
   confidence is reduced — don't hide data-quality problems from the reader.
5. **Never state a disease or health diagnosis.** This payload is
   production/feed only. If `warnings` mentions anything about mortality
   risk or health, phrase it as "worth flagging to your health monitoring"
   — never "this pond has X disease."
6. **Vary register and length across examples.** Don't produce the same
   sentence structure 50,000 times — that teaches the model to recognize a
   template, not to reason. Vary: sentence order, which fact leads,
   formality level (still farmer-readable, but some terser, some more
   explanatory), whether the harvest projection is mentioned prominently or
   as an aside.
7. **If `projected_harvest_date_days_out` is null**, say so honestly —
   something like "harvest timing can't be projected reliably from today's
   conditions" — don't invent a date.

## Output schema (per example)

Produce a JSON object with exactly two fields:

```json
{"instruction": "<restate the payload as a natural pond-state question, as if a farmer or the app is asking 'what should I do today'>",
 "output": "<your reasoning, then the final advisory — see below>"}
```

`output` should read as: 2-4 sentences of reasoning (why this recommendation,
grounded in the specific numbers), then a short, clear final action
statement a farmer could act on in 10 seconds. This matches the two-field
Alpaca-style schema already validated working in Unsloth Studio.

## Example (for Kimi's few-shot context, not for training)

Input payload (abbreviated):
```json
{"pond_id": "SFT-000042", "species": "GIFT Tilapia (Oreochromis niloticus)",
 "doc": 58, "overnight_do_forecast_mg_l": 2.2, "feed_hold_recommended": true,
 "feed_hold_reason": "Overnight DO forecast 2.20 mg/L is below the GIFT Tilapia stress threshold (3.0 mg/L). Compensatory-growth trials support a short feed hold without measurable final-harvest-weight loss, provided feeding resumes once DO recovers.",
 "manufacturer_table": "Avanti Tilapia Grow-Out Table v2", "running_fcr": 1.62}
```

Good output:
```json
{"instruction": "Pond SFT-000042, GIFT Tilapia, day 58 of culture. Overnight oxygen is forecast at 2.2 mg/L. What should today's feeding be?",
 "output": "Tonight's oxygen forecast of 2.2 mg/L falls below the safe threshold for tilapia (3.0 mg/L), and feeding into a low-oxygen night adds unnecessary metabolic and ammonia load right when the pond can least handle it. Research on feed holds during oxygen stress shows no measurable cost to final harvest weight, as long as feeding resumes promptly once conditions recover. Skip today's feeding entirely and resume once the overnight DO forecast is back above 3.0 mg/L."}
```

## Batching guidance

Send payloads in batches of 20-50 per API call (balance context budget against
throughput). Ask Kimi to return a JSON array of the two-field objects, one per
input payload, in the same order. Validate the count matches before saving —
a dropped example silently shifts alignment for everything after it.

## After generation: validate before touching Unsloth

Run `validate_sft_corpus.py` against whatever Kimi returns. It checks rule 1
(no invented numbers) programmatically — this is the one rule an LLM
reviewing its own output can't reliably self-police, so it needs an
independent check, not a trust-the-model step.
