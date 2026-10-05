# Acceptance Criteria — AquaVerse AI Frontend

## 1. Onboarding & Authentication
- [x] **Language Selection**: Supports 4 languages (Tamil, English, Hindi, Telugu) with instant UI locale switching.
- [x] **Mobile Entry**: Enforces 10-digit Indian phone number validation (+91 fixed prefix).
- [x] **OTP Verification**: 6-digit PIN entry with auto-advance focus, 30s countdown timer, and resend functionality.
- [x] **Role Selection**: Farmer vs. Extension Officer role selection writing `has_onboarded = true` to `SharedPreferences`.
- [x] **Splash Routing**: Auto-routes to `/today` or `/officer/dashboard` when `has_onboarded = true` and token valid; routes to `/login` when token expired; routes to `/onboarding/language` on fresh install.

## 2. Data Logging & Offline Capabilities
- [x] **Offline Entry**: Water quality parameter logs (pH, Dissolved Oxygen, Salinity, Temperature, Ammonia) are written locally to Drift SQLite.
- [x] **Outbox Queue**: Network mutations are queued in Drift SQLite outbox table when offline.
- [x] **Auto Sync**: Background auto-sync attempts push when network connectivity is restored via `connectivity_plus`.
- [x] **Staleness Indicator**: Displays "Data as of X ago" badge on parameter displays.

## 3. User Experience & Design System
- [x] **Qualitative Status Indicators**: Uses icon-first status discs (`Good`, `Caution`, `Critical`) rather than raw ambiguous numbers alone.
- [x] **TTS Audio Guidance**: Speaker buttons trigger localized audio playback for low-literacy farmer accessibility.
- [x] **Blind State Warnings**: Non-negotiable alerts display prominent warning banners when parameters exceed safety thresholds or logs are missing.
