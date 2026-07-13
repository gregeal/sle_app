# SLE Prep App — Phase P0 Implementation Plan

> **Archive status (2026-07-13):** P0–P3 and the PRD's OpenAI Realtime
> voice-to-voice interview are implemented. The unchecked steps below are the
> original execution plan, preserved for design history; use the root README
> for current setup, features, verification, and troubleshooting.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build P0 of the French SLE prep app from the PRD (`C:\Users\grege\Documents\My Docs\MyApp\PRD.md`) — a working, offline-capable Android "daily habit engine": 26-week curriculum planner, spaced-repetition vocabulary, SLE-style grammar drills, resource rail, and a provider-agnostic LLM adapter with settings.

**Architecture:** Flutter app (`sle_prep`) with Riverpod state management, Drift (SQLite) local-first storage, seed content shipped as validated JSON assets, and a pluggable `LlmClient` abstraction (OpenAI-compatible + Anthropic) used in P0 only for batch content generation. No backend, no accounts.

**Tech Stack:** Flutter/Dart, flutter_riverpod, drift + drift_flutter, flutter_secure_storage, http, url_launcher; dev: build_runner, drift_dev, flutter_test.

**Environment reality check (verified):** this machine has **no Flutter, no Android SDK, no adb**; Java 15 is on PATH (too old for Android Gradle — Android Studio's bundled JDK will be used instead). Task 0 is real setup work. Testing target: **physical Android phone via USB**.

---

## Repo layout (end state of P0)

```
MyApp/                          ← git repo root (init in Task 1)
  PRD.md                        ← exists
  docs/plans/2026-07-12-p0-implementation-plan.md   ← copy of this plan
  sle_prep/                     ← Flutter project
    pubspec.yaml
    assets/seed/
      curriculum.json           ← 26-week skeleton (weeks 1–4 fully authored in P0)
      vocab_core.json           ← ~300 starter cards, GoC/workplace domains
      drills_core.json          ← ~150 MCQ grammar items across P0 topics
    lib/
      main.dart                 ← entry, DB + provider bootstrap
      app.dart                  ← MaterialApp, bottom-nav shell (Today/Practice/Progress/Settings)
      data/db/database.dart     ← Drift tables + AppDatabase
      data/db/daos.dart         ← query methods per feature
      data/seed/seed_loader.dart← JSON → DB import, idempotent, schema-validated
      domain/srs/sm2.dart       ← pure SM-2 scheduler (no Flutter imports)
      domain/session/session_composer.dart ← pure daily-session builder
      domain/llm/llm_client.dart          ← abstract interface + config model
      domain/llm/openai_compatible_client.dart
      domain/llm/anthropic_client.dart
      domain/llm/prompts.dart   ← versioned prompt templates (content generation)
      features/today/today_screen.dart    ← session checklist, streak, resource rail
      features/vocab/vocab_review_screen.dart
      features/drills/drill_screen.dart
      features/progress/progress_screen.dart  ← minimal in P0: streak + counts
      features/settings/settings_screen.dart  ← LLM provider config, spend note
      providers.dart            ← Riverpod wiring (DB, DAOs, engines)
    test/
      srs/sm2_test.dart
      session/session_composer_test.dart
      seed/seed_content_test.dart
      db/dao_test.dart          ← in-memory (NativeDatabase.memory()) DB tests
      llm/openai_compatible_client_test.dart  ← mocked http.Client
```

Pure-Dart domain logic (`domain/`) never imports Flutter — it stays trivially unit-testable. UI reads it through Riverpod providers.

---

## Task 0: Development environment setup

No files — machine setup. Flutter SDK must live at a **path without spaces** (not under `My Docs`).

- [ ] Install Android Studio (latest stable) via https://developer.android.com/studio — during setup accept Android SDK, SDK Platform, and platform-tools. This also provides the bundled JDK (JBR 21), sidestepping the old Java 15 on PATH.
- [ ] Download Flutter SDK (stable channel, Windows zip) and extract to `C:\dev\flutter`; add `C:\dev\flutter\bin` to the user PATH.
- [ ] Run `flutter doctor` → accept Android licenses with `flutter doctor --android-licenses`.
- [ ] If Gradle picks up Java 15: `flutter config --jdk-dir "C:\Program Files\Android\Android Studio\jbr"`.
- [ ] Enable Developer Options + USB debugging on the phone; connect via USB; verify with `adb devices` (shows device, authorized).
- [ ] Exit criteria: `flutter doctor` shows no blocking issues for Android; `flutter devices` lists the phone.

## Task 1: Project scaffold + git

**Files:** create `MyApp\sle_prep\` (via `flutter create`), `MyApp\.gitignore`, `docs/plans/` copy of this plan.

- [ ] `cd "C:\Users\grege\Documents\My Docs\MyApp"` → `git init` → root `.gitignore` (Flutter defaults + `*.keystore`).
- [ ] `flutter create --org ca.gregeal --project-name sle_prep --platforms android sle_prep`
- [ ] Add dependencies to `pubspec.yaml`: `flutter_riverpod`, `drift`, `drift_flutter`, `flutter_secure_storage`, `http`, `url_launcher`; dev: `drift_dev`, `build_runner`. Register `assets/seed/` in the assets section.
- [ ] `flutter run` on the phone → default counter app launches (proves toolchain end-to-end).
- [ ] Commit: `chore: scaffold sle_prep flutter project` (also commit PRD.md and this plan copy).

## Task 2: Drift database schema + DAOs

**Files:** `lib/data/db/database.dart`, `lib/data/db/daos.dart`, `test/db/dao_test.dart`.

Tables (all with int PKs unless noted):

- `VocabCards`: front, back, exampleFr, domain (enum-ish text), createdAt
- `ReviewStates`: cardId FK unique, easeFactor real (default 2.5), intervalDays int, repetitions int, dueDate dateTime, lapses int
- `DrillItems`: topic text (e.g. `subjonctif`, `pronoms`), prompt, options (JSON text, 4 strings), correctIndex, explanationFr, source text (`seed`/`generated`)
- `DrillAttempts`: itemId FK, wasCorrect bool, answeredAt
- `CurriculumWeeks`: weekNumber unique, themeFr, themeEn, grammarTopics (JSON list), vocabDomain, resourceSlots (JSON list of {label,url})
- `SessionLogs`: date (date-only, unique), blocksPlanned (JSON), blocksCompleted (JSON), minutesActive int
- `AppSettings`: key text unique, value text (non-secret settings only; API keys go to secure storage)

Steps:

- [ ] Write `test/db/dao_test.dart` first against `NativeDatabase.memory()`: insert card → review state defaults created; fetch due cards by date; record drill attempt → per-topic accuracy query; upsert today's session log. Expect FAIL (tables don't exist).
- [ ] Implement tables + `AppDatabase` in `database.dart`; run `dart run build_runner build`.
- [ ] Implement DAO methods in `daos.dart`: `dueCards(DateTime now, int limit)`, `applyReview(cardId, Sm2Result)`, `randomDrillItems(topic, n)`, `recordAttempt(...)`, `topicAccuracy(topic)`, `weekByNumber(n)`, `upsertSessionLog(...)`, `currentStreak()`.
- [ ] `flutter test test/db` → PASS. Commit: `feat: drift schema and daos`.

## Task 3: Seed content + loader

**Files:** `assets/seed/*.json`, `lib/data/seed/seed_loader.dart`, `test/seed/seed_content_test.dart`.

Content is authored during this task with AI assistance and **human-reviewed** (it's Gregory's own study material — errors found in use get fixed in the JSON). P0 ships: 26-week curriculum skeleton (themes/topics for all 26; weeks 1–4 fully detailed), ~300 vocab cards (workplace/GoC domains: administration, meetings, HR, policy, connectors/discourse markers), ~150 drill items covering weeks 1–4 grammar topics (présent/passé composé vs imparfait, pronouns y/en, prepositions, futur/conditionnel intro, subjonctif triggers).

- [ ] Write `test/seed/seed_content_test.dart` first: parse each JSON asset; assert schema (required fields, exactly 4 options, correctIndex in range, 26 weeks, no duplicate card fronts, every drill topic appears in some week's grammarTopics). Expect FAIL (files missing).
- [ ] Author the three JSON files (bulk-generate with an LLM, then review; French proofread pass).
- [ ] Implement `seed_loader.dart`: on first launch (tracked via `AppSettings` key `seedVersion`), import JSON → DB inside a transaction; idempotent; bump-able version for future content updates.
- [ ] Add loader integration test with in-memory DB (import twice → no duplicates). `flutter test test/seed` → PASS.
- [ ] Commit: `feat: seed content and loader`.

## Task 4: SM-2 spaced-repetition engine

**Files:** `lib/domain/srs/sm2.dart`, `test/srs/sm2_test.dart`. Pure Dart, no imports beyond core.

Interface:

```dart
enum ReviewGrade { again, hard, good, easy } // maps to SM-2 q=1,3,4,5

class Sm2State { final double easeFactor; final int intervalDays; final int repetitions; final int lapses; ... }

Sm2State applyGrade(Sm2State s, ReviewGrade g);
DateTime nextDue(DateTime now, Sm2State s);
```

- [ ] Write `test/srs/sm2_test.dart` first: new card + `good` → interval 1; second `good` → 6; third → round(6 × EF); `again` → repetitions reset, interval 1, lapse++, EF floor 1.3; `easy` raises EF; `hard` lowers EF but keeps progress. Expect FAIL.
- [ ] Implement standard SM-2 in `sm2.dart` to make tests pass. `flutter test test/srs` → PASS.
- [ ] Wire into DAO: `applyReview` persists `applyGrade` output + `nextDue`. Re-run db tests.
- [ ] Commit: `feat: sm2 spaced repetition engine`.

## Task 5: Vocab review UI

**Files:** `lib/features/vocab/vocab_review_screen.dart`, `lib/providers.dart` additions, widget test `test/features/vocab_review_test.dart`.

- [ ] Build review flow: due-queue provider → card front (tap to flip) → four grade buttons (Encore / Difficile / Bien / Facile) → next card → session-complete summary (n reviewed, next due count). Fully offline.
- [ ] Widget test with a fake DAO: grading advances to next card; queue-empty shows summary.
- [ ] Run on phone: review 10 seeded cards end-to-end. Commit: `feat: vocab review flow`.

## Task 6: Grammar drill engine + UI

**Files:** `lib/features/drills/drill_screen.dart`, provider additions, `test/features/drill_test.dart`.

- [ ] Drill session = 10 items for the active week's topics, weighted toward the user's weakest topics (`topicAccuracy` from Task 2). MCQ → immediate right/wrong + `explanationFr` → next. Attempts recorded.
- [ ] Widget test with fake DAO: answering shows explanation; score summary at end.
- [ ] Run on phone. Commit: `feat: grammar drills`.

## Task 7: Session composer + Today screen

**Files:** `lib/domain/session/session_composer.dart`, `test/session/session_composer_test.dart`, `lib/features/today/today_screen.dart`, `lib/features/progress/progress_screen.dart`, `lib/app.dart` (bottom-nav shell).

Composer is pure Dart:

```dart
class SessionBlock { final BlockType type; final int minutes; final Map<String,dynamic> params; }
// BlockType: vocabReview, grammarDrill, reading(listening) resource, freePractice

List<SessionBlock> composeSession({
  required int weekNumber, required CurriculumWeek week,
  required int dueCardCount, required Map<String,double> topicAccuracy,
  required int targetMinutes, // 60–90 from settings
});
```

Rules (from PRD F1): vocab 10–15 min (scaled to due count), drills 15 min (weakest topics first), resource block 20 min (week's Mauril/reading slot, via url_launcher), remaining time → second drill or vocab block. Missed days don't stack — composer only ever plans *today* from current DB state (reflow is inherent).

- [ ] Write composer tests first: blocks sum ≈ targetMinutes (±10); zero due cards → no vocab block; weakest topic chosen; week resource slot included. FAIL → implement → PASS.
- [ ] Build Today screen: date + week theme, streak flame (`currentStreak()`), block checklist (tapping a block opens the feature; completing marks it in `SessionLogs`), resource rail card (curated links incl. Mauril + PSC self-assessments — static in P0).
- [ ] Progress screen (minimal P0): streak, total reviews, per-topic drill accuracy bars.
- [ ] Bottom-nav shell in `app.dart`: Today / Practice / Progress / Settings.
- [ ] Run on phone: complete a full composed session offline (airplane mode). Commit: `feat: session composer and today screen`.

## Task 8: LLM adapter + settings screen

**Files:** `lib/domain/llm/llm_client.dart`, `openai_compatible_client.dart`, `anthropic_client.dart`, `prompts.dart`, `lib/features/settings/settings_screen.dart`, `test/llm/openai_compatible_client_test.dart`.

```dart
class LlmConfig { final String baseUrl; final String model; /* apiKey via secure storage */ }
abstract class LlmClient {
  Future<String> complete({required String system, required String user, double temperature});
}
```

- [ ] Test first (mocked `http.Client`): OpenAI-compatible client hits `{baseUrl}/chat/completions` with auth header + correct body, parses choice content; error surfaces as typed exception. Same pattern for Anthropic (`/v1/messages`, `x-api-key`). FAIL → implement → PASS.
- [ ] `prompts.dart`: versioned template `generateDrillItems(topic, count, level)` → strict JSON output instruction matching the `drills_core.json` schema; reuse Task 3 validator on responses (invalid items discarded, retried once).
- [ ] Settings screen: provider preset dropdown (OpenAI / OpenRouter / Ollama-local / Anthropic / custom), base URL, model name, API key field → `flutter_secure_storage`; "Test connection" button; static monthly-cost note per PRD §6.
- [ ] "Generate more drills for this week" button on Practice tab (online-only, disabled offline) → validated items inserted with `source: generated`.
- [ ] Manual verification on phone with a real key (e.g. OpenAI): test connection OK; generate 10 items for `subjonctif`; items appear in drills. Commit: `feat: llm adapter, settings, drill generation`.

## Task 9: Polish + release build

**Files:** `android/app/...` (app name/icon), `pubspec.yaml` version.

- [ ] App display name "SLE Prep", simple launcher icon, version `0.1.0`.
- [ ] `flutter build apk --release` → install on phone (`flutter install --release`).
- [ ] Full manual pass of the daily loop in release mode + airplane mode.
- [ ] Commit + tag `v0.1.0`. Update PRD §10 P0 status.

---

## Verification (end-to-end, definition of P0-done)

1. `flutter test` — entire suite green.
2. On the physical phone, in airplane mode: open app → Today shows a composed 60–90 min session for week 1 → complete vocab review + drill blocks → streak increments; graded cards get correct next-due dates (spot-check a `good` → tomorrow, second `good` → +6 days).
3. Online: settings → real API key → test connection → generate 10 drill items → they pass validation and appear in practice.
4. Fresh install (uninstall → reinstall): seed import runs once, no duplicates (card count matches seed file).
5. `git log` shows one commit per task; tag `v0.1.0` exists.

## Notes / deferred

- P1 (reading practice, AI writing feedback), P2 (oral coach), P3 (mock exams/dashboard) get their own plans after P0 ships — per PRD §10.
- Riverpod chosen for state management (simple, testable, no codegen requirement); Drift chosen over raw sqflite for typed queries + in-memory test support.
- Project path contains spaces (`My Docs`) — Flutter tolerates this for projects; the SDK itself goes to `C:\dev\flutter` (no spaces) to avoid known tooling issues.
- Seed-content French quality is the main non-code risk: budget a review pass, and fix errors in JSON + bump `seedVersion`.
