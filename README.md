# SLE Prep / Objectif C

An Android-first Flutter app for preparing for the Canadian federal public-service Second Language Evaluation (SLE) in French. The long-term goal is C-level readiness across reading, writing, and oral interaction.

The current build is the start of the offline P0 habit engine:

- 26-week curriculum seed data
- 309 French workplace vocabulary cards
- 92 SLE-style grammar drill items
- offline spaced-repetition vocabulary review using SM-2 scheduling
- SLE-style grammar exercises with immediate explanations and weak-topic prioritization
- a 75-minute daily session plan, completion checklist, resource rail, and local progress summary
- optional AI-provider settings with encrypted Android API-key storage
- local SQLite storage; no account, server, or API key is required for the current flow

Use **Accueil** for today’s planned study blocks, **Réviser** for vocabulary or grammar, **Progrès** for local accuracy and streaks, and **Paramètres** for optional AI-provider configuration. Vocabulary and grammar work fully offline; AI generation and feedback are not connected yet.

The full product requirements, design concepts, and implementation sequence live in the repository root:

- [`../PRD.md`](../PRD.md)
- [`../docs/plans/2026-07-12-p0-implementation-plan.md`](../docs/plans/2026-07-12-p0-implementation-plan.md)
- [`../docs/design/objectif-c-ecrans-android.dc.html`](../docs/design/objectif-c-ecrans-android.dc.html)

## Prerequisites

Use a Windows machine with:

1. **Flutter 3.44.6 or newer** on the stable channel. This project requires Dart 3.12 or newer.
2. **Android Studio**, including:
   - Android SDK Platform and Build Tools
   - Android SDK Command-line Tools
   - Android SDK Platform-Tools (`adb`)
   - Android Emulator, if you want to use an emulator
3. Android Studio's bundled **JBR/JDK 17+**. The project targets Java 17.
4. Either an Android phone with USB debugging enabled or a running Android emulator.

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

### 2. Configure Android Studio and the SDK

Open Android Studio once and use **More Actions → SDK Manager** to install the items listed in the prerequisites. Then accept the Android licences:

```powershell
flutter doctor --android-licenses
flutter doctor
```

If `flutter doctor` detects an old Java installation, point Flutter at Android Studio's bundled JBR:

```powershell
flutter config --jdk-dir "C:\Program Files\Android\Android Studio\jbr"
```

Run `flutter doctor` again. Android should show no blocking issue before you try to build the app.

#### Fix: Android SDK Command-line Tools missing

If `flutter doctor` reports either **`cmdline-tools component is missing`** or **`Android sdkmanager not found`**, Flutter can see the Android SDK but cannot accept licences or build Android apps yet.

In Android Studio, open **More Actions → SDK Manager** (or **Tools → SDK Manager** when a project is open), then choose the **SDK Tools** tab. Select and apply these components:

- **Android SDK Command-line Tools (latest)** — required
- Android SDK Platform-Tools
- Android SDK Build-Tools
- Android Emulator — optional, for an emulator

Wait until Android Studio finishes the installation. The following command should then return `True`:

```powershell
Test-Path "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat"
```

Configure Flutter with the SDK location from Android Studio. The usual Windows location is shown below; replace it only if SDK Manager shows a different path:

```powershell
flutter config --android-sdk "$env:LOCALAPPDATA\Android\Sdk"
flutter doctor --android-licenses
flutter doctor
```

Accept every licence prompt with `y`. Do **not** use `C:\Program Files\Android\Android Studio\jbr` as the Android SDK path: it is Android Studio's Java runtime, not the Android SDK.

> **PowerShell tip:** If the prompt changes from `PS ...>` to `>>`, PowerShell is waiting for an unfinished command—usually a missing closing quote. Press `Ctrl+C`, then rerun the complete command above. Do not copy the `PS>` or `>>` prompt characters themselves.

### 3. Choose a device

#### Physical Android phone

1. On the phone, enable **Developer options** and **USB debugging**.
2. Connect it by USB and accept the debugging prompt on the phone.
3. Verify that Flutter can see it:

   ```powershell
   adb devices
   flutter devices
   ```

If `adb devices` shows `unauthorized`, unlock the phone and accept the RSA fingerprint prompt. If it shows no device, install the phone manufacturer's Windows USB driver, reconnect the cable, and try again.

#### Android emulator

In Android Studio, open **Device Manager**, create a phone emulator, and start it. Then run:

```powershell
flutter devices
```

## Run the app

Run these commands from the Flutter project directory:

```powershell
cd "C:\Users\grege\Documents\My Docs\MyApp\sle_prep"
flutter pub get
flutter analyze
flutter test
flutter run
```

If more than one device is connected, select one explicitly:

```powershell
flutter devices
flutter run -d <device-id>
```

Keep `flutter run` open while developing:

- Press `r` for hot reload after a UI change.
- Press `R` for a full hot restart.
- Press `q` to stop the app.

On first launch, the app imports its bundled curriculum, vocabulary, and drills into its on-device database. This can take a moment; subsequent launches do not duplicate the content.

## Run checks

Before committing a change, run:

```powershell
cd "C:\Users\grege\Documents\My Docs\MyApp\sle_prep"
flutter analyze
flutter test
```

The tests cover the Drift data layer, SM-2 scheduling, seed-content validation/import, and the vocabulary-review interaction.

If you change a Drift table in `lib/data/db/database.dart`, regenerate the checked-in database code before testing:

```powershell
dart run build_runner build --delete-conflicting-outputs
flutter test
```

## Build an APK

Create a debug APK for a connected phone or manual installation:

```powershell
flutter build apk --debug
```

Output:

```text
build\app\outputs\flutter-apk\app-debug.apk
```

For a release-mode test on a connected device:

```powershell
flutter build apk --release
flutter install --release
```

> The current Gradle configuration signs release builds with the debug key so local release-mode testing works. Before distributing an APK, configure a real Android release keystore and signing configuration. Do not distribute a debug-signed release build.

## Data and reset behaviour

- Progress and scheduling data are stored locally in SQLite on the device.
- The bundled seed content imports once, tracked by a local `seedVersion` setting.
- No account or network connection is needed for vocabulary review.
- Clearing the app's storage in **Android Settings → Apps → sle_prep → Storage → Clear data** permanently removes your progress and imports fresh seed content on the next launch.

## Current scope and next work

Implemented now:

- local database and seed import
- SM-2 vocabulary scheduling
- vocabulary review UI
- SLE-style grammar-drill UI with explanations and persisted accuracy
- daily session composer, block completion log, resource links, and progress summary
- locally stored AI-provider configuration; API keys use encrypted device storage

Next in the P0 plan:

1. OpenAI-compatible and Anthropic request adapters, including connection tests
2. Validated generation and insertion of new grammar drills
3. On-device/phone validation and release signing

Reading, writing feedback, the oral coach, mock exams, backups, and release signing are planned later phases. The current app does **not** make official SLE level claims.

## Project layout

```text
sle_prep/
├── assets/seed/              Bundled curriculum, vocabulary, and drill JSON
├── lib/
│   ├── data/db/              Drift tables and query helpers
│   ├── data/seed/            Validated one-time seed importer
│   ├── domain/srs/           Pure SM-2 scheduler
│   ├── domain/session/       Pure daily-session composer
│   └── features/             Today, practice, progress, settings, and drills
├── test/                     Database, seed, scheduler, and widget tests
└── android/                  Android launcher and Gradle project
```

## Troubleshooting

| Problem | What to do |
|---|---|
| `flutter` is not recognized | Add `C:\dev\flutter\bin` to `Path`, open a new terminal, and run `flutter --version`. |
| `flutter doctor` reports Android licences | Run `flutter doctor --android-licenses`, accept each licence, then rerun `flutter doctor`. |
| `cmdline-tools component is missing` or `sdkmanager not found` | Install **Android SDK Command-line Tools (latest)** in Android Studio's **SDK Tools** tab, then rerun the three commands in [Fix: Android SDK Command-line Tools missing](#fix-android-sdk-command-line-tools-missing). |
| Java version is too old | Run `flutter config --jdk-dir "C:\Program Files\Android\Android Studio\jbr"`. |
| No Android device is found | Start an emulator or reconnect an unlocked USB-debugging-enabled phone; check `adb devices`. |
| `flutter pub get` fails | Confirm internet access, then run `flutter pub get` again from the `sle_prep` directory. |
| Database/schema errors after table changes | Run `dart run build_runner build --delete-conflicting-outputs`. |
| You need a clean test run | Run `flutter clean`, then `flutter pub get` and `flutter test`. |
