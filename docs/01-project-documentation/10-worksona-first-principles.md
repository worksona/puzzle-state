# puzzle-state Project Documentation — Report 10: Worksona First Principles

> **Project:** puzzle-state | **Generated:** 2026-08-25 | **Repo:** worksona/puzzle-state (public)

*Assessed against the sixteen structural principles of worksona.fp (`worksona-first-principles` skill, bundled compendium `worksona-fp-compendium.md`), including the Manifold-Structured Intelligence concept spec and the standards handbook. Every assessment traces to a numbered principle; none are invented. For the complementary execution rubric, see [Report 09](./09-worksona-themes.md).*

## Executive Summary

puzzle-state is a system whose *design* is close to a textbook expression of manifold-structured intelligence — twelve narrowly-scoped charts, a nine-value transition object treated as first-class, refusal wired into three separate egress paths — and whose *enforcement* is roughly half convention. Its finest structural achievement is that the guarantee that matters most does not depend on code being correct: solutions cannot leak from the public repo because they are not in it. Its defining structural weakness is the mirror image: a strict JSON Schema, a single-writer rule, and a `validate` operation all exist as declarations with nothing that executes them — and three of eighteen live records already violate the schema, unnoticed. The system is well-charted and under-enforced.

## Principle Alignment Scorecard

| # | Principle | Alignment | Evidence Summary |
|---|---|---|---|
| 1 | Competence Is Always Local | 🟢 Strong | Twelve narrowly-scoped skills, each declaring inputs, one phase transition, and often an explicit non-goal |
| 2 | Validity Is a Precondition | 🟡 Moderate | `phase` gates every dispatch and the schema is strict — but nothing executes the schema, and three live records violate it |
| 3 | Guarantees Must Be Structural | 🟡 Moderate | The solution guarantee is genuinely structural (private repo); the single-writer rule is prose |
| 4 | Composition Is the Failure Surface | 🟡 Moderate | `puzzle.yaml` is a real shared representation and container mounts are declared — but zero integration tests and an untransactioned publish fan-out |
| 5 | Transitions Are First-Class | 🟢 Strong | Named nine-value enum, drawn phase machine, a dedicated `advance-phase` op — the project's best principle |
| 6 | Refusal Is Correct Behavior | 🟢 Strong | "ABORT and fail loudly"; `find`-abort at deploy; lock-held exit; `unsolvable` as a recorded refusal |
| 7 | Metrics Encode Alignment | 🔴 Weak | Process counters only; per-record data collected and never aggregated; no declared trade-off targets |
| 8 | Uncertainty Narrows Validity | 🟡 Moderate | Blindfolded solver, a third `ambiguous` outcome, budget caps — but `require_unique_solution: false` widens under ambiguity |
| 9 | Observability Is Safety | 🟡 Moderate | Append-only log, per-stage logs, solver decision traces — yet three kinds of drift went unobserved |
| 10 | Intelligence in Structure | 🟢 Strong | Behavior determined by `phase` + `manifest.yaml` + schema; router explicitly decides nothing — except puzzle mechanics, which have no structure |
| 11 | Additive Scaling / Isolation | 🟢 Strong | Per-puzzle directories, disposable containers, directory-based skill discovery, `$BAZAAR_ROOT` relocation |
| 12 | Runtime Governance | 🟡 Moderate | Lock, leak scan, deploy guard, and egress policy are runtime; schema, single-writer, and validate are honor system |
| 13 | Evolution Is Mandatory | 🔴 Weak | Two commits, no tags, no CHANGELOG, no migration path — while the data plane silently evolved to "artifacts v3" |
| 14 | Executors Share Constraints | 🟢 Strong | SKILL.md is simultaneously human doc and machine instruction; `state/` visible by design so humans can inspect |
| 15 | Critical = Unavoidable | 🟡 Moderate | The most critical constraint is near-unavoidable; four others are README "remember to" items |
| 16 | Structure Is the Output | 🟢 Strong | The repo's entire deliverable is structure — but it has not been re-invested in since scaffold |

**Alignment Levels:** 🟢 Strong — structurally embedded · 🟡 Moderate — partially present or inconsistent · 🔴 Weak — absent or violated

**Distribution:** 8 Strong · 6 Moderate · 2 Weak

## Detailed Principle Assessments

### Principle 1: Competence Is Always Local
**Alignment:** 🟢 Strong

**Evidence:**
- Twelve charts, each scoped to exactly one phase transition. `puzzle-researcher` (candidate → researched), `puzzle-designer` (researched → designed), `puzzle-builder` (designed → built | build-failed), and so on. No skill spans two transitions; none is a god object.
- Each declares its applicability in its own contract. `puzzle-builder`: "Inputs — `puzzles/PUZ-NNNN-slug/puzzle.yaml` at `phase: designed`." `puzzle-curator`: "All `puzzles/*/puzzle.yaml` at `phase >= reported`." Validity is stated as a precondition on the record, not assumed.
- Several declare explicit boundaries. `puzzle-curator` closes with a `## Non-goal` section: "The curator does not publish. The publisher decides whether and how to ship a collection." That is a chart refusing to extend past its region.
- **Competence is local in a second, physical sense.** The host chart holds secrets and does reasoning, research, and publishing; the container chart builds and playtests and holds no secrets. Spec §3's ASCII topology draws the boundary and names what crosses it in each direction ("puzzle + spec ►" one way, "◄ artifact, test logs" the other).

**Gaps:**
- Validity conditions are prose, not machine-checkable. "at `phase: designed`" is a sentence in Markdown; nothing prevents `/puzzle-builder` from being invoked on a `candidate`. Under the standards handbook ("Validity conditions MUST be conservative… Invariants MUST be binary and machine-checkable"), these charts declare validity but do not enforce it.
- `/puzzle-state` is broad by design — eight operations spanning init, read, write, validate, id allocation, phase advance, scrub, and locking. Justified by the single-writer rule, but it is the one chart whose region is defined by *who may act* rather than by *what work is valid*.

**Structural Recommendation:** Add a machine-checkable `applies_when` field to SKILL.md frontmatter (e.g. `applies_when: phase == "designed"`) and have the orchestrator evaluate it before dispatch. The information already exists in prose; promoting it to frontmatter makes it enforceable.

### Principle 2: Validity Is a Precondition for Action
**Alignment:** 🟡 Moderate

**Evidence:**
- The phase field *is* the precondition mechanism, and the orchestrator's dispatch table is a validity router: `candidate → /puzzle-researcher`, `built → /puzzle-tester`, `tested → /puzzle-packager` (if solvable) OR `/puzzle-reporter` (if unsolvable/ambiguous). Routing is conditional on validity, exactly as the concept spec prescribes.
- `scripts/init-facility.sh` checks before every write: `if [[ ! -f "$ROOT/manifest.yaml" ]]` … `else echo "exists: … (left as-is)"`. It refuses to overwrite rather than proceeding optimistically.
- The schema is written to make invalid states unrepresentable: `additionalProperties: false` at every object level, `required: [id, slug, phase, created, updated, source]`, `pattern: "^PUZ-[0-9]{4}$"`, and enums on `phase`, `design.type`, `design.difficulty_target`, `build.artifact_kind`, `test.status`, and `source.surface`.
- Budgets are preconditions on continuation: exceeding `per_puzzle_timeout_s: 1200` terminates the container and assigns a named failure state rather than accepting a partial artifact.

**Gaps:**
- **The schema is never applied.** `/puzzle-state validate` is a row in a Markdown table with no implementation. The consequence is measurable: across `~/bazaar/puzzles/*/puzzle.yaml`, `design.type` is `logic` ×10, `cipher` ×5, and then `meta`, `modern-crypto`, and `stego` ×1 each. The last three are outside the enum. Three records were written outside their region of validity and persisted.
- `/puzzle-state write` is specified as "validate (schema for YAML), write" — the correct design — but with no executable validator behind it, the write half runs and the validate half does not.
- `advance-phase` accepts `id, new_phase` with no stated legality check. Nothing in the contract forbids `published → candidate`.

**Structural Recommendation:** This is the single highest-leverage structural fix in the project. One script — walk `$BAZAAR_ROOT/puzzles/*/puzzle.yaml` against `schemas/puzzle.schema.yaml`, exit non-zero — converts a declared precondition into an enforced one. Add a transition legality table so `advance-phase` refuses illegal edges.

### Principle 3: Guarantees Must Be Structural
**Alignment:** 🟡 Moderate

**Evidence — genuinely structural:**
- **The two-repo split.** Solutions live in `worksona/bazaar-data` (private); the engine repo is public and contains none. This guarantee holds even if every guard is buggy, because the material is not present to leak. Under the compendium's own test ("If an outcome matters, it MUST be enforced by structure"), this is the strongest example in the portfolio.
- **`state/bazaar.lock`.** A filesystem object, acquired as step 1 of the walk: "If held, exit (another run is active)." Concurrency is prevented by a file, not by a rule.
- **The deploy guard.** `~/bazaar/deploy.sh` line 38: `find "$STAGE" \( -name 'solution.md' -o -name 'puzzle.yaml' -o -name 'research.md' -o -name 'design.md' \) | grep -q .` → abort. A machine check that blocks the deploy.
- **The leak scan.** "If any substring of solution.md ≥40 chars appears in the body, ABORT and fail loudly." Binary and mechanical.
- **Sandbox constraints.** `egress: registries-only`, `cpu: 2`, `memory: 4g`, read-only mounts — enforced by the container runtime, not by the code inside it.

**Evidence — not structural:**
- **The single-writer rule.** Spec §2 invariant 3 and `puzzle-state/SKILL.md` ("no skill writes the substrate directly") are prose. Nothing prevents any other skill from writing `~/bazaar/`. This is the compendium's named anti-pattern — a rule that exists only in documentation.
- **The schema.** Strict and unexecuted (Principle 2).
- **`durability.mirror.remote: null`** ships as the default, with README step 4 saying to set it "before relying on it." Invariant by reminder.
- **No CI gates.** No `.github/`, so no guarantee is checked before anything ships.

**Structural Recommendation:** The single-writer rule needs a mechanism. sound-flow solves this exactly — `sound-state` wraps `src/lib/state.mjs` (class `Substrate`), "the only code path permitted to write." A thin `bin/puzzle-state` CLI that other skills shell out to would make the rule enforceable rather than remembered, and would carry the validator from Principle 2 with it.

### Principle 4: Composition Is the Primary Failure Surface
**Alignment:** 🟡 Moderate

**Evidence:**
- **A real shared representation.** `puzzle.yaml` is the single object every chart reads and writes, with a schema, an example (§5), and a strict shape. Charts do not pass ad-hoc payloads to each other; they compose through one typed record. This is the compendium's "shared representations" requirement, met.
- **Overlaps are declared, not implied.** The host↔container boundary specifies exactly what crosses and in which direction: `puzzle-builder` mounts `build/` rw and `templates/types/<template_id>.template/` ro; `puzzle-tester` mounts `artifact/` read-only. Spec §3 draws the same boundary.
- **The phase enum is the composition contract.** Every handoff between charts is mediated by one of nine named values, so no chart needs to know which chart ran before it.
- Idempotency is declared per boundary: the harvester keys on `source.message_ts`; the builder's re-run after `built` is a no-op.

**Gaps:**
- **Zero integration tests.** Nothing exercises any boundary. The one place the compendium says failures concentrate is the one place with no verification at all.
- **The publish fan-out has no overlap protocol.** `puzzle-publisher` runs five sequential external interactions writing `outputs.gist_url`, then `outputs.blog_post_id`, then `outputs.solution_gist_url`, then `outputs.work_state_event_id`, then advances phase. If step 3 fails after step 2 succeeded, the record sits at `reported` with a live public gist. No schema field represents partial egress; no compensation is described. This is the classic boundary failure the principle names.
- **The engine↔data-plane boundary has no contract at all.** `~/bazaar/state/state.json` carries `site{}` and `artifacts{}` keys that no schema in this repo describes, and an `artifacts.flag_storage` scheme ("encrypted-under-solution (logic wing) / sha256-hash (cipher wing)") that appears nowhere in the spec. Two regions evolved across an ungoverned boundary.

**Structural Recommendation:** Make the publisher idempotent per surface — check `outputs.<field>` before each step and skip if populated — converting a five-step fan-out into a resumable one. Add `schemas/state.schema.yaml` so the engine↔data-plane boundary has a declared shape.

### Principle 5: Transitions Are First-Class Objects
**Alignment:** 🟢 Strong

**Evidence:**
- **The transition set is named, enumerated, and typed.** Nine values in `schemas/puzzle.schema.yaml`: `candidate, researched, designed, built, build-failed, tested, packaged, reported, published`. Transitions are not implied by which function ran; they are a field.
- **The transition graph is drawn.** Spec §6 renders the machine in ASCII, including the two failure edges, and states the doctrine: "`build-failed` and `tested:unsolvable` are both terminal-with-findings: they advance to report and publish."
- **Transition is an operation, not a side effect.** `/puzzle-state advance-phase` takes `id, new_phase` and performs three things as one act: "update puzzle.yaml; append activity event; refresh state.json counts." The record, the audit trail, and the derived index move together — implicit context transfer is exactly what this prevents.
- **Transitions carry state explicitly.** Each phase has a corresponding block in the schema (`research`, `design`, `build`, `test`, `package`, `report`, `curation`, `outputs`), so what a transition produced is preserved in a named location rather than in a log or in memory.
- **Transitions are the resume mechanism.** "Re-running an interrupted night picks up where it stopped via per-puzzle phase." The transition object doubles as the crash checkpoint.

**Gaps:**
- No transition declares what is *discarded*. The compendium requires every transition to state what is preserved, transformed, and discarded; puzzle-state declares the first two implicitly through schema blocks and the third not at all.
- No legality constraints on the graph. Nothing forbids an edge the diagram does not draw.
- The failure branches are drawn but not represented as first-class objects: `build-failed` is a phase value, while `tested: unsolvable` is a *combination* of `phase: tested` and `test.status: unsolvable`. Two failure modes with two different encodings, which the orchestrator's dispatch table then has to special-case ("`tested` → `/puzzle-packager` (if solvable) OR `/puzzle-reporter` (if unsolvable/ambiguous)").

**Structural Recommendation:** Add a transition table to the spec listing each legal edge with preserved / transformed / discarded state, and have `advance-phase` reject edges not in it. Consider normalizing the two failure encodings.

### Principle 6: Refusal Is Correct Behavior
**Alignment:** 🟢 Strong

**Evidence:**
- **Explicit, loud refusal at the highest-stakes boundary.** `puzzle-publisher`: "If any substring of solution.md ≥40 chars appears in the body, ABORT and fail loudly. A leaked solution is a defect." No degraded mode, no partial send.
- **Refusal at the deploy boundary.** `deploy.sh` aborts the entire deploy if any private file reached the stage — it does not filter and continue.
- **Refusal on contention.** Orchestrator step 1: "Acquire `state/bazaar.lock`. If held, exit (another run is active)." It exits rather than queueing or forcing.
- **Refusal encoded as a domain outcome.** `test.status: unsolvable` means the solver could not reach the win condition within budget, and the system records that rather than shipping a puzzle it cannot vouch for. Spec §2 invariant 5 elevates it: "a failed playtest advances to a report, not a halt." This is the compendium's "refusal is correct behavior" *and* "escalation is success under uncertainty" in one mechanism — the refusal becomes a publishable finding.
- **Refusal on resource exhaustion.** Timeouts produce named terminal states (`build-failed`, `tested: unsolvable`), never partial artifacts.
- **Refusal in the bootstrap.** `init-facility.sh` refuses to overwrite existing files, printing "exists: … (left as-is)".

**Gaps:**
- Every refusal path is untested. The ≥40-character rule in particular is a heuristic with an unprobed failure mode: a solution key shorter than 40 characters, or reformatted between `solution.md` and the report body, passes.
- Refusal is absent where validity is unchecked. Nothing refuses a record with an out-of-enum `design.type` — three such records exist.
- No circuit breaker or timeout is specified for the external surface calls (gist, scsiwyg, work-state). A hanging surface hangs the walk.

**Structural Recommendation:** Add a leak-guard fixture — a `report.md` containing a known 60-character solution substring, asserted rejected. The project's best-designed refusal deserves a test; it is currently the most consequential untested behavior in the repo.

### Principle 7: Metrics Encode Alignment
**Alignment:** 🔴 Weak

**Evidence:**
- Two trade-off parameters are declared in config: `testing.solver.require_unique_solution: false` ("set true to fail on ambiguity") and `max_solve_time_s: 600`. These are genuine, explicit, region-local trade-off knobs.
- Resource trade-offs are declared: `cpu: 2`, `memory: 4g`, `per_puzzle_timeout_s: 1200`, `night_budget_s: 14400`.
- Per-record instrumentation is rich: `build.exit_code`, `build.duration_s`, `test.solver_passed`, `test.unique_solution`, `test.difficulty_actual`, plus `state.json.counts_by_phase`.

**Gaps:**
- **No metric defines what "good" means.** No north star anywhere in the README, spec, manifest, or any SKILL.md. The compendium is explicit that alignment is encoded *only* through metrics; here it is encoded through prose intent ("a bazaar of puzzles and puzzling things").
- **The counters measure the factory, not the product.** `{published: 17, reported: 1}` is throughput. Nothing measures whether any of the eighteen artifacts has been solved by a visitor — the site has no analytics and no feedback path exists.
- **Collected data is never compared to a target.** `design.difficulty_target` and `test.difficulty_actual` are both captured on every record and never reconciled. That comparison is a ready-made alignment metric sitting unused on disk.
- **No SLOs, no thresholds, no alerts.** Nothing states an acceptable rate of `unsolvable` or `build-failed`. Without a threshold, those outcomes carry no signal.
- **A trade-off was set without evidence.** `require_unique_solution: false` chooses throughput over rigor. Legitimate — but the compendium's framing ("metric changes MUST be reviewed as policy decisions") asks what evidence supports it, and there is none; it is an unrevisited default.

**Structural Recommendation:** Define three metrics computable from data already on disk plus one new counter: **north star** — solved-by-visitor rate per published puzzle; **leading** — `difficulty_actual` vs `difficulty_target` agreement and the `test.status` distribution; **lagging** — records failing validation, and puzzles at `phase >= reported` not yet in a collection. Two of three need aggregation only.

### Principle 8: Uncertainty Narrows Validity
**Alignment:** 🟡 Moderate

**Evidence — where it narrows correctly:**
- **The solver is deliberately blindfolded.** `puzzle-tester`: "Run the solver against the artifact WITHOUT access to `design.solution_sketch` or `solution.md`." The system refuses to let its own knowledge contaminate its uncertainty estimate — a genuinely sophisticated handling of curvature.
- **Ambiguity has its own value.** `test.status` is a three-value enum, not a boolean. `ambiguous` is defined precisely: "solver reached a valid win-condition state via an unintended path." Uncertainty is represented rather than collapsed.
- **Validity narrows physically in the high-uncertainty region.** The build and test stages handle model-generated code — maximum uncertainty — and are exactly where the system contracts hardest: no secrets, `egress: registries-only`, read-only mounts, hard CPU/memory/time caps, disposable per-puzzle containers.
- **Uncertainty is bounded in time.** `per_puzzle_timeout_s` and `night_budget_s` cap the blast radius of a runaway process; `carry_forward[]` preserves what did not finish.
- Corroboration where available: the tester pairs the LLM solve attempt with "a programmatic checker where applicable (e.g. a CSP solver for logic grids, a frequency-analysis pass for ciphers)" — narrower reliance on model judgment in exactly the domains where a mechanical check exists.

**Gaps:**
- **The headline setting widens rather than narrows.** `require_unique_solution: false` means ambiguity is noted and passed through. Under Principle 8, higher uncertainty should produce *stronger* guarantees; here it produces a note in `test.notes`.
- **No escalation path.** The compendium prescribes refusal, reroute, *or escalate*. There is no human-review queue, no `needs_review` phase, no held state. `ambiguous` advances like everything else.
- **No confidence quantification.** `test.difficulty_actual` is free text ("beginner-medium"); `solver-trace.json` records the path but no confidence score. Uncertainty is described, not measured.
- **Uncertainty does not vary by risk.** A `riddle` and an `arg` breadcrumb pack traverse identical validation. There is no high-risk path with tighter gates.

**Structural Recommendation:** Add a `needs_review` phase that `ambiguous` routes to when `require_unique_solution` is false, so ambiguity is *held* rather than passed. That single enum value converts a noted uncertainty into a narrowed validity region.

### Principle 9: Observability Is a Safety Requirement
**Alignment:** 🟡 Moderate

**Evidence:**
- **Append-only decision log.** `state/activity.ndjson`, 47 events, written as part of `advance-phase` — so a state change cannot occur without its audit record.
- **Reasoning traces, not just outcomes.** `test/solver-trace.json` records *how* the solver reached (or failed to reach) the win condition. Under the compendium's framing — "A system that cannot explain why it acted cannot be governed" — this is the right artifact, and it is unusual to find it built in.
- **Per-stage logs at every boundary:** `state/logs/run-YYYY-MM-DD.txt` per walk, `build/log.txt` with `exit_code` and `duration_s`, `test/log.txt`.
- **Derived state is visible and cheap:** `state.json` carries `counts_by_phase`, `last_run`, `last_cursor`, `carry_forward[]`.
- **Observability by design choice, not accident.** `state/` is deliberately visible rather than `.state/`, documented in both the README and spec §18 decision 6. The facility is built to be inspected with `ls` and `cat`.
- `--dry-run` writes the plan to the run log without executing — the routing decision is observable before it acts.

**Gaps:**
- **Drift went unobserved three separate times.** (1) Three of eighteen records carry out-of-enum `design.type` values. (2) `collections/` is empty despite eighteen puzzles at `phase >= reported` — the curator's declared input — meaning orchestrator step 4 either never ran or silently no-op'd, and no run log flagged it. (3) `state.json` grew `site{}` and `artifacts{}` keys governed by no schema. The system logs what happened well and cannot see what *should* have happened and didn't.
- **Refusals are not aggregated.** The handbook requires invariant checks to be logged; individual aborts presumably print, but nothing counts scrub rejections or leak-guard trips over time. A guard that never fires and a guard that is broken look identical.
- No alerting. A failed nightly walk produces a log line.
- No user-side observability at all: eighteen published artifacts generate zero signal.

**Structural Recommendation:** Have `/puzzle-orchestrator` end each walk with a reconciliation block — records validated / records failing / collections produced / refusals triggered. It converts logs-of-events into observation-of-expectations, which is the gap all three drift instances share.

### Principle 10: Intelligence Resides in Structure
**Alignment:** 🟢 Strong

**Evidence:**
- **The router explicitly disclaims intelligence.** `puzzle-orchestrator/SKILL.md`: "Thin router. Decides nothing the per-puzzle phase doesn't already imply; it just sequences and budgets." Behavior is determined by a data field, and the executor is a lookup table.
- **Behavior lives in configuration.** `manifest.yaml` governs intake channels and marker, sandbox base images per artifact kind, egress policy, CPU/memory/timeouts, allowed design types, solver strictness and time budget, packaging and registry, three egress surfaces with visibility settings, the fifteen-term tag taxonomy, durability, and secret refs. Changing what the system does is a config edit, not a code edit.
- **The schema constrains the space of representable states.** Enums for phase, type, difficulty, artifact kind, and test status mean many invalid states cannot be *expressed*, only unenforced.
- **Extension is structural.** `plugin.json` does not enumerate skills — discovery is by directory, so a new capability is a new folder.
- **The concept spec's own vocabulary maps cleanly:** the atlas is `plugin/skills/`, each chart is a SKILL.md, the manifold is the puzzle lifecycle, transitions are the phase enum, and the router is `puzzle-orchestrator`.

**Gaps:**
- **The one place structure was designed and never built is puzzle mechanics.** Spec §10 names twenty template ids and states "Templates live in `templates/types/<template_id>.template/`"; `puzzle-designer` selects from it; `puzzle-builder` mounts it read-only. It does not exist. So the actual intelligence about *how a Playfair cipher puzzle is constructed* currently resides in model interpretation at generation time — precisely what Principle 10 says does not scale. This is the largest structural hole in the system.
- Prose contracts are interpreted, not executed. The intelligence in `SKILL.md` constrains a model's behavior only as strongly as the model attends to it.

**Structural Recommendation:** Build `templates/types/` even minimally — one template directory per exercised mechanic, carrying the generator parameters and the win-condition shape. kairair-ota's definition-driven generation (definitions YAML → pin maps, diagrams, headers, "never hand-duplicated") is the portfolio's working example of this discipline.

### Principle 11: Additive Scaling Requires Isolation
**Alignment:** 🟢 Strong

**Evidence:**
- **Entities are isolated by construction.** One puzzle, one `PUZ-NNNN-slug/` directory, everything about it inside. Spec §1: "Each puzzle is independent and idempotent." Adding the nineteenth puzzle cannot affect the first eighteen.
- **Execution is isolated per entity.** A disposable per-puzzle container, described in spec §3 as "disposable, per-puzzle". No shared build state.
- **Capabilities are isolated.** Adding a skill is dropping a directory; no registry edit, no import graph.
- **Durable and derived layers are separated.** Spec §4: "`puzzles/` and `collections/` are durable. `state/` is rebuildable." The disposable layer can be deleted without loss.
- **Deployment is isolated per artifact.** `deploy.sh` stages each `puzzles/PUZ-*/artifact/` to its own `/p/<PUZ-id>/`.
- **Relocation is isolated:** `$BAZAAR_ROOT` and `$PUZZLE_STATE_REPO` move either plane without code changes.

**Gaps:**
- **Adding a taxonomy type is not additive.** A ninth puzzle family requires edits in four places: the `design.type` enum in `schemas/puzzle.schema.yaml`, `design.allowed_types` in `templates/manifest.yaml.template`, the §10 table in the spec, and the taxonomy table in the README. The declared extension point entangles four files — and the drift is visible, since three live records use types (`meta`, `modern-crypto`, `stego`) added in the data plane without any of those four edits.
- `manifest.yaml` is a single global config; there is no per-collection or per-family override.
- `allocate-id` scans the directory, so adding an entity is O(n) in existing entities — a mild coupling of new work to existing volume.

**Structural Recommendation:** Make the taxonomy single-sourced. If `manifest.design.allowed_types` were the authority and the schema referenced it (or the docs were generated from it), adding a family would be a one-line change and the three out-of-enum records would never have been possible.

### Principle 12: Governance Must Be Runtime-Enforced
**Alignment:** 🟡 Moderate

**Evidence — runtime-enforced:**
- `state/bazaar.lock` — checked at execution, blocks a second walk.
- The leak scan — runs before any surface call, aborts loudly.
- The deploy `find` guard — runs before `netlify deploy`, aborts the publish.
- Container egress policy and resource caps — enforced by the runtime, unbypassable from inside.
- Timeouts — enforced during execution, converting overrun into a named state.
- Idempotency keys (`source.message_ts`) — checked at write time.

**Evidence — not enforced, or post-hoc:**
- **No pre-commit hooks, no CI.** No `.github/` directory. Nothing gates a commit or a publish of the plugin itself.
- **The schema is unexecuted** — governance by document (Principle 2).
- **The single-writer rule is honor-system** — governance by convention (Principle 3).
- **`validate` is an unimplemented operation**, so the one op whose entire purpose is governance does not run.
- **The four required-setup items** (Docker, `$GHCR_TOKEN`, sops-age refs, mirror remote) are verified by nothing.

**Structural Recommendation:** A single CI job running the validator, `shellcheck`, and a SKILL.md frontmatter lint converts four of the six unenforced items into runtime gates. The handbook's position is direct — "Failure to meet this standard MAY block deployment" — and there is currently nothing capable of blocking anything.

### Principle 13: Evolution Is Mandatory
**Alignment:** 🔴 Weak

**Evidence:**
- Version markers exist: `"version": "0.1.0"` in both `plugin/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`; `version: 0.1` in `templates/manifest.yaml.template`; spec header "Version: 0.1 (draft for lock)".
- Spec §18 "Locked decisions" is an explicit statement that certain choices are settled — a deliberate stability boundary, which the principle does endorse as one half of controlled evolution.
- The manifest anticipates growth: `intake.sources[]` entries are annotated `kind: rss (future)` and `kind: archive (future)`.

**Gaps:**
- **Two commits, no tags, no CHANGELOG.** `4ebd37d` (initial scaffold) and `c9d73dc` (site→deck reorganization). The `0.1.0` in two hand-synced JSON files is the only version marker in existence.
- **Real evolution happened, ungoverned.** `~/bazaar/state/state.json` records `"artifacts": {"version": "v3", "upgraded": 18, "upgraded_at": "2026-08-23T18:05:00Z", "flag_storage": "encrypted-under-solution (logic wing) / sha256-hash (cipher wing)"}`. Eighteen artifacts were migrated in place through at least three versions. Nothing in this repo's spec, schema, skills, or README mentions artifact versioning, the v3 pass, or the flag-storage scheme. A migration occurred and left no trace in the structure that governs it.
- **The taxonomy evolved without a migration.** Three records carry `design.type` values added in practice and never added to the enum.
- **No deprecation policy.** The handbook requires that "Deprecated charts MUST emit telemetry warnings" and "Removal MUST follow a migration plan." Neither concept appears.
- **The spec is frozen at a draft.** Marked "0.1 (draft for lock)" since scaffold, still missing eleven of eighteen sections, while the system it describes has moved on.

**Structural Recommendation:** Add `CHANGELOG.md` starting with the v3 artifact upgrade (currently recorded only in another repo's JSON blob), tag `v0.1.0`, add an `artifacts_version` field to the schema so in-place migrations are representable, and state a deprecation policy for phases and taxonomy types. Evolution is happening; it needs somewhere to be recorded.

### Principle 14: Executors Share the Same Constraints
**Alignment:** 🟢 Strong

**Evidence:**
- **One artifact serves both executor classes.** `plugin/skills/*/SKILL.md` is simultaneously the human-readable documentation and the machine's operating instructions. There is no separate "implementation" for the docs to diverge from — the compendium's ideal case.
- **The facility is designed for human inspection.** `state/` visible rather than `.state/`, an explicitly locked decision (spec §18.6). YAML and NDJSON and JSON, browsable with standard tools. A human executor can audit the same state the pipeline reads.
- **The same phase machine governs both.** A human running `/puzzle-orchestrator --once` and the router walking the queue traverse identical transitions. The deck onboards a human into the exact state machine the system executes.
- **Intake accepts either executor's gesture.** A 🧩 reaction (human-initiated) and a `manifest.intake.sources[]` prompt-seed on a weekly cadence (machine-initiated) both produce the same `candidate` record with the same schema.
- **Errors are legible to both.** `[finding]`-prefixed posts tell a human reader what they are getting; `test.status: unsolvable` tells the router the same thing.

**Gaps:**
- **One executor class is unserved: an agent working *on* the repo.** There is no `CLAUDE.md` or `AGENTS.md`. Every other executor — the pipeline, the operator, the solver, the third-party installer — has a contract. The agent asked to modify the engine has none, and must infer conventions (single-writer, visible `state/`, invariant numbering) from prose scattered across the README and spec.
- Human-facing validity conditions are prose while machine-facing ones are schema — asymmetric enforcement across executor types, which is exactly the divergence the principle warns about.

**Structural Recommendation:** Add `CLAUDE.md` stating the invariants an in-repo agent must preserve: only `/puzzle-state` writes the substrate, `state/` stays visible, the schema is authoritative for `puzzle.yaml`, and solutions never enter this repo. It closes the last unserved executor class in one file.

### Principle 15: Critical Constraints Must Be Unavoidable
**Alignment:** 🟡 Moderate

**Evidence:**
- **The most critical constraint is close to unavoidable.** Solutions cannot be published from the public repo because they are not in it (structural), and if they somehow reached a staging directory the `find` guard aborts the deploy (mechanical), and if they reached an outbound body the ≥40-char scan aborts the publish (mechanical). Three independent layers, two of them machine-enforced, one of them absolute.
- **Locking is unavoidable** — it is step 1 of the walk, not an option.
- **Sandbox constraints are unavoidable** from inside the container: egress policy and resource caps are runtime-enforced.
- **Idempotency is structural, not remembered:** `phase` is both the routing key and the checkpoint, so re-running correctly requires no discipline.

**Gaps — constraints that depend on remembering:**
- **"scrub FIRST"** is an ordering rule stated in the publisher's step list. Nothing prevents a caller from skipping to step 2.
- **Single-writer** depends on every skill author remembering not to write directly.
- **`durability.mirror.remote`** ships `null` with README step 4 saying to set it "before relying on it" — a reminder, which the principle names as the failure mode.
- **`packaging.push_image: true`** with `registry: ghcr.io/davidolsson` ships enabled in the template a third party receives; nothing prevents an attempted push into someone else's namespace.
- **The four required-setup items** are a "make sure you always…" list with no verifier — the compendium's canonical warning sign.
- **Running `validate`** is optional and, in any case, unimplemented.

**Structural Recommendation:** Make `init-facility.sh` refuse to seed a manifest that leaves `durability.mirror.remote` null, and flip `push_image` to `false` in the shipped template. Both convert a remembered constraint into a structural one, and both are one-line changes.

### Principle 16: Structure Is the Primary Output
**Alignment:** 🟢 Strong

**Evidence:**
- **This repo's entire deliverable is structure.** Twenty-nine tracked files, zero dependency manifests, no application code. What ships is a spec, a schema, twelve contracts, two templates, two scripts, and a deck. The artifacts (the puzzles) live elsewhere; this repo produces the shape they are made in.
- **Structure was built before output existed.** The spec's eight invariants, the two-plane topology, the phase machine, and the gating discipline were written before there were any puzzles to gate — the correct ordering under this principle.
- **The organization reveals the architecture.** `plugin/skills/` maps one-to-one onto pipeline stages; `schemas/`, `templates/`, `scripts/`, `deck/` each hold one kind of thing. A reader can infer the system from `ls`.
- **Structural investment is visible in the data plane too:** the v3 upgrade pass rebuilt all eighteen artifacts rather than accepting them as-is — refactoring where features did not change.

**Gaps:**
- **Structure was the output once, at scaffold, and has not been re-invested in since.** Two commits. The spec still has eleven missing sections; `templates/types/` — the single most load-bearing piece of missing structure — was named and never built; `collection.yaml` and `state.json` still have no schema.
- **The data plane out-evolved the structure.** Artifact versioning, flag storage, and two `state.json` keys exist in practice and nowhere in the structure that governs them. That is precisely the compendium's "invisible debt that surfaces only under stress, scale, or change."
- The one structural test of the structure — a validator — does not exist, so structural integrity is asserted rather than verified.

**Structural Recommendation:** Treat the four missing structural pieces as the next deliverable, in this order: the validator, `schemas/state.schema.yaml` + `schemas/collection.schema.yaml`, `templates/types/`, and the spec's unwritten sections marked or filled. This repo's product *is* structure; those four items are its backlog.

## Work Graph View

### Validity Regions Identified

The graph has three tiers.

**Tier 1 — Chart regions (12).** One per skill, each bounded by a phase precondition: intake (`puzzle-harvester-slack`, `puzzle-harvester-sources`), reasoning (`puzzle-researcher`, `puzzle-designer`), fabrication (`puzzle-builder`, `puzzle-tester`, `puzzle-packager`), synthesis (`puzzle-curator`, `puzzle-reporter`), egress (`puzzle-publisher`), and two cross-cutting regions — `puzzle-state` (substrate) and `puzzle-orchestrator` (routing).

**Tier 2 — Plane regions (2).** Host (secrets, reasoning, publishing) and container (untrusted execution, no secrets, registries-only egress). This is the sharpest boundary in the graph because it is enforced by a runtime rather than a contract.

**Tier 3 — Repository regions (3).** Engine (`worksona/puzzle-state`, public), data (`worksona/bazaar-data`, private), and published output (`worksona/bazaar` + Netlify, public). Solution material is valid only in the middle region.

### Interface Contract Quality

| Edge | Contract | Quality |
|---|---|---|
| Chart ↔ chart | `puzzle.yaml` + `phase` enum, schema-defined | **Strong** — one typed shared representation, no ad-hoc payloads |
| Host ↔ container | Declared mounts (`build/` rw, template ro, `artifact/` ro), egress policy, resource caps | **Strong** — the only runtime-enforced edge in the graph |
| Data plane → public site | `deploy.sh` staging rules + `find` abort guard | **Strong** — mechanical, fail-closed |
| Facility → egress surfaces | `manifest.surfaces` config + `outputs.*` fields | **Moderate** — declared but untransactioned; a partial ship is unrepresentable |
| Engine repo ↔ data plane | *None* | **Weak** — no schema for `state.json`; `site{}`, `artifacts{}`, and the flag-storage scheme crossed this edge ungoverned |
| Operator → facility | README + `init-facility.sh` + four unverified prerequisites | **Moderate** — documented, unenforced |
| Spec → implementation | Prose reference to `templates/types/` | **Broken** — four documents point at a region that does not exist |

### Curvature Hotspots

Four regions of concentrated uncertainty, and how the system responds to each:

1. **Generation of untrusted code** (`puzzle-builder`). *Response: containment.* Disposable container, no secrets, registries-only egress, hard caps. **Well-handled** — validity contracts exactly where uncertainty peaks.
2. **Solvability of a generated puzzle** (`puzzle-tester`). *Response: blindfolded adversarial evaluation plus a third outcome value.* **Well-handled in representation, under-handled in routing** — `ambiguous` is recorded and then advances like anything else, because `require_unique_solution: false` widens rather than narrows.
3. **Egress fan-out** (`puzzle-publisher`). *Response: abort-on-leak.* **Half-handled** — the dangerous failure (leak) is refused loudly; the likely failure (partial ship across five surfaces) has no compensation.
4. **The engine ↔ data-plane boundary.** *Response: none.* This is the uncontained hotspot. Two regions evolved independently — artifacts to v3, `state.json` grew two keys, three records adopted types outside the enum — with no contract, no schema, and no observation. Every unnoticed drift in this report crossed this one edge.

### Structural Integrity Assessment

puzzle-state encodes an unusual amount of intelligence in structure: phase-driven routing with a self-declaredly thin router, config-driven behavior through `manifest.yaml`, a strict schema, disposable per-entity execution, and a security guarantee achieved by physical separation rather than by careful code. Where it is strong, it is strong in the way the concept spec describes — *"scaling intelligence by encoding locality, guarantees, and composition directly into system structure."*

Where it falls short, it falls short in one consistent way: **the structure is declared but not executed.** A schema nothing applies. A single-writer rule nothing enforces. A `validate` operation with no implementation. A template tree four documents reference and none created. The compendium's own warning list reads like a checklist of what is missing here — *"Treating charts as documentation only," "Encoding rules only in prompts," "Skipping telemetry."*

The distance between this system and a strong structural rating is small and specific: roughly four files (a validator, two schemas, a CI job) and one directory tree. None of it is architectural rework. The architecture is already right.

## Structural Strengths

1. **Principle 5 — Transitions Are First-Class.** A named nine-value enum, a drawn machine with failure edges, a dedicated `advance-phase` op that moves record + audit + index as one act, and a transition object that doubles as the crash checkpoint.
2. **Principle 6 — Refusal Is Correct Behavior.** Loud aborts at both egress boundaries, exit-on-lock, timeouts that produce named terminal states, and `unsolvable` elevated from an error into a publishable finding.
3. **Principle 1 — Competence Is Always Local.** Twelve single-transition charts with declared inputs and explicit non-goals, plus a physical host/container split that makes locality a runtime property.
4. **Principle 11 — Additive Scaling Requires Isolation.** Per-entity directories, disposable per-entity containers, directory-based capability discovery, and a durable/rebuildable split.
5. **Principle 14 — Executors Share the Same Constraints.** One artifact (`SKILL.md`) serves human and machine; the facility is deliberately visible so a human can audit exactly what the pipeline reads.

## Structural Risks

1. **Principle 13 — Evolution Is Mandatory (🔴).** The data plane migrated eighteen artifacts through three versions and introduced a flag-storage scheme; the engine repo has two commits, no tags, no CHANGELOG, and no field to represent an artifact version. Ungoverned evolution across an uncontracted boundary is the compendium's canonical debt accumulation, and it has already happened.
2. **Principle 7 — Metrics Encode Alignment (🔴).** No north star, no target, no aggregation of the alignment data (`difficulty_target` vs `difficulty_actual`) already sitting on disk. Without metrics, the trade-off decisions that *have* been made — `require_unique_solution: false` most notably — are unreviewable.
3. **Principle 2 — Validity Is a Precondition (🟡, high severity).** Three of eighteen live records were written outside the schema's validity region and persisted. Preconditions that are declared but unexecuted are not preconditions.
4. **Principle 10's one hole — `templates/types/`.** Puzzle mechanics were supposed to live in structure and currently live in model interpretation. Four documents describe the tree; it does not exist.
5. **Principle 4 — Composition (🟡).** Zero integration tests, and the five-surface publish fan-out has no compensation for a partial ship. The compendium says failures concentrate at boundaries; this system verifies none of its boundaries.

## Investment Priorities

| Priority | Principle Gap | Structural Fix | Effort | Impact |
|---|---|---|---|---|
| 1 | P2 Validity · P3 Structural guarantees · P12 Runtime governance | `scripts/validate.py` — walk `$BAZAAR_ROOT/puzzles/*/puzzle.yaml` against `schemas/puzzle.schema.yaml`, exit non-zero | S | Converts a declared precondition into an enforced one; catches the three known-invalid records immediately |
| 2 | P6 Refusal · P3 Structural guarantees | Solution-leak fixture: a `report.md` with a known 60-char solution substring, asserted rejected by `scrub` | S | Puts a test under the system's most consequential refusal path |
| 3 | P12 Runtime governance | `.github/workflows/validate.yml` running the validator, `shellcheck`, and a SKILL.md frontmatter lint | S | Makes every other guarantee runtime-enforced rather than remembered |
| 4 | P10 Intelligence in structure | Create `templates/types/` for the exercised mechanics, carrying generator parameters and win-condition shape | M | Moves puzzle mechanics out of model interpretation and into structure; unblocks the documented build path |
| 5 | P4 Composition · P9 Observability | `schemas/state.schema.yaml` + `schemas/collection.schema.yaml`; orchestrator prints an end-of-walk reconciliation | M | Contracts the engine↔data-plane edge where all observed drift crossed |
| 6 | P13 Evolution | `CHANGELOG.md` (starting with the v3 upgrade), a `v0.1.0` tag, an `artifacts_version` schema field, a deprecation policy | S | Gives ongoing evolution somewhere to be recorded before more debt accrues |
| 7 | P7 Metrics | Define north star + leading + lagging metrics; add one solve counter to `/p/<PUZ-id>/` | M | Makes alignment observable and the `require_unique_solution` trade-off reviewable |
| 8 | P4 Composition · P6 Refusal | Make `puzzle-publisher` idempotent per surface (skip any step whose `outputs.<field>` is populated) | S | Removes the partial-publish orphan state |
| 9 | P8 Uncertainty | Add a `needs_review` phase that `ambiguous` routes to when `require_unique_solution` is false | S | Narrows validity under uncertainty instead of widening it |
| 10 | P15 Unavoidable constraints | `init-facility.sh` refuses a manifest with `durability.mirror.remote: null`; flip `packaging.push_image` to `false` | S | Converts two remembered constraints into structural ones |
| 11 | P14 Executors | `CLAUDE.md` stating the in-repo invariants an agent must preserve | S | Closes the last unserved executor class |
| 12 | P3 Structural guarantees | A `bin/puzzle-state` CLI that other skills shell out to, making single-writer a code path | L | Turns the system's central discipline from convention into structure |

## Portfolio Contribution

Three structural patterns here are worth exporting.

**A guarantee that needs no code to be correct.** The two-repo split means solutions are not merely scrubbed from public output — they are absent from the repo that produces it. Any portfolio project with a public/private output split (notella's synthesis briefs, assess-state's org dossiers, merge-intel's client material) can adopt the same shape.

**Failure states as reserved enum values.** `build-failed` and `tested: unsolvable` are not exceptions; they are members of the phase enum with their own dispatch rows and their own report sense. This makes refusal (P6) a data-modeling decision rather than an error-handling decision, and it generalizes to every pipeline in the portfolio.

**Blindfolded in-pipeline evaluation.** The tester is denied `design.solution_sketch` and `solution.md`, and its output is verified against a declared `win_condition` and corroborated by a programmatic checker where the domain allows. This is a working answer to "how does a generation pipeline grade itself honestly," and it is the strongest handling of curvature (P8) in the portfolio.

What puzzle-state should import in return is enforcement machinery that already exists next door: an executable validator (the-dashes' `scripts/validate.py`), a code-path-enforced substrate writer (sound-flow's `Substrate` class in `src/lib/state.mjs`), and definition-driven generation (kairair-ota's definitions YAML → generated pin maps, wiring, headers, "never hand-duplicated" — exactly what `templates/types/` was meant to be).

## Key Takeaways

- **The architecture is right; the enforcement is half-built.** Eight principles Strong, six Moderate, two Weak — and nearly every Moderate has the same cause: a correct structure with nothing that executes it.
- **The strongest structural guarantee in the system requires no code to run correctly.** Solutions cannot leak from a repo that does not contain them. That instinct — make the bad outcome impossible rather than forbidden — is the most transferable thing here.
- **Transitions are the project's best principle.** A named enum, a drawn machine, an atomic `advance-phase`, and a transition object that doubles as the crash checkpoint.
- **The two weak principles compound.** No metrics (P7) means no signal that evolution is needed; ungoverned evolution (P13) means the drift that metrics would have caught accumulates unseen. Three of eighteen live records already sit outside the schema, and nothing noticed.
- **All drift crossed one uncontracted edge.** The engine repo and the data plane have no interface contract — no schema for `state.json`, no field for artifact versions — and every unobserved change in this report crossed it. Contracting that edge is the highest-value structural work available.

## Cross-References

- [Report 01: Project Overview](./01-project-overview.md) — the engine/data-plane split that defines the graph's outer boundary.
- [Report 01b: Technical Specification](./01b-technical-specification.md) — component architecture, data models, and security architecture.
- [Report 04: Features & Capabilities](./04-features-capabilities.md) — the built/specced/untested inventory behind the P10 and P13 findings.
- [Report 07: Portfolio Position](./07-portfolio-position.md) — where the enforcement machinery named above already exists in sibling projects.
- [Report 08: Technical Readiness](./08-technical-readiness.md) — the engineering evidence, scored across ten dimensions.
- [Report 09: Worksona Leadership Themes](./09-worksona-themes.md) — the execution rubric; complements this structural assessment.
