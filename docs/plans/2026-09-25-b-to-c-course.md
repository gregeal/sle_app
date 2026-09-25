# Separate B → C study track

## Purpose and boundaries

Add actual classes alongside the existing 26-week practice calendar. The course
is oral-focused: reading, reformulation and short written notes support speaking.
It is not a comprehensive replacement for the separate written-exam preparation
activities, an official assessment, or a guaranteed eight-week route to C.

The scope is informed by the public PSC oral criteria: clear detailed discourse,
supported opinions, hypothetical/complex situations, comprehension and sustained
interaction. Material and questions are original, not recalled exam questions.

Sources reviewed September 25, 2026:

- [PSC oral assessment: about the test](https://www.canada.ca/en/public-service-commission/services/second-language-testing-public-service/oral-language-assessment-sle/about-the-test.html)
- [Qualification standards in relation to official languages](https://www.canada.ca/en/treasury-board-secretariat/services/staffing/qualification-standards/relation-official-languages.html)

## Course structure

1. **Clear discourse:** develop a relevant answer; narrate with past-time anchors.
2. **Connected ideas:** pronouns/relative clauses; logical relationships.
3. **Opinions and comparisons:** support a position; explain a compromise.
4. **Nuance and recommendations:** acknowledge objections; recommend tactfully.
5. **Hypotheses:** present possibilities; analyze alternative past outcomes.
6. **Comprehension and synthesis:** summarize viewpoints; hear a reservation.
7. **Complex communication:** abstract concepts; delicate disagreement.
8. **Fluency and transfer:** paraphrase and keep speaking; integrate skills.

Each module has two fully authored lessons. Each lesson contains four teaching
paragraphs, short and developed examples (not B/C-scored samples), useful phrases,
a reformulation task with a revealable model, two explanatory multiple-choice
questions, an oral transfer task, three self-assessment criteria, and local notes.
Examples are optionally spoken using existing synthetic speech, not human audio.

Recommended pace is three sessions per module: two classes plus a memory/repair
session. Learners may slow down or revisit any module. No prerequisite locking.

## Learner workflow

- Enter from Accueil or the Learning Hub. Continue opens the first unfinished
  lesson, independent of the calendar week.
- Completion requires studied material, a 2/2 formative check, and saved oral
  practice self-assessment. These are activity records, not proficiency scores.
- Quiz feedback explains answers; retries are unrestricted. Later failed retries
  do not erase historical completion.
- Practise solo or open/resume a lesson-specific conversation in the existing
  partner. Its feedback and error notebook remain the existing implementation.
  Merely opening a session does not contact an AI provider.
- Completed lessons enter a recall queue after two days. Successful recalls set
  the next interval to seven, then 21, then 60 days. Later intervals remain 60.
  Recall requires fresh quiz answers and self-assessment; theory starts collapsed.
- Personal notes autosave after a short debounce, on backgrounding and on leaving.
  Explicit save is also available; save failures are surfaced without deleting data.

## Persistence and safety

- Small, versioned JSON records in existing AppSettings under
  `course:b-to-c-v1:<validated-lesson-id>`; no database migration or new dependency.
- Transactional field merges prevent late note writes overwriting quiz/practice
  results or partner links. Invalid/corrupt records fail visibly instead of being
  silently replaced. Text is bounded at 3,000 characters.
- Recall checks the expected review count and due time to reject stale/double
  submissions. Course conversation reuse is limited to unfinished sessions under
  the existing 30-turn cap.
- The existing calendar restart does not change these records. Android and web
  retain their current local-storage isolation; cross-device sync is not implied.
- No new permissions, credentials, model calls, analytics, or broker endpoints.
  AI practice uses the existing provider and consent paths. Lesson notes are not
  automatically sent to the partner. Audio examples stop on exit/background.

## Validation

Automated course tests cover complete content/option bounds, completion gates,
calendar independence (including restart), non-destructive note merges, partner
reuse, recall intervals and duplicate rejection, corrupt-state preservation,
lesson interaction and note persistence, fresh recall controls, and resume routing.

Release checks: Flutter analysis and full tests, Android release build, Flutter web
release build, PWA finalization/validation. Live device audio and subjective learning
effectiveness still require user testing; automated completion is not evidence of
official SLE readiness.

Verified locally on September 25, 2026:

- Flutter analysis: no issues.
- Full Flutter suite: 201 tests passed, including nine new course tests.
- Broker regression checks: Ruff clean, 36 tests passed (no broker changes).
- Android release APK: built successfully, approximately 94 MB.
- Web release: built; PWA finalized and validated.
- Existing non-blocking warnings remain for Android plugins' future Kotlin Gradle
  migration and Starlette's deprecated httpx test-client integration.
- Phone installation and Git publishing are separate release steps; build
  validation alone does not confirm a production web deployment.
