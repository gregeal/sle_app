# SLE Prep / Objectif C

An Android and authenticated-web Flutter app for preparing for the Canadian federal public-service Second Language Evaluation (SLE) in French. The goal is C-level readiness across reading, writing, and oral interaction, built around a 26-week study plan at 60–90 minutes per day.

All five planned phases (P0–P4) are implemented in the repository:

- **Daily habit engine (P0)** — 26-week curriculum, 309 workplace vocabulary cards with SM-2 spaced repetition, 92+ SLE-style grammar drills with explanations and weak-topic prioritization, a composed daily session with completion checklist, streaks, and resource links (Mauril, PSC self-assessments). Fully offline.
- **AI integration (P0/P1)** — provider-agnostic LLM client (OpenAI, OpenRouter, local Ollama, Anthropic, or any OpenAI-compatible endpoint) with connection test, encrypted API-key storage, and validated on-demand generation of new grammar drills and reading passages. Adapts automatically to newer OpenAI parameter requirements (`max_completion_tokens`, locked temperature).
- **Reading & writing (P1)** — timed SLE-style reading comprehension (memos, emails, policy excerpts) with per-question explanations, and guided composition with AI feedback: inline corrections, a corrected model text, an unofficial A/B/C level estimate, and concrete tips.
- **Oral coach (P2)** — daily and guided modes use on-device STT/TTS; the full OpenAI Realtime interview is true low-latency voice-to-voice over WebRTC, with semantic turn detection, natural interruptions, adaptive A → B → C follow-ups, live transcripts, and a saved report against the five official OLA criteria (aisance, compréhension, vocabulaire, grammaire, prononciation).
- **Checkpoints & dashboard (P3)** — monthly mock-exam checkpoints for all three skills, scored against approximate published cut lines, feeding a per-skill level-trajectory dashboard with streak, total study hours, and per-topic accuracy.
- **Secure web session (P4)** — Flutter Web with browser-local SQLite/OPFS, an allowlisted FastAPI AI Broker, Google OAuth bootstrap, passkey sign-in, HttpOnly sessions + CSRF, model/rate/budget enforcement, and feature parity including Realtime WebRTC. Deployment is defined by `Dockerfile` and `render.yaml`.

Navigation: **Accueil** (today's session), **Réviser** (vocabulary, grammar, reading, writing, AI generation), **Coach** (oral practice), **Progrès** (trajectory, stats, mock exams), **Paramètres** (AI provider).

Vocabulary, grammar drills, and seeded reading passages work fully offline. On Android, AI features use the provider configured in-app and the key remains in encrypted device storage. On the web, the browser never receives a long-lived provider key: text calls pass through the authenticated broker and Realtime receives only a short-lived OpenAI client credential. The Realtime interview sends microphone audio directly to OpenAI. All level estimates are **unofficial**; the app makes no official SLE claims.

Project documents in the repository root:

- [`PRD.md`](PRD.md) — full product requirements
- [`docs/plans/2026-07-12-p0-implementation-plan.md`](docs/plans/2026-07-12-p0-implementation-plan.md)
- [`docs/plans/2026-07-13-p4-web-plan.md`](docs/plans/2026-07-13-p4-web-plan.md) — web architecture and implementation evidence
- [`docs/security/p4-web-security-checklist.md`](docs/security/p4-web-security-checklist.md) — web release security checklist
- [`docs/design/objectif-c-ecrans-android.dc.html`](docs/design/objectif-c-ecrans-android.dc.html) — design screens

## Prerequisites

Use a Windows machine with:

1. **Flutter 3.44.6 or newer** on the stable channel (Dart 3.12+).
2. The **Android SDK** with Platform-Tools (`adb`), a platform, and Build-Tools — via Android Studio's SDK Manager or the command-line tools.
3. A **JDK 17+** for Gradle (Android Studio's bundled JBR, or a standalone JDK configured with `flutter config --jdk-dir`).
4. An Android phone with USB debugging enabled (recommended — the oral coach needs a real microphone), or an emulator.
5. For voice-to-voice interviews: a stable Internet connection, headphones or a quiet room, and an OpenAI API account with Realtime access and billing enabled.
6. For web/broker development: **uv 0.9.4+** and Python 3.12. Docker Desktop is optional for validating the production image.

## One-time Windows setup

### 1. Install Flutter

Download the stable Flutter SDK for Windows from <https://docs.flutter.dev/get-started/install/windows>, then extract it somewhere without spaces. This workspace uses `C:\dev\flutter`.

For the current PowerShell window, add Flutter to `PATH`:

```powershell
$env:Path = "C:\dev\flutter\bin;$env:Path"
```

To make that permanent, add `C:\dev\flutter\bin` to your **user** `Path` environment variable in Windows, then open a new terminal.

Verify the SDK:

```powershell
flutter --version
flutter doctor
```

### 2. Configure the Android SDK

Install the SDK components (via Android Studio's **SDK Manager**, or `sdkmanager` from the command-line tools), then accept the licences:

```powershell
flutter config --android-sdk "$env:LOCALAPPDATA\Android\Sdk"
flutter doctor --android-licenses
flutter doctor
```

If `flutter doctor` detects an old Java installation, point Flutter at a modern JDK:

```powershell
flutter config --jdk-dir "C:\dev\jdk"          # standalone JDK
# or: flutter config --jdk-dir "C:\Program Files\Android\Android Studio\jbr"
```

Run `flutter doctor` again; Android should show no blocking issue before you build.

#### Fix: Android SDK Command-line Tools missing

If `flutter doctor` reports **`cmdline-tools component is missing`** or **`Android sdkmanager not found`**, install **Android SDK Command-line Tools (latest)** (SDK Manager → SDK Tools tab), confirm with:

```powershell
Test-Path "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat"
```

then rerun the three commands above. Do **not** use Android Studio's `jbr` directory as the Android SDK path — it is a Java runtime, not the SDK.

### 3. Choose a device

#### Physical Android phone (recommended)

1. Enable **Developer options** and **USB debugging** on the phone.
2. Connect by USB and accept the debugging prompt.
3. Verify: `adb devices` and `flutter devices`.

If `adb devices` shows `unauthorized`, unlock the phone and accept the RSA prompt. If no device appears, switch the USB mode from "charging only" to file transfer, or install the manufacturer's USB driver.

#### Android emulator

Create and start an emulator in Android Studio's Device Manager, then check `flutter devices`. Note: speech recognition and TTS quality on emulators is poor; use a phone for the oral coach.

## Run the app

```powershell
cd "C:\Users\grege\Documents\My Docs\MyApp\sle_prep"
flutter pub get
flutter analyze
flutter test
flutter run
```

With several devices connected, pick one: `flutter run -d <device-id>`.

During development: `r` hot-reloads, `R` restarts, `q` quits.

On first launch the app imports its bundled curriculum, vocabulary, drills, reading passages, and oral questions into the on-device database. Upgrades import only new content — existing progress and earlier seed data are never duplicated.

## Run the web app and broker locally

The secure web deployment is same-origin: FastAPI serves the Flutter build and `/api/*`, so cookies need no CORS exception. The production bundle also self-hosts its Noto Sans and Flutter fallback fonts under their included open-font licenses; no runtime font CDN is required.

```powershell
cd "C:\Users\grege\Documents\My Docs\MyApp\sle_prep"
flutter pub get
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run

cd ..\broker
Copy-Item .env.example .env
```

Edit `broker\.env` for local use:

```dotenv
ENVIRONMENT=development
PUBLIC_ORIGIN=http://localhost:8000
STATIC_DIR=../sle_prep/build/web
DATABASE_PATH=data/broker.db
ALLOWED_EMAILS=you@example.com
DEV_LOGIN_ENABLED=true
OPENAI_API_KEY=your-key-from-the-provider-dashboard
```

Set the text model and **current** provider pricing/caps in the same file, then run:

```powershell
uv sync --dev
uv run uvicorn app.asgi:app --reload --port 8000
```

Bootstrap the local session once at `http://localhost:8000/auth/dev?email=you@example.com`, then open `http://localhost:8000/`. The development-login route returns 404 in production. To exercise the production-shaped container instead:

```powershell
cd "C:\Users\grege\Documents\My Docs\MyApp"
docker build -t sle-prep .
docker run --rm --env-file broker/.env -p 8000:8000 -e PORT=8000 sle-prep
```

### Deploy with Render

1. In Render, create a **Blueprint** from this repository's `render.yaml`. A paid starter service is specified because the broker's session/passkey SQLite file needs a persistent disk.
2. Enter every variable marked `sync: false`: the final HTTPS `PUBLIC_ORIGIN`, owner `ALLOWED_EMAILS`, Google OAuth credentials, OpenAI key, daily/monthly limits, current per-token prices, and a conservative Realtime-session reservation.
3. In Google Cloud, register exactly `https://YOUR_DOMAIN/auth/google/callback` as an authorized redirect URI. The same host must match `PUBLIC_ORIGIN` for cookies and WebAuthn.
4. After the first Google sign-in, open **Paramètres → Créer une passkey**. Future sign-ins can use the passkey.
5. Add a custom domain in Render if desired; Render provisions TLS. Run Mozilla Observatory against the final URL and archive the result in `docs/security/` before treating the deployment as released.

Never place `OPENAI_API_KEY` in Dart defines, JavaScript, `localStorage`, IndexedDB, the repository, or a client-readable Render variable. Use only the Render secret prompt/environment.

## Android AI provider setup (in-app)

1. Open **Paramètres**, pick a provider (OpenAI, OpenRouter, Ollama local, Anthropic, or custom), enter the base URL, model name, and API key.
2. Tap **Tester la connexion** — it saves the form and performs a cheap round-trip.
3. Notes:
   - OpenAI text features: choose a text model supported by Chat Completions. Realtime/voice-only models do not work in the regular **Nom du modèle** field.
   - OpenAI voice interview: leave **Modèle Realtime** at `gpt-realtime` unless your account requires another supported Realtime model; choose the evaluator voice separately. This feature requires the official `https://api.openai.com/v1` base URL.
   - Ollama on a physical phone: use your PC's LAN IP (e.g. `http://192.168.1.10:11434/v1`); `10.0.2.2` only resolves on the emulator.
   - Text and Realtime audio usage are billed separately. Check the provider's current pricing and your usage dashboard rather than relying on a hard-coded estimate.

## Use the true voice-to-voice interview

1. In **Paramètres**, choose **OpenAI compatible**, set the base URL to `https://api.openai.com/v1`, enter a working text model, and save your OpenAI API key.
2. Under **Entrevue voix-à-voix**, keep `gpt-realtime` (or enter a Realtime model available to your account) and choose a voice such as `marin` or `cedar`.
3. Tap **Tester la connexion**. This checks the text model; it does not spend Realtime audio tokens.
4. Open **Coach → Entrevue Realtime**, read the cost/microphone notice, and tap **Commencer l'entrevue**.
5. Speak naturally. Server-side semantic voice activity detection decides when each turn ends and supports interrupting the evaluator. Use the mic button to mute temporarily.
6. Tap **Terminer et analyser**. The WebRTC session closes, the completed transcript is paired into question/answer exchanges, and the configured text model produces and saves the five-criterion report.

The app requests Android microphone permission on first use. Realtime sessions require Internet access and OpenAI; the daily question and guided interview remain available as the lower-cost STT/TTS fallback.

### Realtime credential security

The Android build is personal bring-your-own-key: it never hardcodes a key in the APK, and it exchanges the encrypted device key for a short-lived Realtime credential. The web build follows the public-client pattern: its authenticated broker owns the standard key and returns only the short-lived credential. In both cases WebRTC authenticates with that ephemeral value, following the [official WebRTC guide](https://developers.openai.com/api/docs/guides/realtime-webrtc).

## Run checks

```powershell
cd "C:\Users\grege\Documents\My Docs\MyApp\sle_prep"
flutter analyze
flutter test

cd ..\broker
uv sync --dev
uv run ruff check app tests
uv run pytest
```

The test suite covers the Drift data layer and migrations, SM-2 scheduling, seed validation and incremental import, the session composer, LLM clients (including OpenAI parameter fallbacks), Realtime client-secret/SDP requests and event parsing, drill/reading/writing/oral generation and parsing, mock-exam scoring, and key widget flows.

After changing a Drift table in `lib/data/db/database.dart`, regenerate the database code (and add a migration step in the same file):

```powershell
dart run build_runner build --delete-conflicting-outputs
flutter test
```

## Build an APK

```powershell
flutter build apk --release
flutter install --release
```

Output: `build\app\outputs\flutter-apk\app-release.apk`

> The current Gradle configuration signs release builds with the debug key so local release-mode testing works. Before distributing an APK, configure a real Android release keystore. Do not distribute a debug-signed build.

## Data and reset behaviour

- Study progress lives only in Android SQLite or this browser's SQLite WASM/OPFS database; it is not synced to the broker.
- Seed content imports incrementally, tracked by a local `seedVersion` setting; schema upgrades migrate in place without data loss.
- API keys are stored with `flutter_secure_storage` (Android Keystore-backed) and are write-only in the UI.
- Web sessions/passkey public keys and content-free usage/audit records live in the broker SQLite file. Provider keys, prompts, and transcripts do not.
- **Android Settings → Apps → SLE Prep → Storage → Clear data** permanently removes all progress and re-imports fresh seed content.

## Roadmap

- Session-plan re-weighting from mock-exam results; encrypted cross-device backup/export; release signing.
- Replace the single-instance SQLite limiter with a shared transactional store before horizontally scaling the broker.
- Optional iOS target and broader device-level audio routing tests.

## Project layout

```text
sle_prep/
├── assets/seed/              Curriculum, vocabulary, drills, reading, oral JSON
├── lib/
│   ├── data/db/              Drift tables, migrations, and query helpers
│   ├── data/seed/            Validated incremental seed importer
│   ├── domain/srs/           Pure SM-2 scheduler
│   ├── domain/session/       Pure daily-session composer
│   ├── domain/mock/          Mock-exam scoring and checkpoint math
│   ├── domain/speech/        Device speech-to-text / TTS wrappers
│   ├── domain/llm/           LLM clients, generators, writing & oral coaches
│   ├── domain/realtime/      OpenAI token bootstrap, WebRTC session, events
│   └── features/             Today, practice, reading, writing, coach,
│                             mocks, progress, settings screens
├── test/                     Unit, parser, DAO, and widget tests
├── tool/sqlite3/             sqlite3.dll for host-side Drift tests (Windows)
└── android/                  Android manifest, launcher icon, Gradle project
```

## Troubleshooting

| Problem | What to do |
|---|---|
| `flutter` is not recognized | Add `C:\dev\flutter\bin` to `Path`, open a new terminal, run `flutter --version`. |
| Android licences not accepted | `flutter doctor --android-licenses`, accept each, rerun `flutter doctor`. |
| `cmdline-tools component is missing` | Install **Android SDK Command-line Tools (latest)**, then reconfigure as shown above. |
| Java version too old | `flutter config --jdk-dir "C:\dev\jdk"` (or Android Studio's `jbr`). |
| No Android device found | Reconnect an unlocked, USB-debugging-enabled phone; check `adb devices`. |
| AI test fails with "Connexion impossible" | Check the phone's internet connection; for Ollama use the PC's LAN IP. |
| AI test fails with HTTP 401 / 404 / 429 | 401: re-paste the key. 404: fix the model name. 429: add credit at your provider. |
| Microphone not working in the coach | Grant the microphone permission (Android Settings → Apps → SLE Prep → Permissions). |
| Realtime interview says it needs OpenAI | Select **OpenAI compatible** and use exactly `https://api.openai.com/v1`; OpenRouter, Anthropic, Ollama, and custom endpoints still work for text features but not this WebRTC flow. |
| Realtime fails with HTTP 401 / 403 | Re-paste the OpenAI key and confirm the API project has Realtime access and billing. ChatGPT subscriptions do not supply API credit. |
| Realtime connects but there is no sound | Raise media volume, unmute the app, grant microphone permission, disconnect/reconnect Bluetooth, then retry with the phone speaker or wired headphones. |
| Realtime disconnects or stalls | Switch to a stable Wi-Fi/mobile network, disable restrictive VPN/firewall rules, and retry. The guided STT/TTS interview remains available as a fallback. |
| Web page says no sign-in method is configured | Set Google OAuth credentials or register a passkey after the local/Google bootstrap flow; ensure the browser supports WebAuthn over HTTPS or localhost. |
| Web AI returns 401 / 403 | Refresh the page and sign in again. A 403 can also mean the email is not in `ALLOWED_EMAILS` or the CSRF/session cookie is stale. |
| Web AI returns 429 | Wait for the minute window or budget renewal; check the broker's configured daily/monthly cap. Do not weaken limits without reviewing provider usage. |
| Browser storage falls back from OPFS | Serve through the broker/container so COOP and COEP headers are present; direct ad-hoc static servers may omit them. |
| Database/schema errors after table changes | `dart run build_runner build --delete-conflicting-outputs`. |
| Need a clean test run | `flutter clean`, then `flutter pub get` and `flutter test`. |
