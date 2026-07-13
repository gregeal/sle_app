# PRD — "Objectif C" : French SLE Prep App for the Canadian Public Sector

| | |
|---|---|
| **Author** | Gregory Ealeifo |
| **Date** | 2026-07-12 |
| **Status** | Implemented v1; Realtime WebRTC interview added 2026-07-13 |
| **Platform** | Android (Flutter) |
| **Audience** | Personal tool first; potential future release to GoC employees |

---

## 1. Overview & Problem Statement

Bilingual positions in the Canadian federal public service require passing the Public Service Commission's **Second Language Evaluation (SLE)**, which grades three skills independently — Reading Comprehension, Written Expression, and Oral Language — on a scale of A < B < C (< E, exemption). A "CCC" or "CBC" profile is the gate to most bilingual-imperative roles and many promotions.

Existing tools don't serve this need well:

- **Duolingo / Babbel / generic apps** teach conversational French with no alignment to SLE formats, Canadian workplace register, or the specific level descriptors the PSC grades against.
- **Mauril and other free GoC resources** are good listening/reading input but unstructured — no plan, no feedback, no test simulation.
- **Private SLE tutoring (LRDG, etc.)** is aligned but expensive ($2,000+) and schedule-bound.
- **Nothing simulates the Oral Language Assessment** — the bottleneck test for most candidates — in an on-demand, low-stakes way.

**This app is a personal, SLE-specific training system**: a structured 6-month curriculum (60–90 min/day) that drills all three skills in the actual test formats, plus an AI coach that corrects writing and simulates the oral interview with level-referenced feedback.

## 2. Goals & Success Metrics

### Primary goal
Take a learner from **solid A / low B** to **readiness for a C profile** across all three SLE skills in approximately 6 months at 60–90 minutes of study per day.

### Honest feasibility note
A→C in 6 months is a **stretch goal**. Typical guidance for public servants puts A→C at 12+ months of part-time study; 6 months at 60–90 min/day (~250–350 hours) is achievable only with high consistency and immersion habits outside the app (Mauril, French media, French at work where possible). The curriculum therefore treats **B across the board by month 3** as the committed milestone and **C-readiness by month 6** as the stretch target, with monthly mock-exam checkpoints to re-plan honestly.

### Success metrics (personal-use scale)
| Metric | Target |
|---|---|
| Monthly mock-exam level estimate | B in all skills by month 3; C-range in Reading/Writing by month 5; C-range Oral by month 6 |
| Study adherence | ≥ 6 sessions/week, 60–90 min each |
| Vocabulary retention | ≥ 90% recall on spaced-repetition reviews |
| Ultimate metric | Actual SLE results when taken |

### Non-goals for v1
Monetization, user accounts, iOS, App Store growth. (See §11.)

## 3. Target User & Personas

**Primary (v1): Gregory** — working professional, anglophone, solid A / low B in French, targeting bilingual public-sector roles. Studies on a phone in 60–90 min/day blocks (commute + evening). Comfortable supplying his own LLM API keys.

**Secondary (future)**: GoC employees with a language-training entitlement gap — waiting lists for official training are long, and self-serve SLE-specific tools are scarce. Kept in mind for architecture decisions (nothing hard-codes single-user assumptions into content), but not built for in v1.

## 4. Background: The SLE Tests the App Must Mirror

Facts below are from PSC pages and SLE-prep sources; exact counts/durations should be re-verified against canada.ca before building test simulations (formats change — e.g., the Oral Language Assessment replaced the old Test of Oral Proficiency in 2021).

### 4.1 Test of Reading Comprehension
- ~60 multiple-choice questions (includes ~10 unscored pilot questions), 90 minutes.
- Texts on government and workplace topics; questions test comprehension of main ideas, details, inference, and vocabulary in context.
- Level determined by cut score. Unsupervised online screening versions are shorter (~30 questions).

### 4.2 Test of Written Expression
- ~65 multiple-choice questions, 90 minutes.
- Tests grammar, vocabulary, punctuation/spelling, and organization of information in workplace writing contexts (choosing correct completions, identifying errors, ordering ideas).
- **Not an essay test** — this matters: drills should be MCQ-style error detection and sentence completion, not free composition. (Free writing still trains the underlying skill and is kept as a feedback exercise.)

### 4.3 Oral Language Assessment (OLA)
- Live interview over MS Teams, roughly 20–40 minutes, professionally themed (your work, responsibilities, opinions).
- Questions escalate: A-level (concrete, routine) → B-level (narration, factual explanation) → C-level (opinions with justification, hypotheticals, abstract and sensitive workplace topics).
- Graded on five criteria: **fluency/ease, comprehension, vocabulary, grammar, pronunciation** — C requires C-level performance on most criteria.
- This is the test the app's AI oral coach simulates.

### 4.4 What "Level C" means (summary for feedback prompts)
- **Reading C**: understand most complex texts, implicit meaning, nuance.
- **Writing C**: control of complex structures, precise vocabulary, well-organized workplace writing.
- **Oral C**: sustain conversation on complex/abstract topics; give and defend opinions, counsel, handle hypothetical and sensitive situations with consistent fluency and only non-impeding errors.

## 5. Product Scope

### 5.1 Core loop
Open app → today's session (pre-planned mix of activities totalling 60–90 min) → complete activities → feedback + progress logged → spaced-repetition queue updated → weekly summary and monthly mock-exam checkpoint.

### 5.2 Features (MVP → later, see §10 for phasing)

**F1 — Six-month curriculum & daily session planner (P0)**
- 26-week plan, each week a theme (workplace scenarios: briefing a manager, HR conversations, policy discussion, email triage…) with a grammar focus and vocabulary domain.
- Each day auto-composes a session from blocks: vocab review (10–15 min), grammar drill (15 min), reading or listening practice (20 min), writing or speaking practice (20–30 min).
- Plan adapts: missed days reflow; monthly checkpoint results re-weight weak skills.

**F2 — Spaced-repetition vocabulary (P0)**
- SM-2-style scheduler over GoC/workplace-domain French: administrative vocabulary, idioms, connectors/discourse markers (essential for oral C), verb conjugations.
- Seed decks AI-generated + curated once; reviews are fully offline.

**F3 — Grammar drills (P0)**
- Targeted drills on known SLE pain points: subjunctive, conditional, pronouns (y/en, relatives), prepositions, verb tense sequencing, register.
- SLE-style MCQ format (error spotting, sentence completion) to double as Written Expression prep.

**F4 — Reading practice (P1)**
- SLE-format passages (memos, policy excerpts, news) with multiple-choice questions, timed mode, explanations for wrong answers.

**F5 — Writing practice with AI feedback (P1)**
- Two modes: (a) MCQ Written-Expression drills (test-aligned), (b) free composition (email/memo prompts) with LLM correction — errors annotated, rewritten model answer, level-referenced comments tied to §4.4 descriptors.

**F6 — AI oral coach (P2, the differentiator)**
- Simulated OLA interview: the assessor asks professionally-themed questions escalating A→B→C; user answers by voice; LLM plays the assessor — follow-ups, probing hypotheticals, then structured feedback per the five OLA criteria with an estimated level and 2–3 concrete fixes.
- Two delivery tiers: **full mock interviews use the OpenAI Realtime API** (speech-native, most realistic, ~$0.10–0.30/min — reserved for weekly/monthly sessions); **daily one-question mode uses device STT/TTS + a standard text model** (near-free, instant feedback).
- Pronunciation feedback is best-effort (from transcript mismatches), not phoneme-level scoring — stated limitation.

**F7 — Mock-exam checkpoints & progress dashboard (P3)**
- Monthly: timed reading + writing mock (MCQ, auto-scored against approximate cut lines) and a full-length simulated OLA. Dashboard: level trajectory per skill, streaks, hours, vocab retention.

**F8 — Curated resource rail (P0, cheap)**
- Links/schedule slots for free official resources: Mauril (CBC/Radio-Canada listening), PSC self-assessment practice tests (used as external calibration), TERMIUM/Language Portal of Canada. The plan schedules them; the app doesn't rehost their content.

## 6. Non-Functional Requirements

- **Provider-agnostic LLM layer**: works with any OpenAI-compatible endpoint (OpenAI, OpenRouter, local Ollama, etc.) plus Anthropic. User pastes base URL + API key + model name in settings; per-feature model choice (cheap model for drills, stronger model for oral assessment).
- **Cost control**: batch-pre-generate drill/reading content (generate a week's material in one call); cache everything generated; monthly spend estimate surfaced in settings. Target < ~$15/month for text features; Realtime-API mock interviews are the main variable cost (~$2–6 per 20-min session), budgeted at roughly one per week.
- **Offline-first for daily habit**: vocab reviews, grammar drills, and pre-generated reading work offline; only writing feedback and oral coach require connectivity.
- **Local-first data**: all progress in on-device SQLite; export/import backup file. No server, no accounts.
- **API keys stored in Android encrypted storage** (never in plaintext or backups).
- **French correctness**: Canadian-French register preferred; prompts must instruct models on Canadian workplace French and SLE context.

## 7. Technical Architecture (high level)

- **App**: Flutter (Dart), single codebase, Android-first (iOS later "for free" if wanted).
- **Local DB**: Drift (SQLite) — curriculum state, SRS scheduling, generated-content cache, session logs.
- **LLM adapter interface**: one `LlmClient` abstraction; `OpenAiCompatibleClient` (covers OpenAI/OpenRouter/Ollama/most open-source servers) and `AnthropicClient` implementations. All prompts versioned in-app as templates.
- **Speech**: device STT (`speech_to_text` plugin) and device TTS (`flutter_tts`) by default — free and offline-capable. **Decision**: start with device STT; if accuracy on learner-accented French proves poor, escalate to Whisper-API STT (paid but negligible: ~$0.006/min, ≈ $0.12 per 20-min interview). Full mock interviews use the OpenAI Realtime API's built-in speech handling instead (§5.2 F6).
- **Content pipeline**: generation prompts produce structured JSON (drill items, passages+questions, interview scripts) validated against schemas before caching; malformed generations are retried or discarded.

## 8. Content Strategy

- **AI-generated, format-locked**: every generated exercise conforms to an SLE-style template (§4) so practice transfers to test day. Templates are hand-written once, from PSC sample/practice materials.
- **Curated calibration**: PSC's own online self-assessment tests are the ground truth for level estimates — the app schedules them at checkpoints rather than pretending its internal estimates are official.
- **Curriculum skeleton hand-authored**: the 26-week theme/grammar sequence is authored once (with AI assistance, human-reviewed) and shipped with the app; only exercise *instances* are generated on demand.
- **Register**: prompts enforce Canadian public-service French (courriel not email, workplace formality, GoC terminology via TERMIUM references).

## 9. Risks & Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| 6-month A→C is too aggressive | Demotivation, plan collapse | Framed as stretch (§2); monthly checkpoints re-plan; B-by-month-3 committed milestone |
| AI-generated French contains errors | Trains mistakes | Stronger model + self-review pass for content generation; report-an-error button; curated seed content for high-stakes items |
| Oral simulation ≠ real OLA | False confidence | Feedback anchored to published OLA criteria; PSC self-assessments as external calibration; app states estimates are unofficial |
| Test formats change | Drills misaligned | Format facts isolated in one config/content module; §4 re-verified before each phase |
| API cost creep | Abandonment | Batch generation, caching, cheap-model routing, visible spend estimate |
| Solo-dev scope creep | Nothing ships | Phased build (§10) — app is useful from P0 (vocab + drills + planner) within weeks |
| Pronunciation feedback quality | Weak on 1 of 5 OLA criteria | Stated limitation; transcript-based heuristics only; recommend human feedback occasionally |

## 10. Milestones

| Phase | Scope | Definition of done |
|---|---|---|
| **P0 — Daily habit engine** (~wks 1–4) | Flutter skeleton, Drift DB, curriculum planner (F1), SRS vocab (F2), grammar drills (F3), resource rail (F8), LLM adapter + settings | Complete a full offline-capable 60-min daily session; start the 6-month plan **while building the rest** |
| **P1 — Reading & writing** (~wks 5–8) | Reading practice (F4), writing MCQ drills + AI free-writing feedback (F5), content-generation pipeline hardening | Timed SLE-format reading set and corrected composition end-to-end |
| **P2 — Oral coach** (~wks 9–14) | STT/TTS integration, daily one-question mode, full simulated OLA interview with 5-criteria feedback (F6) | 20-minute simulated interview producing level-referenced feedback |
| **P3 — Checkpoints & dashboard** (~wks 15–18) | Monthly mock exams, level trajectory dashboard, plan re-weighting (F7) | First full mock-exam cycle informs an automatic plan adjustment |
| **P4 — Web session** (implemented; deployment-ready) | Auth-gated Flutter Web deployment with an AI Broker backend (see §14 and [docs/plans/2026-07-13-p4-web-plan.md](docs/plans/2026-07-13-p4-web-plan.md)) | Code, tests, container, Blueprint, and security checklist complete; final public URL requires owner-provided domain/OAuth/provider secrets |

Note the app's P0 ships in ~1 month so the 6-month study clock and the build overlap — the builder is also user #1, which doubles as continuous QA.

## 11. Out of Scope (v1)

- iOS release, Play Store publication, monetization/subscriptions
- User accounts, cloud sync, multi-user backend *(amended by P4, §14: a single-owner auth gate and a minimal AI Broker are introduced for the web session; study data remains local-first with no server-side sync)*
- Human tutor marketplace or live conversation matching
- Official level certification claims of any kind
- Listening-specific test prep beyond Mauril integration (listening is assessed within the OLA, not as a separate SLE test)

## 12. Resolved Decisions (formerly Open Questions)

1. **Assessor LLM**: OpenAI is the primary provider — the Realtime API ("ChatGPT live") for full spoken mock interviews, standard chat models for writing feedback and daily oral drills. The provider-agnostic adapter (§6) is kept so models can be benchmarked/swapped later with a fixed rubric.
2. **STT**: device STT from day one of P2 (Whisper API is paid, though only ~$0.006/min). If device STT proves inaccurate on learner-accented French, escalate to Whisper API — the cost of doing so is trivial.
3. **Score reporting**: mock reading/writing scores map to A/B/C via published cut-score approximations, clearly labelled as unofficial estimates (calibrated against PSC self-assessment tests at checkpoints, per §8).

## 13. Sources

- [PSC — SLE Oral Language Assessment (candidates)](https://www.canada.ca/en/public-service-commission/services/second-language-testing-public-service/oral-language-assessment-sle-cat.html)
- [PSC — SLE Oral Language Assessment (managers)](https://www.canada.ca/en/public-service-commission/services/second-language-testing-public-service/managers/oral-language-assessment-sle.html)
- [PSC — SLE Test of Written Expression](https://www.canada.ca/en/public-service-commission/services/second-language-testing-public-service/managers/sle-written.html)
- [LRDG — How to score a CBC or CCC on the SLE](https://lrdgonline.com/how-to-cbc-sle/)
- [LRDG — SLE Test of Written Expression](https://lrdgonline.com/sle-test-written-expression/)
- [LRDG — SLE French oral exam questions](https://lrdgonline.com/sle-french-oral-questions/)
- [GCcollab — Preparing for Federal Public Service second-language tests (PDF)](https://wiki.gccollab.ca/images/7/72/Parcours_Refaire_tests_EN.pdf)

*Canada.ca pages could not be machine-fetched during drafting (bot-blocked); test-format numbers were cross-checked across the third-party sources above and should be re-verified manually on canada.ca before building the test simulators (§9).*

## 14. P4 — Web session (implemented; deployment-ready)

Extend the product to a **web session usable anywhere on the internet, gated by a permission** (sign-in against an owner-controlled allowlist), with feature parity including the Realtime voice interview.

**Requirements**

- Same Flutter codebase compiled for the web; study data stays **local-first** in the browser (SQLite WASM + OPFS) exactly as it stays on the phone — no server-side study database.
- **No long-lived credentials in the browser.** A minimal backend ("AI Broker") holds the provider API key in a server-side secret store, authenticates the user (passkey/WebAuthn primary, OAuth fallback, email allowlist), proxies text AI calls, and mints short-TTL ephemeral secrets for Realtime voice sessions. The Android app's direct-to-provider model is unchanged.
- **Abuse and cost containment**: per-user rate limits, hard daily/monthly spend caps, model allowlist, and an audit log enforced in the broker.
- **Hardening**: TLS + HSTS, strict CSP, HttpOnly/SameSite cookies with CSRF protection, security-headers scan and an OWASP-style checklist as release gates.

Full architecture (component and sequence diagrams), threat model, task breakdown, and verification plan: [docs/plans/2026-07-13-p4-web-plan.md](docs/plans/2026-07-13-p4-web-plan.md).

Implementation evidence: Flutter analysis and production web build are green;
the complete Flutter suite covers 95 tests, the FastAPI broker has 12 passing
auth/security/proxy tests, and the release controls are archived in
[docs/security/p4-web-security-checklist.md](docs/security/p4-web-security-checklist.md).
`Dockerfile` and `render.yaml` define the same-origin production deployment.
The final Render service, custom domain, Google OAuth registration, live
OpenAI smoke test, and external Observatory scan require owner-managed secrets
and infrastructure and therefore are deployment steps rather than repository
artifacts.
