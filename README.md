# AquaVerse AI — Frontend Mobile Application

AquaVerse AI is an offline-first, voice-guided Flutter mobile application built for aquaculture farmers and extension officers. It enables seamless pond management, daily water parameter logging, AI voice assistance, automated risk alerts, and extension officer supervision.

---

## 🌟 Architecture & Tech Stack

The application strictly adheres to the locked tech stack and architectural constraints:

- **Framework**: Flutter 3.8 / Dart SDK `^3.8.0`
- **State Management**: `flutter_riverpod` (`^2.5.1`) with `riverpod_annotation`
- **Routing**: `go_router` (`^14.2.0`)
- **Database & Offline Queue**: `drift` (`^2.34.3`) + `sqlite3_flutter_libs` (SQLite outbox pattern)
- **Secure Secret Storage**: `flutter_secure_storage` (`^9.2.2`)
- **Simple Launch Gating**: `shared_preferences` (`^2.3.2`) — restricted strictly to `has_onboarded` flag
- **Networking**: `dio` (`^5.7.0`) + `retrofit` (`^4.4.1`)
- **Audio & Media**: `just_audio` (`^0.9.40`) for TTS voice guidance and audio playback
- **Push Notifications**: `firebase_messaging` (`^15.1.3`) + `flutter_local_notifications` (`^17.2.3`)

---

## 🔒 3-Layer Storage Contract

| Storage Layer | Allowed Usage | Constraints & Rules |
|---|---|---|
| **Drift (SQLite)** | Structured data (ponds, water logs, risk alerts, sync outbox) | Offline-first, reactive query streams, relational integrity |
| **`flutter_secure_storage`** | Auth tokens, refresh tokens, API credentials | Encrypted device keychain/keystore |
| **`shared_preferences`** | Simple launch-gating flag (`has_onboarded`) | Strictly restricted to `has_onboarded` flag only |

---

## 🔀 Onboarding & Routing Matrix

| `has_onboarded` | Valid/refreshable Token | Navigation Target |
|---|---|---|
| `false` | — | Full Onboarding (`/onboarding/language` ➔ `/mobile` ➔ `/otp` ➔ `/role`) |
| `true` | Yes | Today Dashboard (`/today` for Farmers, `/officer/dashboard` for Officers) |
| `true` | No | Re-login (`/login` — OTP verification only, skipping language/role pickers) |

---

## 📁 Directory Structure

```
lib/
├── app/                  # Application root & Riverpod config
├── core/                 # Core utilities & cross-cutting concerns
│   ├── config/           # App config & environment constants
│   ├── database/         # Drift SQLite database, tables, & connections
│   ├── errors/           # Failure & exception handling definitions
│   ├── network/          # Dio HTTP client, Retrofit services, & auth API
│   ├── repositories/     # Offline-first repository implementations
│   ├── router/           # GoRouter route definitions & auth guards
│   ├── services/         # Audio TTS, connectivity monitoring, push notifications
│   ├── storage/          # SharedPreferences flag store & SecureStorage
│   ├── sync/             # Offline queue manager & auto-sync worker
│   └── theme/            # AquaVerse design system tokens & colors
├── features/             # Feature modules
│   ├── alerts/           # Risk alerts & warning center
│   ├── ask/              # Voice-first AI assistant & speech queries
│   ├── crop/             # Crop cycle management & stocking history
│   ├── help/             # Help center & FAQ resources
│   ├── log/              # Offline-first pond parameter logging
│   ├── notifications/     # Broadcast & targeted alert history
│   ├── officer/          # Extension officer dashboard & farmer list
│   ├── onboarding/       # Language selection, mobile entry, OTP, role picker
│   ├── ponds/            # Pond management & parameter thresholds
│   ├── profile/          # User profile & farm setup
│   ├── settings/         # App preferences & offline sync status
│   ├── splash/           # 3D animated multi-ring loader & splash route guard
│   └── today/            # Farmer daily summary & task action cards
└── shared/               # Reusable UI widgets & components
    ├── models/           # Shared domain entities & enums
    └── widgets/          # AppCard, ActionCard, SpeakerButton, StatusDisc, StalenessBadge
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.8.0`
- Dart SDK `^3.8.0`
- Android Studio / Xcode (for mobile emulator testing)

### Installation & Setup

1. **Clone the Repository**:
   ```bash
   git clone -b frontend https://github.com/AquaverseAI/AquaVerse.git
   cd AquaVerse
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Code Generation** (if updating Drift / Retrofit / Freezed schemas):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Execute Linter & Tests**:
   ```bash
   flutter analyze
   flutter test
   ```

5. **Run the Application**:
   ```bash
   flutter run
   ```

---

## 🧪 Quality & Engineering Guidelines

- **Zero-Capex, 12-Week MVP Framing**: Minimal client overhead; no bloated state management or redundant architectural layers.
- **Rule Discipline (R1–R9)**: Enforces offline sync, outbox retry strategy, qualitative risk level indicators, and voice-assisted TTS guidance.
