# Google Stitch Prompt — AquaVerse AI: Full Exhaustive UI Spec (Every Screen, Every Element, Themed Loaders)

> Canonical master UI spec. Source for Google Stitch frame generation and later Antigravity/Flutter implementation prompts.
> Saved: 2026-08-14. Batch strategy + drift flags in `### Implementation notes` at the end.

## Persona / role framing (include at top of the Stitch prompt)

Act as a senior full-stack product developer and UI designer, fluent across the
**MANGOS** stack (MongoDB, App-layer/Angular-style architecture thinking, Node.js,
GraphQL/Go services, Swift/Flutter-grade mobile front ends), specializing in
production-grade mobile UI for low-connectivity, low-literacy field environments. You
design every pixel with a functional reason behind it — nothing decorative without
purpose — while making the interface feel premium, dimensional, and alive through
subtle animated 3D micro-interactions and aquaculture-themed motion design. You are
designing the complete, final, implementation-ready UI for a government-aligned
agri-tech app used by real shrimp and fish farmers in coastal Tamil Nadu.

---

## Global rules that apply to every single screen below

- Status bar: 9:41, full signal, full wifi, full battery, consistent across all frames.
- Bottom navigation bar (on all Section 2 + Section 3 farmer screens): 5 icons —
  **Today (home icon) / Log (clipboard-plus icon) / Ask (mic icon, center, slightly
  raised/larger) / Alerts (bell icon) / Crop (calendar-growth icon)** — active tab in
  `seaGreen`, inactive tabs in muted `midBlue`/grey, with the active tab's icon showing
  a subtle glow/lift.
- Top app bar pattern (inner screens): left-aligned back chevron (`deepNavy`), centered
  or left-aligned screen title in bold, right-aligned contextual icon (notification bell,
  overflow menu, or edit icon) where relevant.
- Every primary action button: full-width minus 16dp horizontal margin, 52–56dp height,
  fully rounded (pill) or 16dp corner radius, filled `seaGreen → brightMint` gradient,
  white bold label, subtle top-edge highlight + soft drop shadow (the "3D bevel" look).
- Every secondary button: outlined, `midBlue` 1.5px border, `midBlue` text, transparent
  fill, same corner radius as primary.
- Every card: white or `paleSky`-tinted background, 16dp corner radius, soft layered
  drop shadow (ambient + directional), 16dp internal padding.
- Every icon: 24px, consistent line weight (2px stroke), paired with a text label for
  any action that isn't purely navigational.
- Tamil text rendered wherever farmer-facing (not officer/admin-facing) content appears,
  using a Tamil-safe font (Noto Sans Tamil or equivalent), no glyph breakage.

---

## SECTION 1 — ONBOARDING & AUTH FLOW (5 screens)

### 1.1 Splash
- Full-bleed static background: dawn-lit coastal pond, teal/navy/amber gradient light.
- Centered, upper-third: glass-style 3D fish logo (leaping pose, teal-to-navy gradient,
  specular highlight, soft drop shadow) inside a rounded-square backdrop card.
- Directly below logo: "AquaVerse AI" — bold, 28sp, white or deepNavy depending on
  contrast against background at that point.
- Directly below app name: tagline "Better decisions, better harvest" — 14sp, medium
  weight, localized Tamil default.
- Bottom, safe-area padded: one primary button — **"Get Started"** — full width, gradient
  fill, white bold label, right-facing arrow icon inside the button on the trailing edge.
- No secondary buttons, no links, no skip option on this screen.

### 1.2 Language Selection
- Top: back chevron (top-left) — disabled/hidden on this first onboarding step since
  Splash has no back target; show only if reachable from elsewhere.
- Heading: "Select Language" bold 22sp, subheading "Choose your preferred language to
  continue" 14sp grey.
- Vertically stacked list of 4 selectable language cards, each full-width, rounded,
  bordered: **தமிழ் (Tamil)** — pre-selected, `seaGreen` border + checkmark icon on the
  right; **English**; **हिंदी (Hindi)**; **తెలుగు (Telugu)** — each unselected card has a
  neutral grey border, tapping switches the selected state.
- Bottom: primary button **"Next"** — disabled/greyed until a language is selected
  (though Tamil is pre-selected by default so it's enabled immediately).

### 1.3 Enter Mobile Number
- Top-left: back chevron, returns to Language Selection.
- Heading: "Enter your mobile number" bold 22sp, subheading "We'll send you an OTP to
  verify your number" 14sp grey.
- Input row: a non-editable country-code chip **"+91"** with small dropdown chevron
  (locked to India for MVP, chevron present for future-proofing but non-functional) +
  a text field for the 10-digit number, placeholder "98765 43210".
- Trust microcopy directly below the input, small lock icon + text: **"We never share
  your number"**.
- Bottom: primary button **"Send OTP"** — disabled until 10 valid digits entered.

### 1.4 Verify OTP
- Top-left: back chevron, returns to Mobile Number entry.
- Heading: "Verify OTP" bold 22sp, subheading "Enter the 6-digit OTP sent to +91 98765
  43210" 14sp grey (dynamic number shown).
- 6 individual boxed digit inputs in a horizontal row, center-aligned, auto-advancing
  focus, `seaGreen` border on active box.
- Below the boxes: **"Resend OTP in 00:28"** countdown text, greyed out until timer
  expires, then becomes a tappable `midBlue` **"Resend OTP"** link.
- Bottom: primary button **"Verify & Continue"** — disabled until all 6 digits entered.

### 1.5 Select Your Role
- Top-left: back chevron, returns to OTP screen.
- Heading: "Select Your Role" bold 22sp, subheading "Choose how you want to use
  AquaVerse AI" 14sp grey.
- Two large selectable role cards, stacked vertically, each with an icon-in-circle
  (farmer icon / officer icon), role name bold, one-line description, and a radio/check
  indicator on the right edge:
  - **"Farmer"** — icon: a farmer figure; description: "Manage your ponds and get daily
    guidance"; selected by default with `seaGreen` border + filled checkmark.
  - **"Extension Officer"** — icon: an officer/clipboard figure; description: "Monitor
    multiple ponds and support farmers"; unselected state, grey border, empty radio.
- Bottom: primary button **"Continue"**.

---

## SECTION 2 — MAIN FARMER SCREENS: PRIMARY FLOW (5 screens)

### 2.1 Today (Home)
- Top bar: left — small circular avatar placeholder + **"Vanakkam, [Farmer Name]"**
  greeting text with a small waving-hand emoji; right — notification bell icon with a
  small red unread-count dot.
- Below top bar, small grey text: **"Pond ID: TN-01-001"**.
- Large card: **Pond Status** — a big circular status disc (not a number) filled
  `seaGreen` with a water-drop icon inside, word **"Good"** bold beneath the disc, one
  Tamil sentence describing status beneath that, and a small grey timestamp tag in the
  corner: **"Data as of 4h ago."**
- Section heading: **"Today's Actions"**.
- 1–3 horizontal action cards, each with: a left-side icon-in-circle (feed bowl icon /
  aerator fan icon / water-drop-crossed icon), action title bold ("Feed 18 kg", "Run
  Aerator"), subtext ("Split into 3 times", "11:00 PM – 06:00 AM"), and a small speaker
  icon button on the right edge of each card (tap to hear the card read aloud in Tamil).
- Section: **"Risk Level"** — label "Low Risk" in `seaGreen` pill badge, small sparkline
  trend chart beside it, and a **"Details"** text-link on the right.
- Section: **"Overnight DO Forecast (mg/L)"** — a band-area chart with a shaded red
  "Danger" zone, shaded amber "Caution" zone, and clear "Safe" zone, x-axis showing time
  labels (6 PM, 12 AM, 6 AM, 12 PM), small legend row beneath (colored dot + label for
  Safe/Caution/Danger).
- Bottom navigation bar (as defined in Global Rules), Today tab active.

### 2.2 Log Entry
- Top bar: back chevron (left) — returns to Today; center/left title **"Log Entry"**;
  right — small calendar-date icon showing today's date "07 Aug 2026"; below title, grey
  text **"Pond ID: TN-01-001"**.
- Row: **"Feed Given (kg)"** label, left `−` stepper button, center numeric value **"18"**
  pre-filled, right `+` stepper button.
- Row: **"Mortality (no.)"** label, same stepper pattern, pre-filled **"2"**, plus a
  small **"None"** quick-select chip beside it for zero mortality.
- Row: **"Feed-Tray Check"** label, 3 horizontal tappable option chips: **"Empty"** /
  **"Some"** (selected, filled `seaGreen`) / **"Lots"**.
- Row: **"Water Colour"** label, horizontal row of 5 tappable color swatch circles
  (shades from pale green to deep green/brown), selected swatch shows a check ring.
- Section: **"Optional Readings"** — three small input fields side by side: **pH**
  (value 7.8), **DO (mg/L)** (value 5.2), **Salinity (ppt)** (value 8) — each with a
  small label above and unit suffix shown faintly inside the field.
- Section: **"Add Photos"** — a horizontal row of 3 photo thumbnail slots (showing
  already-added pond photos) plus a dashed-border **"+"** add-photo button as the 4th slot.
- Small info row with a flame/streak icon: **"5-day logging streak 🔥 — More logs mean
  better forecasts."**
- Bottom: primary button **"Save Log"**, and directly beneath it, small centered grey
  text: **"Saved offline — will sync when online."**

### 2.3 Ask (Voice)
- Top bar: back chevron (left), title **"Ask Aqua"** centered/left.
- Center of screen: a large circular microphone button (should be depicted with a
  pulsing/rippling animated ring around it to suggest "listening" state), mic icon
  inside, `seaGreen`/`brightMint` gradient fill.
- Beneath the mic button: **"Listen..."** status text, and smaller grey text **"Tap the
  mic and ask your question."**
- A toggle row above or beside the mic: **"Voice"** / **"Text"** segmented control, Voice
  selected by default; tapping Text reveals a text input field with a send button instead.
- Below that: **"Recent Questions"** section heading, a short scrollable list of
  previously asked questions in Tamil, each row with a small chat-bubble icon and a
  right chevron.
- Below recent questions (or as a result state after asking): **"Photo-based Symptom
  Check"** card — a small pond/animal photo thumbnail, heading **"Consistent with white
  spot"**, body text **"Isolate pond, stop water exchange, confirm with officer"** —
  explicitly non-diagnostic phrasing — and a full-width secondary button **"Call
  Officer"** with a phone icon.
- Bottom navigation bar, Ask tab active (center, raised).

### 2.4 Alerts
- Top bar: back chevron (left), title **"Alerts"** centered/left, right — small filter
  or overflow icon (optional).
- Segmented tab control directly below top bar: **"All"** / **"Critical"** / **"Info"** —
  Critical selected/highlighted in the reference state, shown as pill tabs with the
  active tab filled `deepNavy` and white text.
- Vertically stacked alert cards, each containing:
  - Left: a severity icon-in-circle — red triangle-exclamation for Critical, amber
    triangle for Medium/Warning, blue info-circle for Info.
  - Title bold: e.g. **"Low Oxygen Detected"**.
  - One-clause reason: **"Run aerator immediately"**.
  - Small grey timestamp top-right of the card: **"08:20 AM"**.
  - A full-width or inline secondary button **"Call Officer"** with phone icon, shown
    only on Critical-severity cards.
  - Two small feedback buttons side by side at the bottom of each card: a green
    thumbs-up/check button labeled **"This was right"** and a red thumbs-down/cross
    button labeled **"This was wrong"**.
  - At least one card in the list should additionally show a small grey badge:
    **"Low confidence — limited data."**
- Bottom: text link, centered, **"View All Alerts"** with a right chevron.
- Bottom navigation bar, Alerts tab active.

### 2.5 Crop / Cycle
- Top bar: back chevron (left), title **"Crop / Cycle"**, subtext beneath **"Pond ID:
  TN-01-001"**.
- Vertical timeline, each stage as a row with a left-side icon in a circle (filled
  `seaGreen` with checkmark if completed, filled `midBlue` with a clock/in-progress icon
  if ongoing, grey outline if not yet reached), a vertical connecting line between rows,
  and per-row: stage name bold ("Stocked", "Feed Management", "Medicines", "Growth",
  "Harvest"), and a right-aligned date or status ("05 Jun 2026", "Ongoing", "2 Records",
  "Day 64", "Expected: 10 Sep 2026").
- Below the timeline, a 2x2 stat grid: **"Cumulative Feed"** (1,245 kg), **"FCR
  (Running)"** (1.32), **"Cost per kg"** (₹92), **"Market Price / kg"** (₹165).
- Bottom card, visually distinct (`seaGreen`-tinted background): **"Expected Profit"**
  label, large bold **"₹1,25,000"**, small upward trend sparkline beside it.
- Bottom navigation bar, Crop tab active.

---

## SECTION 3 — CRITICAL SAFETY & RELIABILITY SCREENS (6 screens, non-negotiable)

### 3.1 Blind-State / Suppression (Today variant)
- Same base layout as 2.1 Today, but: the Pond Status disc area is replaced/overlaid
  with a prominent amber-bordered banner card at the top: warning-triangle icon,
  bold heading **"Data unreliable"**, body text **"No log in 3 days. Alerts paused until
  fresh data arrives."**
- "Today's Actions" section shows an empty/muted state: grey text **"No actions
  available. Please add a log to get recommendations."**
- Risk Level section shows **"Unknown"** in a grey pill instead of a colored risk badge.
- Overnight DO Forecast chart area shows a muted/greyed-out placeholder chart with
  overlay text: **"No reliable data to show forecast."**
- Bottom nav unchanged.

### 3.2 SMS / IVR Fallback Settings
- Top bar: back chevron, title **"SMS / Call Alerts"**.
- Toggle row: label **"Receive critical alerts by SMS/Call"**, right-aligned on/off
  switch (shown ON, `seaGreen` fill), subtext beneath **"For non-smartphone / low-network
  users."**
- Card labeled **"Sample SMS Preview"**: a mock SMS bubble styled like a phone message,
  containing Tamil alert text, e.g. "⚠ AquaVerse Alert: Low oxygen at TN-01-001. Run
  aerator now. Reply STOP to opt out."
- Below: a row **"Change mobile number"** with the current number shown and a right
  chevron, and small grey footer text: **"You will receive alerts for critical events
  only."**

### 3.3 Offline Mode
- Centered layout (modal-like or full screen): large cloud-with-slash icon in `midBlue`.
- Bold heading **"You are offline"**, subtext **"Some features are limited."**
- Section **"Queued Logs"**: a list of log entries each showing a date/time and a status
  chip — **"Uploaded"** (green check) or **"Pending"** (amber clock) per row.
- Bottom: secondary button **"View Offline Logs"**.

### 3.4 Sync in Progress
- Centered layout: large upward-arrow-into-cloud icon, animated-implied (arrow appears
  mid-motion).
- Bold heading **"Sync in Progress"**, subtext **"2/3 logs uploaded."**
- A horizontal progress bar beneath, roughly 2/3 filled in `seaGreen`.
- Same queued-logs list pattern as 3.3, showing live per-item status updating from
  Pending → Uploading → Uploaded.
- Bottom: secondary button **"View Sync Details"**.

### 3.5 Low-Confidence Forecast
- Same chart card as seen on Today, but expanded to full screen: title **"Overnight DO
  Forecast (mg/L)"**, chart shown with a visibly wide shaded uncertainty band (not a
  thin confident line), small badge overlay on the chart: **"Low confidence — limited
  data."**
- Beneath chart: legend row (Safe/Caution/Danger dots + labels) same as Today.
- Footer microcopy: **"Add more logs for accurate forecasts."**

### 3.6 Log Saved Successfully
- Centered layout: large green circular checkmark icon (filled, with a subtle bounce/
  scale-in implied).
- Bold heading **"Log Saved Successfully!"**, subtext **"Your data is safe and synced."**
- Bottom: primary button **"Back to Home"**.

---

## SECTION 4 — MORE SCREENS: FARMER (6 screens)

### 4.1 Pond Details
- Top bar: back chevron, title **"Pond Details"**, subtext **"Pond ID: TN-01-001"**,
  right — small edit-pencil icon.
- Segmented tabs: **"Summary"** / **"Charts"** / **"Logs"**, Summary active.
- Metadata list (label-value rows): Pond Name (West Farm Pond), Location (Thanjavur,
  Tamil Nadu), Area (1.20 acre), Depth (1.5 m), Liner Type (HDPE), Water Source
  (Borewell), Stocking Date (28 Mar 2026), Fish Species (Pangasius).
- Section **"Today's Key Indicators"**: 3 small stat chips — pH (7.8), DO (5.2 mg/L),
  Temp (28°C).
- Bottom: primary button **"Edit Pond Details"**.

### 4.2 Notifications
- Top bar: back chevron, title **"Notifications"**, right — small **"Mark all as
  read"** text link.
- Vertically stacked notification rows, each with a left icon (matching type: red
  triangle for DO alert, amber for ammonia risk, cloud-rain for forecast, clock for
  log reminder, gear for system update), bold title, one-line description, and a right
  or below-title grey timestamp (e.g. "2 hours ago", "Yesterday", "2 days ago"). Unread
  items show a small colored dot on the left edge of the row.

### 4.3 Settings
- Top bar: back chevron, title **"Settings"**.
- Section **"General"**: rows — Language (value "Tamil", right chevron), Units (value
  "Metric", right chevron), Notifications (row expands or links out), Alert Preferences.
- Section **"Others"**: rows — Privacy Policy, Terms & Conditions, App Version (value
  "1.0", no chevron, static).
- Each settings row: left label, right either a value + chevron, or just a chevron, or
  a toggle switch where applicable (e.g. Push Notifications row with an on/off switch).

### 4.4 Profile / More
- Top bar: back chevron, title **"Profile / More"**.
- Header card: circular avatar photo, bold name **"Murugan"**, grey subtext phone number
  **"+91 98765 43210"**.
- Menu list, each row with a left icon + label + right chevron: **"My Profile"**, **"My
  Pond Details"**, **"Notification Settings"**, **"Language"** (value "Tamil" shown
  inline), **"Help & Support"**, **"About AquaVerse"**.
- Bottom: full-width outlined button, red/danger-tinted text, **"Logout"** with a
  logout icon.

### 4.5 My Ponds
- Top bar: back chevron, title **"My Ponds"**, right — small **"+"** add-pond icon.
- Vertically stacked pond cards, each with: pond name bold (e.g. "West Farm Pond"),
  pond ID grey subtext, a status pill on the right ("Good" green / "Medium" amber /
  "Poor" red), and small grey "last updated" text ("2h ago", "4h ago", "1d ago").
- Bottom: primary button **"+ Add Pond"**.

### 4.6 Help Center
- Top bar: back chevron, title **"Help Center"**.
- Search bar at top: magnifying-glass icon, placeholder "Search for help...".
- Section **"FAQ"**: list rows, each with a question-mark icon, question text, right
  chevron.
- Section rows: **"Video Guides"** (subtext "Step-by-step videos"), **"User Manual"**
  (subtext "Complete user guide").
- Prominent button, WhatsApp-green filled: **"WhatsApp Support"** with a chat icon.
- Footer text, centered: **"Helpline: 1800-XXX-XXXX"**, subtext "Mon–Sat, 9 AM – 6 PM."

---

## SECTION 5 — EXTENSION OFFICER MODE (3 screens)

### 5.1 Officer Dashboard (Multi-Pond View)
- Top bar: title **"Officer Dashboard"**, right — small overflow/menu icon.
- Search bar: placeholder "Search ponds or farmers...".
- Stat card row (4 small stat cards): **"My Ponds"** (28), **"Active Farmers"** (156),
  **"Visits Today"** (12), **"Pending Reports"** (7) — each with a small icon and bold
  number.
- Section **"Recent Pond Visits"**: a table/list with columns Pond ID, Farmer, Location,
  Status (colored pill), Last Visit (date/time) — several rows shown.
- Bottom: text link **"View All Visits"** with right chevron.

### 5.2 Visit Log Entry
- Top bar: back chevron, title **"Visit Log Entry"**.
- Field: **"Pond"** — dropdown selector showing selected pond name.
- Field: **"Observations"** — multi-line text area, placeholder or filled sample text
  ("Water colour green, DO good. Farmer following feed schedule.").
- Field: **"Suggestions"** — multi-line text area ("Continue aeration. Monitor
  ammonia.").
- Section **"Photos"**: horizontal row of 3 photo thumbnails + a dashed "+" add button.
- Bottom: primary button **"Save Visit Log"**.

### 5.3 Officer Ponds / Farmers List
- Top bar: back chevron, title **"Ponds / Farmers"**.
- Filter row: two dropdown chips — **"All Ponds"** and **"All Status"** — plus a sort
  icon on the right.
- Vertically stacked list rows, each with Pond ID bold, Farmer name grey subtext, and
  a right-aligned status pill (Good/Medium/Poor), tappable to drill into Pond Details.

---

## SECTION 6 — DESIGN SYSTEM REFERENCE PANEL (1 frame)

- **Color Palette** block: 5 labeled swatches (deepNavy #1B4F7A, midBlue #3E7CA6,
  seaGreen #4FAE9E, brightMint #3FCCA6, paleSky #D6EEF2), each shown as a rounded
  square swatch with hex code beneath.
- **Typography** block: Latin + Tamil paired samples at Regular / Medium / SemiBold /
  Bold weights, showing "Aa" and a Tamil sample line at each weight.
- **Icon Set** block: a grid of the core navigation + action icons (Home, Log Entry,
  Ask Aqua, Alerts, Crop/Cycle, Profile, Settings, Offline, Sync), 24px, consistent
  line weight, labeled beneath each.
- **Button Styles** block: Primary (filled gradient, 3D bevel), Secondary (outlined),
  Ghost (text-only) — shown side by side with their raised/3D shadow treatment visible.
- **Card Styles** block: an Info Card example ("Water Quality — Good — All parameters
  normal") and an Alert Card example ("Low Oxygen — Critical — Run aerator
  immediately"), showing the elevation/shadow treatment.
- **App Flow Summary** strip: horizontal row of small icons connected by arrows —
  Splash → Onboarding → Login → Home (Today) → Log Entry → Ask Aqua → Alerts →
  Crop/Cycle.

---

## SECTION 7 — STUNNING AQUACULTURE-THEMED LOADERS (design as a dedicated frame,
## then reference which loader applies to which async state throughout the app)

Design 6 distinct animated loader concepts, each themed around aquaculture/aquatic
motion, described in enough visual detail that a developer can recreate them as
Flutter `AnimationController`-driven custom painters or Rive/Lottie-style sequences.
For each, describe: the visual elements, the motion path, the color treatment, and
which app moment it's used for.

1. **"Swimming Fish" loader** — a small stylized fish (same glass-fish motif as the
   logo) swims in a continuous figure-eight or side-to-side path across a short
   horizontal track, leaving a faint fading trail/ripple behind it, tail fin flicking
   on each stroke. Used for: general content loading (e.g. Today screen fetching pond
   status), app-wide default loader.

2. **"Rising Bubbles" loader** — a cluster of 3–5 small translucent bubbles of varying
   size rise vertically from the bottom of a small circular container, gently wobbling
   left-right as they ascend, fading out near the top and looping. Color: pale
   `brightMint`/`paleSky` translucent bubbles over a `deepNavy` circular background.
   Used for: Log Entry saving state, photo upload progress.

3. **"Aerator Ripple" loader** — concentric circular ripple rings expand outward from
   a center point (mimicking a pond aerator churning water), rings fading in opacity
   as they expand, looping continuously with a new ring starting as the outer one
   fades. Used for: the "Sync in Progress" screen, and any background-sync indicator.

4. **"Oxygen Wave" loader** — a horizontal sine-wave line animates flowing
   left-to-right like a water surface ripple, with a small dissolved-oxygen bubble icon
   riding along the wave crest. Used for: forecast/risk calculation loading (e.g. "Ask
   Aqua" thinking state after a question is submitted, DO forecast chart loading).

5. **"Shrimp Curl" loader** — a minimalist line-art shrimp icon curls and uncurls
   rhythmically (tail flexing toward head and back), a simple 2-keyframe loop, subtle
   and quick. Used for: small inline loading spinners (e.g. button-level loading state
   on "Save Log" or "Send OTP" while the request is in flight).

6. **"Net Cast" loader** — a stylized casting net icon expands outward from a center
   point in a circular fan pattern then contracts back, mimicking a fisherman's throw
   net opening and closing, looping smoothly. Used for: pull-to-refresh interactions
   (e.g. refreshing Today screen or Alerts list).

For every loader: keep the motion smooth and looping (no jarring resets), keep the
color treatment consistent with the locked palette (deepNavy/midBlue/seaGreen/
brightMint/paleSky only — no off-palette colors), and keep loaders small and
unobtrusive (loaders should never dominate the screen or block the user from seeing
context beneath them, except for true full-screen blocking states like initial app
launch data fetch).

---

## Output format requested from Stitch

Generate this as a structured multi-frame UI kit — one frame per screen listed in
Sections 1–5 (25 frames total), one frame for the Section 6 design system reference,
and one frame for the Section 7 loader concepts (all 6 loaders shown together on one
reference frame, each labeled with its name and its usage context). Name every frame
exactly matching the numbering above (e.g. "2.4 Alerts", "3.1 Blind-State Banner",
"7. Loader Concepts") so each screen can be referenced unambiguously in later
implementation prompts to Antigravity. Maintain pixel-consistent spacing, shadow
depth, corner radius, and iconography across all 27 frames as one unified system —
this should look and feel like a single professionally designed app, not 27
independently generated screens stitched together.

---

### Implementation notes (meta, not part of the Stitch prompt)

- Intentionally exhaustive so Stitch has no ambiguity left to fill in on its own. If
  Stitch can't hold the full spec in one generation without dropping detail, batch:
  generate Section 1, then Section 2, then Sections 3–5, then Sections 6–7, each as a
  separate follow-up prompt that reuses the "Global rules" block verbatim so visual
  consistency doesn't drift between batches.
- Loaders are described as motion concepts — Stitch renders them as static key-frame
  illustrations. The looping animation logic is implemented natively in Flutter
  (custom `AnimationController` + `CustomPainter`, per the "no animation package" rule
  already given to Antigravity).
- Flag immediately if Stitch's output drifts on the Alerts screen specifically — it's
  been dropped or under-specified in every prior generation pass, so verify it first.

#### Frame count check
Sections 1–5 = 5 + 5 + 6 + 6 + 3 = **25** frames. + Design System (26) + Loaders (27) = **27 total**.
