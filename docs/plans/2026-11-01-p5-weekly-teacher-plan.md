# P5 — Weekly AI Teacher: Implementation Plan

**Goal:** Add a weekly teaching cadence on top of the existing course material: every week the AI teacher gives a class, assigns a week of exercises covering all four language skills with speaking deliberately dominant, and closes the week with a review that shapes the next one.

**Status:** Planned (2026-11-01). Nothing below is implemented yet.

**Decisions taken with the owner:** hybrid class (text + TTS teaching, then a live voice practice segment); 5 study days × 60 min (~5 h/week); a placement class picks the starting track; the weekly plan gets its own tab *and* becomes the source of truth for the Accueil daily plan.

---

## 1. What the review found

The app is in good shape and already contains almost all the raw material this feature needs. Five findings shaped the design.

**1.1 Two disconnected products.** `composeSession` in `lib/domain/session/session_composer.dart` still builds the original P0 day: spaced-repetition vocabulary, grammar drills, one resource link, free practice. It has no knowledge of the course tracks. Meanwhile `lib/domain/course/` holds two full tracks (A→B and B→C, 8 modules and 16 lessons each) where every lesson already carries teaching notes, examples, key phrases, a quiz, a writing exercise with a model answer, a speaking task and rubric criteria — plus a `CourseWorkshop` with a reading passage, a listening passage and a writing task. **The richest content in the app is invisible to the home screen.** This is the structural reason the weekly feature is needed, and why the weekly plan should drive Accueil.

**1.2 Course progress is not queryable.** `CourseProgress` is serialised as JSON into `AppSettings` under `course:<track>:<lesson>`. That is a reasonable choice for per-lesson reads and it avoided migrations, but nothing can aggregate it: there is no way to ask "how many minutes of speaking did I do this month" or "which skill is lagging". A weekly plan needs per-day, per-skill rows, so the new tables are relational and the existing `CourseProgress` is left untouched.

**1.3 Listening is the weakest of the four skills.** `listening_lessons.dart` is a fixed catalog of synthetic-speech passages with negative IDs, plus one listening passage per course workshop. There is no rotation, no generation and no spaced review. Since the request is explicitly "all 4 components", listening gets a first-class slot in every week.

**1.4 Lesson completion is all-or-nothing.** `_courseUpdate` only marks a lesson complete when read + full-marks quiz + all three rubric criteria + both comprehension answers + a revised draft all land, and `completeCourseRecall` demands the whole set again. That is fine for a self-paced library but brittle as a weekly obligation: one missed element blocks the week. The weekly layer therefore tracks **per-assignment** completion and never blocks the week on a single item.

**1.5 Everything else needed already exists and is reusable.** Realtime voice (`OpenAiRealtimeVoiceSession`, with the SDP newline fix in place), speaking sessions with turn-level mistake tracking, the writing coach, reading generation, device TTS, the validated-JSON-with-retry pattern used by `oral_coach.dart` and `writing_coach.dart`, and the `AiGateway` split that keeps Android and web honest. The weekly layer composes these rather than reimplementing them.

## 2. The weekly loop

```
Placement class (once)
      │
      ▼
  Week N  ──▶  Class day      teaching (text + TTS, offline) → quiz →
      ▲                       live voice practice → teacher assigns the week
      │                            │
      │                            ▼
      │       Days 2–5        assignments across 4 skills, speaking-dominant
      │                            │
      │                            ▼
      └────── Weekly review   evidence → teacher report → next week adapts
```

Each week is bound to one course lesson from the active track, in order. The class teaches that lesson; the assignments practise it across the four skills; the review measures it and decides the emphasis of the following week.

## 3. The time contract (the heart of the request)

Budget: **5 days × 60 min = 300 min/week.** The composer is a pure function that must satisfy these invariants, and the tests assert the invariants rather than one hard-coded timetable:

| Component | Share of the week | Minutes (of 300) |
|---|---|---|
| **Speaking** | **40–50 %** (target 42) | **~126** |
| Listening | 12–20 % | ~42 |
| Reading | 12–20 % | ~42 |
| Writing | 12–20 % | ~48 |
| Teaching + quiz | ≤ 8 % | ~15 |
| Vocabulary consolidation | 5–12 % | ~27 |

Additional invariants:

- Speaking is never below 40 % and is always the largest single share.
- Listening, reading and writing are "well distributed": no two of them differ by more than 8 percentage points in the same week.
- **Every study day contains at least one speaking block.**
- No day exceeds its target by more than 10 %; totals land on the budget exactly after integer rounding.
- Adaptation (§6) may shift weights inside these bands but can never break them.

A representative week (the composer produces shapes like this):

| Day | Blocks | Minutes |
|---|---|---|
| 1 — Classe | teaching + quiz 15 · live speaking practice 20 · listening 15 · vocab 10 | 60 |
| 2 | speaking task 26 · reading workshop 24 · vocab 10 | 60 |
| 3 | speaking conversation 30 · writing draft 25 · vocab 5 | 60 |
| 4 | speaking task 25 · listening 27 · vocab 8 | 60 |
| 5 | speaking recap 25 · writing revision 23 · reading check 12 | 60 |

## 4. The class itself (hybrid)

`WeeklyClassScreen` runs four segments, gated in order but resumable:

1. **Explication** — objective, teaching points, simple and developed examples, key phrases, drawn from the bound `CourseLesson`. Rendered as text with a play button that speaks it through the existing device TTS. Works fully offline.
2. **Vérification** — the lesson's existing MCQ quiz via `courseQuizScore`. Formative: a wrong answer explains, it does not block.
3. **Pratique guidée en direct** — a Realtime voice segment with a new *teacher* persona (distinct from the existing ELO *examiner* persona): it drills the week's target structures, corrects gently in the moment, and keeps its turns short so the learner speaks far more. Budgeted at ~20 min, once per week. Falls back to the existing manual-turn / device-STT path when Realtime is unavailable, so the class never dead-ends.
4. **Devoirs** — the generated week is shown as a checklist and persisted; the teacher introduces it in one short spoken paragraph.

Teacher prompts live in `weekly_class_prompt.dart`, versioned like `realtimePromptVersion`, and carry the same prompt-injection isolation already used by `writing_coach.dart` (learner text is encoded data, never instructions).

## 5. Data model (schema v8)

Two new tables; migration `from < 8` creates them and touches nothing else.

- **`StudyWeeks`** — `id`, `weekNumber`, `trackId`, `lessonId`, `startDate` (date-only), `status` (`active` | `closed`), `planJson` (the composed plan snapshot, so a week never silently re-plans under the learner), `reportJson` (nullable), `createdAt`.
- **`WeeklyAssignments`** — `id`, `weekId` FK, `dayIndex` (1–5), `skill` (`speaking` | `listening` | `reading` | `writing` | `vocabulary` | `teaching`), `minutes`, `title`, `payloadJson` (what to open and with what argument), `completedAt` (nullable), `evidenceKind` + `evidenceId` (nullable: speaking session, writing attempt, reading attempt, listening attempt).

Placement result and the active-week pointer stay in `AppSettings` (`placement:v1`, `weekly:activeWeekId`) — single values, no table needed.

## 6. Review and adaptation

At the end of the week (or on demand) the teacher produces a report from **evidence already in the database**: quiz score, reading/listening accuracy, writing feedback levels, speaking mistakes by category, and assignment completion. The report is strict validated JSON — the same parse → validate → retry → persist discipline as `oral_coach.dart`: per-skill level estimate, two strengths, three priorities, and a recommended emphasis for next week. Invalid output is retried once and never persisted half-parsed.

Next week's composer receives that emphasis and shifts minutes **within** the bands of §3 — a weak skill moves toward its 20 % ceiling, a strong one toward its 12 % floor, and speaking stays dominant regardless.

**Carry-over policy:** a missed day does not stack. At most one catch-up slot is offered on the following day; the week still closes on schedule. This preserves the P0 principle that the plan must never become an impossible backlog.

## 7. Files

**New**
- `lib/domain/weekly/weekly_plan.dart` — pure: `SkillKind`, `WeeklyAssignmentSpec`, `WeeklyPlan`, `composeWeeklyPlan(...)` implementing the §3 contract.
- `lib/domain/weekly/weekly_class_prompt.dart` — versioned teacher prompts.
- `lib/domain/weekly/weekly_report.dart` — report model + validated parser.
- `lib/domain/weekly/placement.dart` — placement model, prompt, validated parser.
- `lib/data/db/weekly_daos.dart` — create week, read today's assignments, mark complete with evidence, close week, aggregate per-skill minutes.
- `lib/features/weekly/weekly_home_screen.dart` — the "Classe" tab.
- `lib/features/weekly/weekly_class_screen.dart` — the four class segments.
- `lib/features/weekly/weekly_report_screen.dart` — end-of-week report.
- `lib/features/weekly/placement_screen.dart` — the placement class.

**Modified**
- `lib/data/db/database.dart` — two tables, `schemaVersion` 7 → 8, migration step.
- `lib/providers.dart` — `activeStudyWeekProvider`, `todayAssignmentsProvider`; `todayPlanProvider` prefers weekly assignments and falls back to `composeSession` when no week is active (back-compatible).
- `lib/app.dart` — add the "Classe" tab (Accueil · Classe · Réviser · Coach · Progrès, with Paramètres reachable from Accueil to keep the bar at five).
- `lib/features/today/today_screen.dart` — render the day from assignments, each tapping through to the existing feature screen.
- `lib/features/progress/progress_screen.dart` — per-skill minutes this week against the contract, so the speaking-dominant split is visible.
- `PRD.md` — new section 15 (below).

## 8. Requirements upgrade (PRD §15)

The current PRD specifies a 26-week curriculum and a 60–90 min day but never states how the four skills are balanced, what a week owes the learner, or when a level is considered reached. Section 15 adds:

- **Weekly pedagogical contract** — teach, practise, produce, review every week; the skill-time envelope of §3 as a numbered requirement.
- **Four-skill coverage** — listening promoted to a first-class component with a guaranteed weekly slot, not a link to an external site.
- **Progression gates** — a module advances when its lessons' assignments are done and the report shows no skill below the module's target level twice in a row; A→B graduates to B→C on sustained B-level evidence, recorded with its reasoning.
- **Carry-over and recovery** — the explicit no-backlog rule.
- **Honesty** — level estimates stay unofficial everywhere, including the new report and the placement.
- **Availability** — teaching, reading, listening, writing drafts and vocabulary work offline; only the live segment, generation and reports need the network.
- **Cost** — one live voice segment per week by default, so the weekly cadence adds a small, predictable amount to the existing budget.

## 9. Tasks

1. **P5-1 Schema v8 + DAOs** (TDD) — tables, migration from 7 (and from 1), DAO round-trips, completion with evidence, per-skill aggregation.
2. **P5-2 Weekly composer** (TDD) — pure `composeWeeklyPlan`; tests assert every invariant in §3 including the speaking floor, the distribution bound, the daily-speaking rule, determinism for a given week, and correct behaviour under adaptation emphasis.
3. **P5-3 Placement** — screen, prompt, validated parse, track selection recorded with its reasoning; creates week 1.
4. **P5-4 Class screen** — four segments, TTS teaching, quiz reuse, live practice with teacher persona + fallback, assignment hand-off.
5. **P5-5 Accueil integration** — weekly-driven day with legacy fallback; tap-through to existing feature screens; completion recorded from real evidence.
6. **P5-6 Weekly review** — report generation, validation, persistence, next-week adaptation; Progrès shows the week's skill split.
7. **P5-7 Docs + ship** — PRD §15, README, full suite, release build, install, push.

## 10. Verification

- `flutter analyze` clean; full suite green (currently 136 tests) plus the new composer, DAO, parser and widget tests.
- Migration: a database at v7 (and one at v1) upgrades with existing course progress, speaking history and mock results intact.
- Contract: property-style tests over many generated weeks assert the speaking share never drops below 40 %, the three other skills stay within 8 points of each other, and every day has a speaking block.
- On device: placement → week 1 class (teaching audio offline, quiz, live practice, assignments) → a day's work from Accueil → week closes with a report → week 2 reflects the report's emphasis.
- Offline: aeroplane mode still gives teaching, reading, listening, writing drafts and vocabulary.

## 11. Risks

| Risk | Mitigation |
|---|---|
| A weekly obligation feels heavier than the old free-form day | No-backlog rule, one catch-up slot, the week closes on time; the class day is 60 min like any other |
| Live segment unavailable (network, quota, Realtime outage) | Fallback to manual-turn / device-STT practice; the class completes without it and the report notes reduced speaking evidence |
| Teacher persona drifts into examiner behaviour | Separate versioned prompt, explicit "teach and correct gently, do not grade" instruction, tested prompt builders |
| Report JSON invalid or injected | The existing validated-parse → retry → never-persist-partial discipline; learner text encoded as data |
| Two plans confuse the learner | Weekly becomes the single source of truth for Accueil; the legacy composer only runs when no week is active |
