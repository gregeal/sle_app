# Four-skill A → B / B → C courses and selected-text help

## Scope

This extends the original B → C implementation. Both tracks now contain reading,
listening, writing and speaking in every lesson: 32 classes across 16 modules.
It preserves the 26-week calendar and existing B → C work. It does not imply
official certification, exhaustive coverage of every French construction, a
fixed time to proficiency, or cross-device synchronization.

Difficulty uses [Canadian SLE qualification standards](https://www.canada.ca/en/treasury-board-secretariat/services/staffing/qualification-standards/relation-official-languages.html),
reviewed September 25, 2026. These are not CEFR levels. A → B emphasizes familiar
foundations leading to concrete, less routine factual communication. B → C adds
complexity, inference, coherent argument, nuance, abstraction and hypotheses.
All instructional passages/questions are original, not recalled examination items.

## Course content and workflow

- A → B: eight modules from identity/routines through questions, time, places,
  descriptions, requests, instructions, past events, plans, comparisons, messages,
  clarification and incident reporting. The final class integrates these skills.
- B → C: retains the original sixteen classes and adds a distinct reading passage,
  listening script, comprehension checks, writing task and model excerpt to each.
- Both tracks have two core questions plus reading/listening checks per lesson.
  Explanations are shown after checking, with unrestricted retries.
- Writing drafts save separately from personal notes. The learner checks task
  coverage, language/cohesion and revision; this is not automatic writing scoring.
  Optional selected-text questions provide AI feedback on passages the learner
  deliberately submits. Model excerpts illustrate approach, not fixed-length
  benchmark responses or official scoring samples.
- Listening uses the existing synthetic voice. Transcripts are behind a reveal
  control. If speech is unavailable, reading the script remains possible but is
  not equivalent to auditory comprehension; the UI asks learners to revisit audio.
- Speaking may be solo or through the existing partner. Trusted local session
  linkage enables B-level scaffolding for foundation-course conversations; the
  ordinary C-oriented partner remains unchanged outside those sessions.
- Recall retains the 2 / 7 / 21 / 60-day interval sequence and requires fresh quiz,
  comprehension and practice confirmations, plus a nonempty revised draft.

## Persistence and compatibility

- Existing B → C keys remain `course:b-to-c-v1:<id>`. New A → B keys use
  `course:a-to-b-v1:<id>`, with unique `ab-` lesson IDs. No schema migration.
- Course catalog validation rejects unknown lesson/track IDs.
- Version-one JSON gains optional `skills` and `writing` fields. Old records
  default to unattempted new workshops and an empty draft. Historical completion
  dates, notes, quiz/practice results and conversation links are not erased.
- The full-course progress total requires new workshop completion. Old activity
  completion is displayed separately when those workshops remain incomplete.
- Transactional field merges protect saved evidence from delayed note/draft
  writes. Notes remain bounded at 3,000 characters, writing at 6,000. A minimum
  nonempty draft check prevents empty-writing validation, not plagiarism or quality
  assessment. Quiz/recall checks reject incomplete or out-of-range answers.
- Repeated failed practice does not erase previously passed comprehension fields.
  Recall uses due time and expected count to prevent duplicate/stale grading.

## Selection and AI helper

Flutter's [SelectionArea](https://api.flutter.dev/flutter/material/SelectionArea-class.html)
covers ordinary rendered text separately for each Material page route and app tab.
It does not wrap the Navigator: retained hidden routes/tabs must not participate
in the visible page's selection. Native page transitions remain intact.
Existing editable/selectable
study text uses a shared [context-menu builder](https://api.flutter.dev/flutter/material/TextField/contextMenuBuilder.html).
The native copy/edit actions are retained. Flutter's web context menu replaces the
browser menu within the app so custom actions are available.

- New actions: Translate and Ask a question, up to 1,000 selected characters.
- Opening the helper makes no AI request. The learner reviews text, target/explanation
  language and optional context before explicit submission.
- Selected text/context/question are JSON-encoded data under a fixed linguistic
  system instruction that treats them as untrusted input. This reduces instruction
  confusion, but does not guarantee immunity to prompt injection. No tools or URL
  fetching are added. Inputs/structured outputs are bounded and malformed responses
  rejected. Provider failures are surfaced with retry under user control.
- Only explicit fields are submitted through the existing text gateway: direct
  configured provider on Android, authenticated broker on web. No new credentials,
  network endpoints, external translation app dependency or broker changes.
- Output is rendered as text, not executable HTML or automatically followed links.
  AI translations/explanations are fallible, particularly without context.
- Optional vocabulary saving requires review and confirmation of editable card
  fields and reuses existing duplicate-safe spaced-review persistence.
- Credential fields and obscured text receive no new AI actions. Images/external
  app surfaces are not covered. No blanket claim of screen-wide OCR is made.
- Active voice/dictation guards are checked both while constructing the menu and
  immediately before navigation. They are removed on disposal. This prevents the
  helper from covering an active microphone or paid Realtime connection.
- Requests already sent may continue after leaving the helper; no automatic retry
  or background polling is introduced.

## Validation and remaining acceptance checks

Tests cover catalog completeness, question validity, storage separation, legacy
record compatibility, four-skill completion, draft bounds, partner level selection,
recall validation, actual selection menus, credential exclusion, explicit AI
submission, malformed output, recovery and vocabulary save behavior.

Release gates: full Flutter analyzer/tests, Android build, web build and PWA
validation. Physical-device selection handles, browser-specific interaction,
subjective synthetic-voice quality and live-provider linguistic quality need user
acceptance testing. Automated course completion is not proof of SLE readiness.

### Local verification — September 25, 2026

- `flutter analyze --no-pub`: no issues found.
- `flutter test --no-pub --reporter expanded`: 213 tests passed, including real
  app navigation through the course library and an A → B lesson.
- `flutter build apk --release --no-pub`: passed; artifact at
  `sle_prep/build/app/outputs/flutter-apk/app-release.apk`.
- `flutter build web --release --no-pub --no-web-resources-cdn --no-wasm-dry-run`:
  passed; `tool/finalize_pwa.dart` and `tool/validate_pwa.dart` also passed.
- Broker `uv run --frozen ruff check app tests`: passed.
- Broker `uv run --frozen pytest`: 36 tests passed.
- `git diff --check`: passed.

The Android build reports a future Flutter compatibility warning for Kotlin
Gradle Plugin usage in `flutter_tts`, `flutter_webrtc` and `speech_to_text`.
The backend reports a Starlette TestClient/httpx deprecation warning. Neither
prevented the current checks/builds; reassess these before upgrading the affected
toolchains. No live paid-provider requests were made during this verification.

### Phone delivery — September 25, 2026

After user approval, the validated release APK was installed successfully on the
connected Samsung SM-S908W using `adb install -r`, without uninstalling or clearing
app data. Android reports version `0.1.1` (code `2`) and an update time of
`2026-09-25 17:29:17`. Physical-device feature and live-AI acceptance checks remain
for the learner; installation success does not substitute for those checks.

### Follow-up: precise word selection

Replaced the Navigator-wide selection surface after reproducing a long-press
selecting the wrong word from a retained route. Each page and tab now has an
independent selection surface. The editable-text helper also resolves navigation
from the originating text widget, not the toolbar's overlay context.
Regression checks cover a specific accented word in a paragraph, exact clipboard
contents, visible highlight boundaries, dragging a handle to extend to a phrase,
hidden-tab isolation, and passing only the selected word to the translation helper.

Follow-up validation: `flutter analyze --no-pub` reports no issues and the complete
Flutter suite passes all 216 tests. Fresh Android and web release builds passed,
including PWA finalization and validation. After user approval, this follow-up
was installed on the Samsung SM-S908W with `adb install -r` and launched
successfully. Android reports update time `2026-09-25 18:26:05`. App data was not
cleared. Physical-device word-selection acceptance remains for the learner.
