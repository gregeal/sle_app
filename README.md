# SLE Prep / Objectif C

An Android-first Flutter app for preparing for the Canadian federal public-service Second Language Evaluation (SLE) in French. The goal is C-level readiness across reading, writing, and oral interaction, built around a 26-week study plan at 60–90 minutes per day.

All four planned phases (P0–P3) are implemented:

- **Daily habit engine (P0)** — 26-week curriculum, 309 workplace vocabulary cards with SM-2 spaced repetition, 92+ SLE-style grammar drills with explanations and weak-topic prioritization, a composed daily session with completion checklist, streaks, and resource links (Mauril, PSC self-assessments). Fully offline.
- **AI integration (P0/P1)** — provider-agnostic LLM client (OpenAI, OpenRouter, local Ollama, Anthropic, or any OpenAI-compatible endpoint) with connection test, encrypted API-key storage, and validated on-demand generation of new grammar drills and reading passages. Adapts automatically to newer OpenAI parameter requirements (`max_completion_tokens`, locked temperature).
- **Reading & writing (P1)** — timed SLE-style reading comprehension (memos, emails, policy excerpts) with per-question explanations, and guided composition with AI feedback: inline corrections, a corrected model text, an unofficial A/B/C level estimate, and concrete tips.
- **Oral coach (P2)** — daily and guided modes use on-device STT/TTS; the full OpenAI Realtime interview is true low-latency voice-to-voice over WebRTC, with semantic turn detection, natural interruptions, adaptive A → B → C follow-ups, live transcripts, and a saved report against the five official OLA criteria (aisance, compréhension, vocabulaire, grammaire, prononciation).
- **Checkpoints & dashboard (P3)** — monthly mock-exam checkpoints for all three skills, scored against approximate published cut lines, feeding a per-skill level-trajectory dashboard with streak, total study hours, and per-topic accuracy.

Navigation: **Accueil** (today's session), **Réviser** (vocabulary, grammar, reading, writing, AI generation), **Coach** (oral practice), **Progrès** (trajectory, stats, mock exams), **Paramètres** (AI provider).

Vocabulary, grammar drills, and seeded reading passages work fully offline. AI features require a configured provider. The API key is stored with Android encrypted storage and is sent only over HTTPS to the provider you selected for authenticated API calls; it is not stored in SQLite or sent to an SLE Prep developer server. The Realtime interview additionally sends microphone audio to OpenAI. All level estimates are **unofficial**; the app makes no official SLE claims.

Project documents in the repository root:

- [`PRD.md`](PRD.md) — full product requirements
- [`docs/plans/2026-07-12-p0-implementation-plan.md`](docs/plans/2026-07-12-p0-implementation-plan.md)
- [`docs/design/objectif-c-ecrans-android.dc.html`](docs/design/objectif-c-ecrans-android.dc.html) — design screens

## Prerequisites

Use a Windows machine with:

1. **Flutter 3.44.6 or newer** on the stable channel (Dart 3.12+).
2. The **Android SDK** with Platform-Tools (`adb`), a platform, and Build-Tools — via Android Studio's SDK Manager or the command-line tools.
3. A **JDK 17+** for Gradle (Android Studio's bundled JBR, or a standalone JDK configured with `flutter config --jdk-dir`).
4. An Android phone with USB debugging enabled (recommended — the oral coach needs a real microphone), or an emulator.
5. For voice-to-voice interviews: a stable Internet connection, headphones or a quiet room, and an OpenAI API account with Realtime access and billing enabled.

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

## AI provider setup (in-app)

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

This repository is a personal, bring-your-own-key app: it never hardcodes an API key into the APK. The device uses the key from Android encrypted storage to call `/v1/realtime/client_secrets`, then authenticates the WebRTC call with the returned short-lived credential. Do not distribute a build with a preloaded or shared key. Before turning this into a multi-user/public app, move client-secret creation to an authenticated server endpoint so the standard OpenAI key never exists in client code or on end-user devices, as required by the [official WebRTC guide](https://developers.openai.com/api/docs/guides/realtime-webrtc).

## Run checks

```powershell
cd "C:\Users\grege\Documents\My Docs\MyApp\sle_prep"
flutter analyze
flutter test
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

- All progress lives in on-device SQLite; there is no account or server.
- Seed content imports incrementally, tracked by a local `seedVersion` setting; schema upgrades migrate in place without data loss.
- API keys are stored with `flutter_secure_storage` (Android Keystore-backed) and are write-only in the UI.
- **Android Settings → Apps → SLE Prep → Storage → Clear data** permanently removes all progress and re-imports fresh seed content.

## Roadmap

- Production token-broker deployment for a multi-user release; usage/cost metering per Realtime session.
- Session-plan re-weighting from mock-exam results; encrypted backup/export; release signing.
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
| Database/schema errors after table changes | `dart run build_runner build --delete-conflicting-outputs`. |
| Need a clean test run | `flutter clean`, then `flutter pub get` and `flutter test`. |
