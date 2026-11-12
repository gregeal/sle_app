# P6 — Habit first, then fluency

Date: 2026-11-11
Status: P6-0 and P6-1 implemented (schema v10); P6-2 onward not started
Scope: `sle_prep/` (Android + web). The broker needs one small change (P6-2).

## 1. What the owner told us

| Question | Answer |
|---|---|
| Oral level today | A or low B |
| Where is the plateau | All four skills |
| Test date | None booked |
| Real usage since the Nov 1 install | A handful of times |
| Why the app stays closed | "I forget / no trigger" |
| What breaks when speaking | Can't find words; nerves / freeze |
| AI budget | About $60 / month |
| French outside the app | Employer group class, 6 learners, 2 × 1 h / week |

Extra requests: advice on a second tutor, work-life balance, and finding the
best time of day to study.

## 2. Diagnosis

1. **This is an under-dosing problem before it is a method problem.** A
   handful of sessions in ten days cannot produce a plateau; there is not yet
   enough practice to plateau on. The first job of the product is to get
   opened every day. Everything else is secondary.
2. **The product is aimed at the wrong milestone.** The app is "Objectif C";
   the learner is A / low B. The next honest milestone is a solid oral B.
   C stays the destination, not the next step.
3. **The app asks for 60 minutes and delivers about 5 minutes of material.**
   Each lesson has one ~45-word reading passage with one question and one
   ~40-word listening script with one question. The weekly plan schedules
   36–60 minutes for each of those skills, and every reading block in a week
   reopens the same passage. A learner who does open the app runs out of
   things to do, then self-declares the rest.
4. **Real speaking time is tiny.** A 6-person class gives roughly 5–8 minutes
   of individual speaking per hour: about 15 minutes a week. The app caps
   live voice at 20 minutes a week. Word-finding and nerves only improve with
   many low-stakes speaking minutes, so this is the constraint to remove.
5. **Nothing calls the learner back.** No notifications, no reminder, no
   widget. The streak resets every weekend by construction, so it never
   builds the pull it is supposed to.

## 3. Code review findings

Ranked by impact on a learner. Line numbers are as of commit `ecee488`.

### Bugs

| # | Finding | Where | Fix |
|---|---|---|---|
| B1 | **A crash burns the week's live voice.** An unsettled lease is counted at its full reservation (`usedSeconds ?? reservedSeconds`), and a lease reserves *all* remaining seconds. If the app is killed mid-call, the rest of the weekly allowance is gone. The screen text promises a "réconciliation" that does not exist. | `lib/data/db/weekly_daos.dart:582-591` | Checkpoint elapsed seconds every 15 s; on next reserve, settle any open lease at its last checkpoint. |
| B2 | **Long answers are cut when the screen sleeps.** No wake lock is held during a voice session, and `paused` mutes the microphone. With a 30 s screen timeout, any answer longer than that is truncated. Needs confirmation on the S22 but the code path is unambiguous. | `lib/features/coach/realtime_interview_screen.dart:98` | Hold a wake lock (`wakelock_plus`) while a session is connected. |
| B3 | **The streak resets every weekend.** `currentStreak` walks back day by day and stops at the first empty day, but two days a week are scheduled rest days. | `lib/data/db/daos.dart:437` | Skip days that were not scheduled study days. |
| B4 | **"Study time" is fictional.** Total minutes adds the *planned* minutes of completed blocks, not observed time. A 40-minute block finished in 3 minutes counts as 40. Practice done from Coach or Réviser counts for nothing, in minutes or streak. | `lib/data/db/daos.dart:542` | Sum `observedSeconds` from evidence; log every activity, planned or not. |
| B5 | **Every reading/listening block of a week is the same passage.** All blocks of a skill share one payload and one workshop entry. | `lib/domain/weekly/weekly_plan.dart:707`, `lib/features/weekly/weekly_assignment_screen.dart:221` | Per-occurrence content (P6-3). |
| B6 | **Closing a week is one tap and irreversible.** No confirmation; evidence freezes immediately. | `lib/features/weekly/weekly_home_screen.dart:478` | Confirm dialog stating what freezes. |
| B7 | **Catch-up only sees yesterday.** A block missed two days ago can never be swapped in. | `lib/features/weekly/weekly_home_screen.dart:420` | Consider every earlier incomplete block. |
| B8 | **No backup.** `allowBackup="false"` and no export. The Nov 1 reinstall wiped all history; a phone change would do the same six months in. | `android/app/src/main/AndroidManifest.xml:23` | JSON export/import (P6-5). |
| B9 | **The teacher is labelled "Évaluatrice".** Class mode reuses the examiner's bubble label and the "Analyse des cinq dimensions…" spinner. | `lib/features/coach/realtime_interview_screen.dart:824,861` | Mode-aware labels. |
| B10 | **The legacy plan stops at week 26** and three planning systems overlap (26-week daily plan, course library, weekly class). Réviser still shows the legacy week theme while the weekly class runs a different lesson. | `lib/providers.dart:243` | Retire the legacy plan from navigation once a weekly plan exists; keep its data. |

### Efficiency and quality

- `AppSettings` is used as a general store for drafts, feedback caches,
  leases and catch-up markers. It grows without bound and every key is a
  string contract. Move drafts and caches to typed tables with a cleanup rule.
- `currentStreak` and `totalActiveMinutes` load whole tables. Fine today,
  linear forever. Replace with an `activity_log` table (P6-1) and aggregate
  queries.
- `SwitchListTile` in `weekly_home_screen.dart` builds a new `Future` on every
  rebuild. Use a provider.
- Raw exception text (`'$e'`) is shown to the learner in several weekly
  screens. Map to learner-facing messages.
- Grammar drills are picked at random from 92 items (2–10 per topic). Missed
  items are not prioritised and repeats arrive within days.
- No indices on `drill_attempts(item_id)`, `review_states(due_date)`,
  `weekly_evidence(assignment_id)`. Add with the next schema bump.

### What is solid and should not be touched

Validated-JSON-with-retry on every LLM call; prompt-injection isolation;
ephemeral Realtime secrets; the migration chain (now tested v1→v9); evidence
typing; the pure-Dart domain layer; honest "non officiel" labelling.

## 4. Product decisions

| Decision | Choice | Why |
|---|---|---|
| Next milestone | **Solid oral B**, then C | Matches the learner's level; C in six months from A/low B at 4–5 h a week is not realistic. |
| Default session | **20 minutes**, with a 5-minute floor | "I forget" plus an unbooked hour means zero. A small session done daily beats a large one skipped. |
| Weekly contract | 6 days, one full day off | Protects work-life balance and makes the streak achievable. |
| Speaking share | Keep 40–50 %, but **most of it live** | Word-finding and nerves need real-time production, not typed reflection. |
| Live voice allowance | **75 min / week**, metered | Fits ~$60 / month with margin; the meter replaces guessing. |
| Content | Generated per week and cached, plus curated external input | Fills the time the plan schedules; authentic audio is the only route to listening comprehension. |
| Self-declared blocks | Kept, but never count as speaking evidence | Honest metrics. |
| Legacy 26-week plan | Hidden once a weekly plan exists | One plan, one home screen. |

## 5. Features

### Answering "should it include links, dictation, videos, writing?"

| Feature | Verdict | Skill it moves |
|---|---|---|
| **Dictée** (hear a sentence, type it, see a diff) | Yes, high value at A/B | Listening, spelling, agreements — directly feeds the written-expression test |
| **Shadowing** (hear, repeat, compare) | Yes | Word-finding, pronunciation, nerves |
| **External articles / audio / video** with a task attached | Yes, link out only | Listening, reading, vocabulary |
| **Short daily writing** with correction | Yes, 5 sentences | Grammar accuracy |
| **Exam-format written-expression drills** | Yes | The actual test format |
| Long free composition | No | The SLE written test is multiple choice, not an essay |
| Embedded video player / scraping | No | Legal and maintenance cost; a link plus a task does the job |

External sources to curate (all free, all link-out): Mauril (CBC/Radio-Canada,
built for learners), TV5MONDE Apprendre, RFI Français facile, Radio-Canada
Ohdio, the Language Portal of Canada quizzes, bilingual canada.ca pages for
parallel reading, ONF/NFB films. Each item carries a level, a duration and a
**task** — "listen twice, then give the teacher a 60-second summary" — so
input always ends in output.

## 6. Implementation plan

Each task ships with tests and leaves `flutter analyze` clean and the suite
green. Order is by impact on daily use.

### P6-0 · Stop the leaks (1–2 days)

Fix B1, B2, B3, B4, B6, B7, B9. No schema change except B1's checkpoint
column (`weekly_voice_leases.checkpoint_seconds`, schema v10).

Done when: a killed voice session costs only the seconds actually used; a
90-second answer survives a 30-second screen timeout on the S22; a
Friday-to-Monday streak survives the weekend; minutes shown equal minutes
observed.

### P6-1 · Habit engine (3–4 days)

1. **Reminders** — `flutter_local_notifications`, exact-time daily reminder at
   the learner's chosen slot, skipped on rest days and once the day's minimum
   is done. A second, gentler nudge 3 h later if still untouched. Web: none
   (document it).
2. **One-button home** — Accueil becomes a single primary action:
   "Commencer · 20 min". Below it, the day's three blocks. Everything else
   moves behind "Plus".
3. **Session ladder** — 5 / 20 / 40 minutes chosen at start. The 5-minute
   floor (vocabulary + one spoken answer) keeps the streak alive on bad days.
4. **Rest-aware streak and real minutes** — new `activity_log` table
   (`id, startedAt, endedAt, kind, skill, source`); every activity writes a
   row, including Coach and Réviser.
5. **Mon créneau** — onboarding asks wake time, work hours, class days. For
   two weeks the app records start time and completion for every session,
   then reports "you finish 80 % of 7:15 sessions and 20 % of 21:00 sessions"
   and moves the reminder.
6. **Class-day awareness** — on group-class days the plan shrinks to a
   10-minute pre-class warm-up and a 5-minute post-class capture.
7. **Weekly check-in** — Sunday-evening (or chosen day) 3-minute review:
   minutes by skill, sessions kept vs planned, one adjustment for next week.

Schema v10: `activity_log`, `study_schedule` settings, lease checkpoint.

### P6-2 · Speaking that fits the two stated problems (4–5 days)

For "can't find words":
1. **Chunk bank** — each lesson's phrases become spoken cloze cards: hear the
   situation, say the chunk aloud, STT checks it. Words are learned as usable
   pieces, not as translations.
2. **Circumlocution drill** — "décris sans dire le mot": the teacher names an
   object or idea; the learner describes it. Trains the escape route for a
   missing word.
3. **4-3-2** — the same topic for 4 minutes, then 3, then 2. The classic
   fluency drill; the app times it and shows words per minute each round.

For "nerves / freeze" — a graduated ladder, each rung unlocked by doing the
previous one a few times:
1. Shadowing alone (no listener).
2. Push-to-talk conversation with the teacher (today's mode).
3. **Hands-free conversation** — server VAD (`semantic_vad`, low eagerness)
   so turns flow like a real exchange. Needs the broker to allow the
   `turn_detection` override on web.
4. **Transcript hidden** — listen without reading.
5. Simulated interview (existing).

Also: raise the weekly live allowance to a configurable 75 minutes with a
**spend meter** (seconds used × published rate, shown in Settings and on the
practice screen), and **fluency metrics** per session (words per minute,
filler rate, mean answer length) charted over time.

### P6-3 · Enough input to fill the time (4–5 days)

1. **Weekly content pack** — when a week opens, generate and cache 4 reading
   passages (120–250 words, 3–4 questions each) and 4 listening scripts at
   the track's level, through the existing validated-JSON pipeline. Each
   reading/listening block gets its own item (`payload.occurrence`). Offline
   fallback: the current single workshop passage.
2. **Natural audio** — listening scripts and dictée use OpenAI TTS voices
   (cached as files) instead of the device robot voice; device TTS stays the
   offline fallback. Speed control 0.8× / 1×.
3. **Dictée** — sentence by sentence, replay allowed, word-level diff,
   misspelt words offered to the vocabulary deck.
4. **Shadowing** — play, record, STT compare, replay both.
5. **Bibliothèque** — curated external items (source, level, minutes, task).
   Opening one starts a timer; returning prompts the spoken or written task,
   which is what earns the evidence.

### P6-4 · Written expression in the real format (2–3 days)

1. Two exam-format item types: fill-in-the-blank and error identification.
2. Grow the bank per topic with the drill generator (already validated) to
   at least 30 items per topic.
3. **Missed-item review** — wrong answers enter SM-2, like vocabulary. Random
   selection is replaced by "due mistakes first, then new".
4. Daily 5-sentence writing with correction; each correction can become a
   review item.

### P6-5 · Proof of progress and safety (2–3 days)

1. **Monthly benchmark** — the same three prompts recorded on the 1st of each
   month, audio kept on device, played side by side. The answer to "I don't
   feel I'm improving" is hearing September next to December.
2. **Can-do checklist** per level (B: narrate a past event, compare two
   options…), ticked from evidence, not self-report.
3. **Backup** — export/import one JSON file (everything except secrets).
4. Progress screen shows the next milestone as "B oral", with C beyond it.

### P6-6 · Group-class companion (1–2 days)

1. After each class: 2-minute capture — what was covered, corrections the
   teacher gave. Typed or dictated.
2. The next two days' practice reuses it: the teacher persona is told the
   class topic and the learner's noted errors.
3. Before each class: a 10-minute warm-up on the previous class's material
   plus one sentence prepared to say first.

### Sequence and effort

| Order | Task | Days | Why here |
|---|---|---|---|
| 1 | P6-0 | 1–2 | Removes the reasons a session fails once started |
| 2 | P6-1 | 3–4 | Nothing else matters until the app is opened daily |
| 3 | P6-2 | 4–5 | Attacks the two named speaking problems |
| 4 | P6-3 | 4–5 | Fills the time honestly; fixes listening |
| 5 | P6-5 | 2–3 | Backup before real history accumulates |
| 6 | P6-4 | 2–3 | Test-format accuracy |
| 7 | P6-6 | 1–2 | Leverage on the class already paid for |

## 7. The learner's side

### A week that fits around work

Target: about 2 h 15 in the app plus the 2 h of class. One full day off.

| Day | App | Minutes |
|---|---|---|
| Class day 1 | Pre-class warm-up; post-class capture | 10 + 5 |
| Class day 2 | Same | 10 + 5 |
| Three other weekdays | Live conversation 10 · listening or dictée 7 · vocabulary 3 | 20 each |
| Saturday | Reading + short writing + weekly check-in | 35 |
| Sunday | Off | 0 |

Rules: the 5-minute floor always counts; never miss two days in a row; no
making up missed days.

### Finding the best time

Speaking needs privacy; listening does not. So split them: listening and
vocabulary on a commute or a walk, speaking where nobody is listening. Run a
two-week experiment — week 1 before work, week 2 at lunch — and let Mon
créneau's completion rate decide. Until that exists, pick the slot attached to
something that already happens every day (first coffee, the drive in) and set
a phone alarm.

### A second tutor?

Keep the group class; it gives structure and a human audience. Its weakness
is speaking time — about 15 minutes a week. Close that gap in this order:

1. Daily live conversation in the app (cheap, private, removes the fear of
   being judged).
2. After four weeks of that, add **one 30-minute one-to-one session a week**
   with a human tutor. The freeze happens with a human listening, so part of
   the cure has to be a human listening. Ask the employer first whether
   individual language training is available; otherwise a private online
   tutor is enough.
3. Use the class better: prepare one thing to say, volunteer first, and ask
   the teacher for your three most frequent errors.

### Breaking the plateau

1. Dose before method: four weeks of daily contact before judging anything.
2. Speak every day, even for five minutes, even badly.
3. Learn chunks, not words: "il faudrait que je…", "ce qui m'inquiète,
   c'est…". Retrieval of a whole phrase is what feels like fluency.
4. When a word is missing, describe it. Never stop and never switch to
   English.
5. Narrow the field: ten work topics, repeated until they are easy.
6. Listen to the same short clip three times before reading the transcript.
7. Keep five active errors at most; retire one before adding another.
8. Measure monthly, not daily.

### A timeline without a deadline

The owner asked for a timeframe that does not create pressure. These are
estimates from typical classroom-hour figures, not promises, and nothing in
the app counts down to them.

| Stage | Roughly | What "done" means |
|---|---|---|
| 1 · Install the habit | 4 weeks | Showing up on most planned days. No level goal at all. |
| 2 · Solid oral B | 9–12 months | Narrating, explaining and comparing on familiar work topics without freezing. |
| 3 · Toward C | A further 12–18 months | Opinions, hypotheses and nuance on unprepared topics. |

At about 4.5 hours of French a week (2 h of class, 2 h 15 in the app) that is
roughly 230 hours a year. More dose later (a weekly one-to-one, more
listening) shortens stages 2 and 3; nothing shortens stage 1.

Rules that keep it sustainable:

- The goal for any single day is five minutes. Everything above that is a
  bonus, not a debt.
- A missed day is not made up. A missed week is reviewed, not punished.
- Progress is judged monthly, by the benchmark recording (P6-5), never daily.
- Book the test only after stage 2 feels true in real conversations.

## 8. Verification

- P6-0: unit tests for lease settlement after a simulated kill, rest-aware
  streak across a weekend, observed-minute totals; device check of a
  90-second answer with a 30-second screen timeout.
- P6-1: notification scheduling logic tested as pure Dart (next fire time
  given schedule, rest days, completion); migration test v9→v10.
- P6-2/3: generators covered by the existing validate-and-retry tests;
  content pack falls back to the bundled workshop when offline.
- All: `flutter analyze` clean, full suite green, release build installed on
  the S22 before each push.

## 9. Risks

| Risk | Mitigation |
|---|---|
| Notifications get ignored after a week | Slot chosen from the learner's own completion data; reminder text names the 5-minute floor |
| Live voice overspends | Hard weekly cap, visible meter, lease checkpointing (B1) |
| Generated content has errors | Same validation as drills; a "signaler" button removes an item from the pack |
| Scope: seven tasks | P6-0 and P6-1 alone solve the stated blocker; stop there and measure two weeks before continuing |

## 10. Delivered in P6-0 and P6-1

- Voice leases: heartbeat every 15 s, reconciled at the last checkpoint after
  60 s of silence (B1). Wake lock on all speaking screens (B2).
- Streak skips scheduled rest days (B3). `activity_logs` records measured
  time from every study screen; totals no longer credit planned minutes (B4).
- Closing a week asks first (B6). Catch-up reaches any earlier day (B7).
  Class mode says "Enseignante" (B9).
- Rhythm screen: study / class / rest per weekday, 20 / 40 / 60 minutes,
  reminder time, slots suggested around working hours, completion by time of
  day. New weeks are composed from it; the weekly minimum day is now 20 min.
- Android reminders: weekly-repeating, inexact, none on rest days, one nudge
  no later than 21:00, today's dropped once the floor is reached.
- Home: journey stage, week progress, one primary action, five-minute door,
  class-day card (warm-up and capture), weekly check-in.

Not verified on a device yet: reminder delivery, the notification permission
prompt, and the wake lock during a 90-second answer.

Deliberately left for later: the 40-minute "long session" is the session
length setting rather than a per-day choice; reminders on the web; the
content shortfall (B5) and the 75-minute live allowance (P6-2, P6-3).

## 11. Open question

Realtime per-minute cost is an estimate until the meter exists. The 75-minute
allowance should be revisited after two weeks of metered use.
