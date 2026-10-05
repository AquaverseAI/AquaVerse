# AGENTS

1. **Three-layer storage contract:**
   - Drift (SQLite) → structured data only (ponds, logs, alerts, outbox)
   - `flutter_secure_storage` → tokens/secrets only
   - `shared_preferences` → simple launch-gating flags only (`has_onboarded`, nothing else without explicit review noted in a comment)

2. **Routing decision table** (splash logic — do not let this drift):

   | `has_onboarded` | Valid/refreshable token? | Route to |
   |---|---|---|
   | false | — | Full Onboarding |
   | true | yes | Today (Home) |
   | true | no | Re-login (OTP only, no language/role pickers) |

3. **Rule-numbering discipline:** R1–R9 refer only to the nine numbered rules in PRD-AV-04 §7, verbatim. Do not attach an R-number to any other constraint (app size, TTS, persistence choices, etc.) unless directly citing that section. If unsure which rule (if any) applies, state the constraint without a number rather than guessing one.

4. **Locked tech stack + explicit exclusions** (Hive, Bloc/Provider/GetX, SSL pinning, root detection, Play Integrity/App Attest, Redis, Celery — none of these belong in this client-side Flutter app).

5. **Zero-capex, 12-week MVP framing** — before adding any new dependency or architecture layer, check whether it's actually required by PRD-AV-04 §5–§6, or whether it's speculative "enterprise-grade" scope creep.
