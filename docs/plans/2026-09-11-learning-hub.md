# P5 — One-place learning workspace

## Implement in this increment

1. Personal notebook: search vocabulary, add/edit/delete personal terms and examples,
   and review them with the existing spaced-repetition scheduler. Edits retain
   scheduling; deletion is confirmed; seeded content is protected.
2. Mistake recovery: revisit grammar items whose latest attempt is incorrect;
   a subsequent correct answer removes the item from the recovery queue.
3. Listening lab: original workplace lessons, Canadian-French device speech,
   comprehension questions, explanations, optional transcripts, and separately
   persisted listening results. These are practice, not official mock scores.
4. Feedback history: reopen saved oral/writing reports without another paid call.
5. Learning Hub entry points in Accueil and Réviser; free-practice planner blocks
   open the hub instead of showing an instruction-only message.
6. Confirmed course restart from Android/web settings: start week one today,
   retain completed activity and all practice history, and replace unfinished
   daily work atomically. Repeating the same-day reset is idempotent.

## Boundaries

Reuse the existing local/per-user database and encrypted-key architecture. No new
provider, paid service, cloud transcript storage, or automatic microphone capture.
Synthetic listening audio is not a replacement for real conversations or varied
speakers. Device voices may need installation or an Internet connection.

## Next increments (not implemented by this plan)

- Encrypted backup/import and explicit Android/web progress synchronization.
- Exam-date planning with weekly workload adjustment.
- A human-validated, larger listening library with multiple speakers and accents.
- A unified correction-to-flashcard workflow for AI feedback.

## Validation

Cover latest-attempt ordering, personal-card validation and due dates, schema-v5
migration without lost progress, listening content integrity, separate listening
results, playback disposal, and existing reading/grammar regressions. Run the
locked broker checks, full Flutter tests/analysis, code generation, and web build.

Level-C listening rationale: [PSC oral assessment criteria](https://www.canada.ca/en/public-service-commission/services/second-language-testing-public-service/oral-language-assessment-sle/about-the-test.html).

## Local validation evidence — 2026-09-11

- Full Flutter suite: **167 passed**, including 16 added regression tests.
- Flutter static analysis: **no issues found**.
- Drift bindings regenerated; v5-to-v6 migration preserves existing cards/settings.
- Broker locked Ruff check: passed; locked pytest suite: **34 passed**.
- Release web build, PWA finalization, and PWA validation: passed.
- Signed Android release build: passed (`build/app/outputs/flutter-apk/app-release.apk`).
- Existing non-blocking toolchain warnings remain: Drift's reference diagnostic,
  plugins' future Built-in Kotlin migration, and Starlette's test-client deprecation.
- Real-device French voice playback and course reset remain pending: no USB phone
  was detected during this pass. No installed user data was changed, and no GitHub
  push or production deployment was performed.
