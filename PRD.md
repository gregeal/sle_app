# PRD — "Objectif C" : French SLE Prep App for the Canadian Public Sector

| | |
|---|---|
| **Author** | Gregory Ealeifo |
| **Date** | 2026-07-12 |
| **Status** | Core v1 implemented; hardening complete, with mock validity and backup gaps tracked below |
| **Platform** | Android and Web (Flutter), with a same-origin FastAPI web broker |
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
Monetization, cross-device progress synchronization, broad multi-tenant signup,
iOS, and App Store growth. Web accounts exist only as an allowlisted security
boundary for the server-held provider key. (See §11.)

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
- The CFP publishes integrated level descriptors covering comprehension,
  delivery/hesitation, vocabulary and structures, clarity, and pronunciation.
  The app reports five pedagogical dimensions (**aisance, compréhension,
  vocabulaire, grammaire, prononciation**) aligned with those descriptors; this
  is a formative, non-official scorecard rather than the CFP's official report.
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
- Simulated OLA interview: the assessor asks professionally-themed questions escalating A→B→C; user answers by voice; LLM plays the assessor — follow-ups, probing hypotheticals, then structured feedback across the five pedagogical dimensions with an estimated level and 2–3 concrete fixes.
- Two delivery tiers: **full mock interviews use the OpenAI Realtime API** (speech-native and billed at the provider's current audio rates); **daily one-question mode uses device STT/TTS + a standard text model**. Provider pricing changes, so the app and deployment must not rely on the historical estimates in this PRD.
- Pronunciation feedback is best-effort (from transcript mismatches), not phoneme-level scoring — stated limitation.

**F7 — Mock-exam checkpoints & progress dashboard (P3)**
- Monthly: timed reading + writing mock (MCQ, auto-scored against approximate cut lines) and a full-length simulated OLA. Dashboard: level trajectory per skill, streaks, hours, vocab retention.

**F8 — Curated resource rail (P0, cheap)**
- Links/schedule slots for free official resources: Mauril (CBC/Radio-Canada listening), PSC self-assessment practice tests (used as external calibration), TERMIUM/Language Portal of Canada. The plan schedules them; the app doesn't rehost their content.

## 6. Non-Functional Requirements

- **Provider-agnostic LLM layer**: works with any OpenAI-compatible endpoint (OpenAI, OpenRouter, local Ollama, etc.) plus Anthropic. User pastes base URL + API key + model name in settings; per-feature model choice (cheap model for drills, stronger model for oral assessment).
- **Cost control**: cache generated drill/reading content, use server-side model allowlists and configurable rate/budget reservations, and keep provider project limits/alerts enabled. Pricing is intentionally not frozen in this document because model and audio rates change.
- **Offline-first for daily habit**: vocab reviews, grammar drills, and pre-generated reading work offline; only writing feedback and oral coach require connectivity.
- **Local-first data**: progress remains in Android SQLite or a per-user
  browser-local SQLite database. The web broker stores only authentication,
  content-free audit, and quota metadata; it never stores learning content or
  transcripts. Export/import and encrypted backup remain planned work, not a
  completed v1 capability.
- **API keys stored in Android encrypted storage** (never in plaintext or backups).
- **French correctness**: Canadian-French register preferred; prompts must instruct models on Canadian workplace French and SLE context.

## 7. Technical Architecture (high level)

- **App**: Flutter (Dart), one Android/Web codebase; iOS remains future work.
- **Local DB**: Drift (SQLite) — curriculum state, SRS scheduling, generated-content cache, session logs.
- **LLM adapter interface**: one `LlmClient` abstraction; `OpenAiCompatibleClient` (covers OpenAI/OpenRouter/Ollama/most open-source servers) and `AnthropicClient` implementations. All prompts versioned in-app as templates.
- **Speech**: device STT (`speech_to_text` plugin) and device TTS (`flutter_tts`) by default. Full Realtime practice uses OpenAI's speech handling. Device speech accuracy and audio routing require real-device evaluation before any pronunciation-quality claim; paid fallback pricing must be checked at implementation time.
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
| Oral simulation ≠ real OLA | False confidence | Feedback aligned to published OLA descriptors; official CFP resources as external calibration; app states that its five dimensions and estimates are non-official |
| Test formats change | Drills misaligned | Format facts isolated in one config/content module; §4 re-verified before each phase |
| API cost creep | Abandonment | Batch generation, caching, cheap-model routing, visible spend estimate |
| Solo-dev scope creep | Nothing ships | Phased build (§10) — app is useful from P0 (vocab + drills + planner) within weeks |
| Pronunciation feedback quality | Weak formative signal | Stated limitation; transcript-based heuristics only; recommend human feedback occasionally |

## 10. Milestones

| Phase | Scope | Definition of done |
|---|---|---|
| **P0 — Daily habit engine** (~wks 1–4) | Flutter skeleton, Drift DB, curriculum planner (F1), SRS vocab (F2), grammar drills (F3), resource rail (F8), LLM adapter + settings | Complete a full offline-capable 60-min daily session; start the 6-month plan **while building the rest** |
| **P1 — Reading & writing** (~wks 5–8) | Reading practice (F4), writing MCQ drills + AI free-writing feedback (F5), content-generation pipeline hardening | Timed SLE-format reading set and corrected composition end-to-end |
| **P2 — Oral coach** (~wks 9–14) | STT/TTS integration, daily one-question mode, full simulated OLA interview with five-dimension feedback (F6) | 20-minute simulated interview producing level-referenced, non-official feedback |
| **P3 — Checkpoints & dashboard** (partially implemented) | Formative mock screens and dashboard exist; exam-length timing, validated scoring and mock-result-driven plan re-weighting remain | Not complete until a full mock cycle changes the plan and is calibrated externally |
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
2. **STT**: device STT from day one of P2. If it proves inaccurate on learner-accented French, benchmark a provider STT fallback and its current price before adopting it.
3. **Score reporting**: mock reading/writing scores map to A/B/C via published cut-score approximations, clearly labelled as unofficial estimates (calibrated against PSC self-assessment tests at checkpoints, per §8).

## 13. Sources

- [CFP — Évaluation linguistique à l’oral](https://www.canada.ca/fr/commission-fonction-publique/services/evaluation-langue-seconde/gestionnaires/evaluation-linguistique-oral-sle.html)
- [CFP — Test d’expression écrite supervisé](https://www.canada.ca/fr/commission-fonction-publique/services/evaluation-langue-seconde/sle-test-expression-ecrite-supervise-oec.html)
- [CFP — Test de compréhension de l’écrit supervisé](https://www.canada.ca/fr/commission-fonction-publique/services/evaluation-langue-seconde/sle-test-comprehension-ecrit-supervise-oec.html)
- [LRDG — How to score a CBC or CCC on the SLE](https://lrdgonline.com/how-to-cbc-sle/)
- [LRDG — SLE Test of Written Expression](https://lrdgonline.com/sle-test-written-expression/)
- [LRDG — SLE French oral exam questions](https://lrdgonline.com/sle-french-oral-questions/)
- [GCcollab — Preparing for Federal Public Service second-language tests (PDF)](https://wiki.gccollab.ca/images/7/72/Parcours_Refaire_tests_EN.pdf)

*The official Canada.ca pages above were re-verified on 2026-07-13. Recheck them before changing a simulator because formats and administration rules can change.*

## 14. P4 — Web session (implemented; deployment-ready)

Extend the product to a **web session usable anywhere on the internet, gated by a permission** (sign-in against an owner-controlled allowlist), with feature parity including the Realtime voice interview.

**Requirements**

- Same Flutter codebase compiled for the web; study data stays **local-first** in the browser (SQLite WASM + OPFS) exactly as it stays on the phone — no server-side study database.
- **No long-lived credentials in the browser.** A minimal backend ("AI Broker") holds the provider API key in a server-side secret store, authenticates the user (passkey/WebAuthn primary, OAuth fallback, email allowlist), proxies text AI calls, and mints short-TTL ephemeral secrets for Realtime voice sessions. The Android app's direct-to-provider model is unchanged.
- **Abuse and cost containment**: per-user rate limits, atomic daily/monthly reservation caps, model allowlist, and an audit log enforced in the broker. Text reservations settle from provider token usage. Realtime uses a conservative fixed reservation because media bypasses the broker, so provider project limits/alerts remain required for an actual-spend backstop.
- **Hardening**: TLS + HSTS, strict CSP, HttpOnly/SameSite cookies with CSRF protection, security-headers scan and an OWASP-style checklist as release gates.

Full architecture (component and sequence diagrams), threat model, task breakdown, and verification plan: [docs/plans/2026-07-13-p4-web-plan.md](docs/plans/2026-07-13-p4-web-plan.md).

Implementation evidence: the repository's CI workflow runs Flutter analysis
and tests, a finalized/validated production PWA, a signed Android release build using a disposable CI key, broker lint/tests,
and a deployable-container readiness check. Test totals are not frozen in this
PRD; the current CI run is the source of truth. Release controls and the
remaining manual gates are tracked in
[docs/security/p4-web-security-checklist.md](docs/security/p4-web-security-checklist.md).
`Dockerfile` and `render.yaml` define the same-origin production deployment.
The final Render service, custom domain, Google OAuth/passkey validation, paid
OpenAI smoke test, clean-profile offline/PWA test, device microphone/audio test,
and external Observatory scan require owner-managed secrets or infrastructure
and must not be treated as completed repository-only validation.
