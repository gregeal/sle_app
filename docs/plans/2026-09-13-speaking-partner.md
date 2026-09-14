# Speaking partner and persistent repair practice

The original device-dictation design below was extended on September 14 with
explicit opt-in [OpenAI live dictation](2026-09-14-openai-dictation.md). In that
optional mode, audio is sent to OpenAI during capture, before feedback submission.

Implement a separate practice mode alongside the existing Realtime mock interview.
Continuous device dictation remains under learner control: pauses do not submit;
after submitting a thought, the AI provides corrections and a spoken follow-up.
This is turn-based STT/text/TTS, not simultaneous word-by-word diagnosis.

- Persist sessions, drafts, replies and grounded correction suggestions locally.
- Resume an unfinished conversation and target saved, due mistakes in new sessions.
- Import a saved Coach answer as an editable draft, without changing the original
  report or calling AI until the learner submits it.
- Repair with the partner: explain, reformulate, then transfer to a new context.
- Solo recall: attempt before reveal, then self-grade; Again returns soon and
  successes increase spacing. AI observations never automatically award mastery.
- Dismiss erroneous suggestions (especially transcription errors); no pronunciation
  or fluency score inferred from text, and no official SLE level promise.
- Atomic/idempotent turn persistence; bounded prompts, output validation, duplicate
  handling, stale-review protection, microphone cleanup, and migration tests.

No new API keys, providers, cloud database, automatic recording, or transcript
uploads while dictating. Only submitted text and limited relevant context reach
the existing provider/broker. Device speech engines may themselves use cloud speech.

The existing Realtime interview remains an uninterrupted simulation. Official
[Realtime conversation guidance](https://developers.openai.com/api/docs/guides/realtime-conversations)
supports learner-controlled turns; do not replace it with silence-triggered replies.

## Validation (2026-09-13)

- Flutter analysis: no issues; complete Flutter suite: 183 tests passed.
- Locked broker checks: Ruff passed and 34 pytest tests passed.
- Web release built; application-shell PWA finalization and validation passed.
- Signed Android release APK built successfully (93.3 MB); not installed or
  published as part of this implementation request.
- Regression coverage includes schema-v6 upgrade preservation, exact-excerpt
  validation, retry-safe persistence, stale drafts/reviews, recurring/dismissed
  errors, solo scheduling, manual voice submission, interrupted dictation,
  microphone-start failure, final background transcription, and Coach import.
- Automated speech and provider tests use fakes. Live device/browser microphone,
  actual provider response quality, and end-to-end production sessions still need
  hands-on acceptance testing; no paid API call was made during verification.
