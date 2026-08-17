# Implementation Log — AquaVerse AI

## 2026-08-14 — Task 1: Shared Widgets Foundation & Onboarding Flow

### 1. Shared Components Foundation (`lib/shared/widgets/`)
- [speaker_button.dart](file:///home/techpark-6/Music/AquaVerse%20AI/aquaverse_farmer_app/lib/shared/widgets/speaker_button.dart): Audio TTS speaker button with animated soundwave indicator.
- [status_disc.dart](file:///home/techpark-6/Music/AquaVerse%20AI/aquaverse_farmer_app/lib/shared/widgets/status_disc.dart): Icon-first qualitative status indicator disc (`Good`, `Caution`, `Critical`).
- [action_card.dart](file:///home/techpark-6/Music/AquaVerse%20AI/aquaverse_farmer_app/lib/shared/widgets/action_card.dart): Daily farmer action card featuring title, time/schedule, speaker button, and action callback.
- [staleness_badge.dart](file:///home/techpark-6/Music/AquaVerse%20AI/aquaverse_farmer_app/lib/shared/widgets/staleness_badge.dart): "Data as of X ago" timestamp indicator.
- [offline_banner.dart](file:///home/techpark-6/Music/AquaVerse%20AI/aquaverse_farmer_app/lib/shared/widgets/offline_banner.dart): Offline network banner with pending sync queue count.
- [blind_state_banner.dart](file:///home/techpark-6/Music/AquaVerse%20AI/aquaverse_farmer_app/lib/shared/widgets/blind_state_banner.dart): Non-negotiable alert suppression / missing log warning banner.

### 2. Core Storage & Auth Services
- [onboarding_flag_store.dart](file:///home/techpark-6/Music/AquaVerse%20AI/aquaverse_farmer_app/lib/core/storage/onboarding_flag_store.dart): SharedPreferences manager for `has_onboarded`, language, role, and mobile number.
- [auth_api_service.dart](file:///home/techpark-6/Music/AquaVerse%20AI/aquaverse_farmer_app/lib/core/network/auth_api_service.dart): Backend service handling `otp/request` (+91 mobile validation) and `otp/verify` (6-digit code verification).

### 3. Onboarding Flow (`lib/features/onboarding/presentation/`)
- [onboarding_controller.dart](file:///home/techpark-6/Music/AquaVerse%20AI/aquaverse_farmer_app/lib/features/onboarding/presentation/controllers/onboarding_controller.dart): Unified Riverpod `Notifier` managing language, mobile number validation, 6-digit OTP state, 30s countdown resend timer, role selection, and onboarding flag completion.
- [language_select_screen.dart](file:///home/techpark-6/Music/AquaVerse%20AI/aquaverse_farmer_app/lib/features/onboarding/presentation/language_select_screen.dart): 4 language toggle cards (Tamil default/selected, English, Hindi, Telugu), advancing to Phone Entry.
- [phone_entry_screen.dart](file:///home/techpark-6/Music/AquaVerse%20AI/aquaverse_farmer_app/lib/features/onboarding/presentation/phone_entry_screen.dart): Fixed +91 country prefix box, 10-digit numeric text field, privacy note, disabled "Send OTP" button until 10 digits entered. Includes back button navigation.
- [otp_verify_screen.dart](file:///home/techpark-6/Music/AquaVerse%20AI/aquaverse_farmer_app/lib/features/onboarding/presentation/otp_verify_screen.dart): 6 separate digit input boxes with auto-advance focus, 30s countdown resend timer, error message + shake animation on failure.
- [role_selection_screen.dart](file:///home/techpark-6/Music/AquaVerse%20AI/aquaverse_farmer_app/lib/features/onboarding/presentation/role_selection_screen.dart): Dual selectable cards for Farmer vs. Extension Officer roles, writing `has_onboarded=true` and routing to `/today` (Farmer) or `/officer/dashboard` (Officer).

### 4. Splash Screen Revamp & Login Navigation
- Integrated new landscape background plate and centered PNG logo.
- Replaced glassmorphism card with a custom 3D animated multi-ring loader (`Matrix4` rotations + scale animation).
- Built contextual auto-navigation: Checks `OnboardingFlagStore.hasOnboarded` and routes via Iris-In transition to either `/onboarding/language` (first time) or `/login` (returning user).
- Created `/login` placeholder screen and updated `app_router.dart` accordingly.

### 5. Router Integration & Verification Results
- Registered routes in [app_router.dart](file:///home/techpark-6/Music/AquaVerse/lib/core/router/app_router.dart): `/onboarding/language`, `/onboarding/mobile`, `/onboarding/otp`, `/onboarding/role`, `/today`, `/officer/dashboard`.
- `flutter analyze`: **No issues found!**
- `flutter test`: **All tests passed! (8/8 tests)**
- Deployment: Streamed install succeeded and app launched on **Pixel 9a emulator** (`com.aquaverse.aquaverse_farmer_app/.MainActivity`).

---

## 2026-08-17 — Task 2: Splash Screen Rebuild From Scratch (Sphere Animation Match)

### 1. Reference Video Analysis
- Primary Reference: `Sphere Animation.mp4`
- Secondary Composition Reference: `Splash screen reference.mp4`
- Motion Choreography Observations:
  - 3D tumble on Y-axis (360° spin) with a 15° X-axis perspective tilt.
  - Scale-in from `0.3` to `1.0` over 2400ms entrance driven by `Curves.easeOutCubic`.
  - Continuous ambient 360° Y-axis idle rotation (12s cycle) after entrance completes.
  - Specular gradient light sweep across glass surface.
  - Staggered entrance timing: Title at 1800ms, Subtitle at 2100ms, Primary Button at 2400ms.

### 2. Implementation & Stack Discipline
- **Deleted**: Obsolete 2D painter `lib/features/splash/widgets/fish_logo_painter.dart`.
- **Rebuilt**: `lib/features/splash/splash_screen.dart` from scratch using pure native Flutter `Transform` + `Matrix4` 3D perspective matrix (`Matrix4.identity()..setEntry(3, 2, 0.0015)..rotateY(...)..rotateX(...)`).
- **Shader Sweep**: Implemented animated `ShaderMask` sweep using locked brand palette (`#1B4F7A` Deep Navy → `#4FAE9E` Sea Green → `#3FCCA6` Bright Mint).
- **Background**: Full-bleed `assets/images/splash_background.png`.
- **Exit Transition**: Unchanged `IrisTransition` (`iris_transition.dart`) triggered by "Get Started" button tap to `/onboarding/language`.

---

## 2026-08-17 — Task 3: Pivot to Splash Text-Reveal + Orbiting Dual-Dot Loader

### 1. Direction Pivot
- Previous sphere-rotation approach superseded. New reference shows a progressive text blur/focus sweep and a transitional orbiting two-dot loader. No 3D sphere.

### 2. Components Built
- **[NEW] [orbit_dots_loader.dart](file:///home/techpark-6/Music/AquaVerse/lib/shared/widgets/orbit_dots_loader.dart)**: Reusable widget — two dots (`seaGreen` solid + `brightMint` translucent) orbiting 180° out of phase using `Transform.translate` with `sin`/`cos` offsets. Generic constructor: size, dotSize, color1, color2, period.
- **[REBUILT] [splash_screen.dart](file:///home/techpark-6/Music/AquaVerse/lib/features/splash/splash_screen.dart)**:
  - Progressive `ImageFilter.blur` focus sweep per text block via `ImageFiltered` widget, driven by staggered `AnimationController` intervals.
  - GPU safeguard: `sigma <= 0.3` bypasses `ImageFiltered` and uses plain `Opacity` to avoid unnecessary rasterization budget on low-end devices.
  - Max blur sigma capped at `kMaxBlurSigma = 10.0` to stay within 2GB Android Go raster budget.
  - `_buildBlurText()` helper centralises blur/opacity logic and is the correct point to swap in a pure-opacity fallback if device profiling shows jank.
  - Ghost-to-solid button via animated `Color.lerp` across gradient stops, border color, and box shadow.
  - `OrbitDotsLoader` shown during route-decision async call (real loading state, no artificial delay).
- **[REBUILT] [splash_controller.dart](file:///home/techpark-6/Music/AquaVerse/lib/features/splash/splash_controller.dart)**:
  - All three routing table branches enforced (PRD-AV-04 §7 Rule 2):
    - `has_onboarded == false` → `/onboarding/language`
    - `has_onboarded == true` + valid token → `/today` or `/officer/dashboard`
    - `has_onboarded == true` + expired/missing token → `/onboarding/mobile`

### 3. Performance Notes
- `ImageFilter.blur` is applied only while `sigma > 0.3` (early animation frames). At rest it falls back to plain `Opacity(child: Text(...))`.
- **Low-End Device Action Required**: Run `flutter run --profile -d <android-go-emulator>` and check for dropped frames in the blur sweep phase. If frame drops exceed 5% during the 0–1200ms entrance window, replace `ImageFiltered` in `_buildBlurText()` with a simple `Opacity(opacity: opacity, child: Text(...))` fallback — the code is already structured to make this a 2-line change.

### 4. Verification Results
- `flutter analyze`: **0 errors, 0 warnings** (9 info items).
- `flutter test`: **9/9 tests passed.**

---

## 2026-08-17 — Task 4: Onboarding Screen Background Image Integration

### 1. Assets & Styling
- Placed attached aquaculture background image into `assets/images/onboarding_bg.png` (576x1024 vertical aqua fish-farm scene with mountains, circular net cages, and decorative overlay lines).
- Created **[OnboardingScaffold](file:///home/techpark-6/Music/AquaVerse/lib/shared/widgets/onboarding_scaffold.dart)** widget to wrap onboarding screens with `BoxFit.cover` background image rendering and a soft white gradient overlay (`0.35 → 0.15 → 0.25` opacity stops) to ensure high contrast and maximum text legibility across all device screen sizes.

### 2. Screens Updated
- **[language_select_screen.dart](file:///home/techpark-6/Music/AquaVerse/lib/features/onboarding/presentation/language_select_screen.dart)**
- **[phone_entry_screen.dart](file:///home/techpark-6/Music/AquaVerse/lib/features/onboarding/presentation/phone_entry_screen.dart)**
- **[otp_verify_screen.dart](file:///home/techpark-6/Music/AquaVerse/lib/features/onboarding/presentation/otp_verify_screen.dart)**
- **[role_selection_screen.dart](file:///home/techpark-6/Music/AquaVerse/lib/features/onboarding/presentation/role_selection_screen.dart)**
- **[ai_intro_screen.dart](file:///home/techpark-6/Music/AquaVerse/lib/features/onboarding/presentation/ai_intro_screen.dart)**

### 3. Verification Results
- `flutter analyze`: **0 errors, 0 warnings** (9 info hints).
- `flutter test`: **9/9 tests passed.**

---

## 2026-08-17 — Task 5: Select Language Screen Rebuild (AquaVerse Teal/Sea-Green Light Theme)

### 1. Design Tokens Added
- Added centralized `AppColors.lang*` design tokens in **[app_colors.dart](file:///home/techpark-6/Music/AquaVerse/lib/core/theme/app_colors.dart)**:
  - `langBgPrimary`: `#FFFFFF`
  - `langBgSurface`: `#F4FBF9`
  - `langBgSelected`: `#E4F6F1`
  - `langBorderDefault`: `#E0EEEA`
  - `langBorderSelected`: `#14B8A6`
  - `langAccentPrimary`: `#0E9488`
  - `langAccentSeagreen`: `#2E8B77`
  - `langCtaGradient`: `LinearGradient(colors: [#2E8B77, #14B8A6])`
  - `langTextPrimary`: `#0B2B27`
  - `langTextSecondary`: `#5B7A75`

### 2. Screen Layout & Architecture ([language_select_screen.dart](file:///home/techpark-6/Music/AquaVerse/lib/features/onboarding/presentation/language_select_screen.dart))
- **Header Badge**: 64dp circular gradient icon badge (`#2E8B77` → `#14B8A6`) with globe icon (`Icons.language_rounded`).
- **Title & Subtitle**: "Select Language" + "Choose your preferred language to continue" + `SpeakerButton` voice prompt.
- **Search Bar**: Full-width rounded input (`#F0F7F5`) with live real-time filtering across native names, English names, and country codes.
- **Scrollable List**: ~64dp tiles with country/language code badges, native script titles, English subtitles, and selected-state checkmarks.
- **Sticky CTA**: Full-width gradient "Continue" button (`#2E8B77` → `#14B8A6`).

### 3. Verification Results
- `flutter analyze`: **0 errors, 0 warnings** (9 info hints).
- `flutter test`: **9/9 tests passed.**

---

## 2026-08-17 — Task 6: Today Screen 3D-Minimal Visual Redesign

### 1. Visual Redesign Summary
- Redesigned `TodayScreen` using a 3D-minimal glassmorphism visual language.
- Added 3D depth gradients, radial glow motifs, tier-based card elevations (`_Tier1GlassCard`, `_Tier2GlassCard`), ambient background drifting blob, 9-section staggered load-in animation choreography, and breathing glow buttons.

### 2. Verification Results
- `flutter analyze`: **0 errors, 0 warnings**.
- `flutter test`: **9/9 tests passed.**

---

## 2026-08-17 — Task 7: Sensor-Driven Log Pivot (Scope C Implementation)

### 1. Architectural Changes
- **Log Screen Rebuilt** (`log_entry_screen.dart`):
  - **Top Read-Only Card**: Displays live sensor readings (DO, pH, Temp, Salinity) with `StalenessBadge` auto-synced from IoT backend.
  - **"What sensors can't see" Section**: Retained manual observation inputs: Feed Given (kg) stepper, Mortality Count, Feed Tray Check, and Water Appearance.
  - **Removed**: Manual numeric input fields for pH, DO, Temp, Salinity (now sensor-driven).
  - **Photo Upload**: Integrated 2-phase `/v1/media/upload-url` -> `/v1/media/{media_id}/commit` flow.
- **Endpoint Alignment**: Verified and documented the 19-endpoint matrix across `ApiClient`, `LogRepository`, and `docs/BACKEND_SYNC_NOTES.md`.

### 2. Verification Results
- `flutter analyze`: **0 errors, 0 warnings**.
- `flutter test`: **9/9 tests passed.**
