# puzzle-state Project Documentation — Report 04: Features & Capabilities

> **Project:** puzzle-state | **Generated:** 2026-08-25 | **Repo:** worksona/puzzle-state (public)

## Executive Summary

puzzle-state ships twelve `/puzzle-*` Claude Code skills covering a full puzzle lifecycle from intake to publication, plus a schema, facility templates, an idempotent bootstrap script, and a fifteen-slide onboarding deck. Eighteen puzzles have been carried through the pipeline and are live at https://puzzle-state.netlify.app. This report inventories what actually works, and marks — explicitly and by name — the capabilities that are specced but not built, and the ones that are built but never exercised.

**Status legend used throughout:**

- **Built & exercised** — implemented and demonstrably used in the live facility.
- **Built, unexercised** — the contract exists and is complete; no live puzzle has used it.
- **Specced, not built** — described in the spec, README, or a skill contract; the artifact does not exist.

## 1 · Intake — Getting Things Into the Bazaar

| Feature | What it does | Invocation | Implementation | Status |
|---|---|---|---|---|
| Slack 🧩 harvest | Drains 🧩 reactions in configured channels (default `#development`, self-only) into candidate records; tracks per-channel `message_ts` cursor so nothing re-processes | `/puzzle-harvester-slack` | `plugin/skills/puzzle-harvester-slack/SKILL.md` | Built, unexercised |
| Inbox file drain | Classifies files dropped in `~/bazaar/inbox/` — `.url` → a URL candidate, `.query`/`.txt`/`.md` → a prompt candidate, `.pdf`/`.png`/`.jpg` → reference media attached to `build/inputs/` — then moves processed files to `state/processed-inbox/YYYY-MM-DD/` | `/puzzle-harvester-sources` | `plugin/skills/puzzle-harvester-sources/SKILL.md`; format list written by `scripts/init-facility.sh` into `inbox/README.md` | Built, unexercised |
| Recurring source feeds | Emits a candidate per cadence window from `manifest.intake.sources[]`; `kind: prompt-seed` works today, `rss` and `archive` are marked "(future)" in the contract | `/puzzle-harvester-sources` | same skill, sub-mode B; seed entry in `templates/manifest.yaml.template` | Partially built — `prompt-seed` only |
| Direct query intake | A candidate created with `source.surface: query` and a free-text prompt, bypassing Slack and the inbox | via `/puzzle-state` | `schemas/puzzle.schema.yaml` `source.surface` enum | Built & exercised |

**Evidence on exercise.** All eighteen live records carry `source.surface: query` with `marked_by: keystone@stonemaps.org` — for example `PUZ-0007-meta-cabinet`, whose prompt reads *"Keep building. Chosen next from the ingested compendium's ranked candidates…"*. Neither the Slack path nor the inbox path has produced a live puzzle, and `state/state.json` shows `last_cursor: {}`, confirming no Slack cursor has ever advanced.

## 2 · The Pipeline — Candidate to Published

Eight phases, one skill per stage, dispatched purely by phase.

| Feature | What it does | Invocation | Implementation | Status |
|---|---|---|---|---|
| Research pass | Fetches `source.url`, does bounded web research (≤6 searches, ≤12 fetches), writes `research.md` in five sections — Theme, Mechanics inspiration, Comparables, Source refs, Open hooks — and fills the `research` block. Deliberately non-prescriptive: it may *not* set `design.type` | `/puzzle-researcher` | `plugin/skills/puzzle-researcher/SKILL.md` | Built & exercised |
| Design pass | Picks a taxonomy type and template, writes `design.md` with mechanics, an exact testable win condition, a difficulty target, an estimated solve time, and a short solution sketch | `/puzzle-designer` | `plugin/skills/puzzle-designer/SKILL.md` | Built & exercised |
| Sandboxed build | Renders the artifact inside a per-puzzle Docker container (`build/` mounted rw, templates ro), captures stdout/stderr to `build/log.txt`, records `exit_code` and `duration_s`, copies the result to `artifact/` | `/puzzle-builder` | `plugin/skills/puzzle-builder/SKILL.md` | Built & exercised |
| Playtest | Runs a solver against `artifact/` mounted read-only, **without** access to `design.solution_sketch` or `solution.md`; verifies against `design.win_condition`; writes `test/solver-trace.json` and `test/log.txt`; records `solvable` / `unsolvable` / `ambiguous` | `/puzzle-tester` | `plugin/skills/puzzle-tester/SKILL.md` | Built & exercised |
| Packaging | Emits `deploy/` per artifact kind — `RUN.md` for static and PDF, `Dockerfile` + `compose.yaml` + image build/push for `docker-web`, a zipped pack for `breadcrumb-pack`, a publish receipt for `scsiwyg-post` | `/puzzle-packager` | `plugin/skills/puzzle-packager/SKILL.md` | Partially exercised — `html-static` only |
| Reporting | Composes the public-safe `report.md` (pitch, provenance, build receipt, playtest outcome, how to play, link to the gated solution) and the full `solution.md` (intended path, alternates, leak points, designer notes) | `/puzzle-reporter` | `plugin/skills/puzzle-reporter/SKILL.md` | Built & exercised |
| Three-sense reporting | The reporter frames three outcomes distinctly: `solvable` → "puzzle ships"; `build-failed` → "tried to build, here's what broke"; `unsolvable`/`ambiguous` → "no unique path — a finding". All three advance | `/puzzle-reporter` | same skill, "Three senses" table; spec §2 invariant 5 | Built, unexercised — every live puzzle is `solver_passed: true` |
| Idempotent re-entry | Every stage is a no-op on re-run unless the puzzle is reset to the prior phase; an interrupted night resumes from each puzzle's `phase` | `/puzzle-orchestrator --once` | Idempotency sections in `puzzle-builder`, `puzzle-packager`, `puzzle-orchestrator`, `puzzle-harvester-slack` | Built & exercised |

## 3 · Orchestration and Substrate

| Feature | What it does | Invocation | Implementation | Status |
|---|---|---|---|---|
| Nightly walk | Acquires `state/bazaar.lock`, runs both harvesters, walks puzzles by phase oldest-first dispatching one skill each, runs the curator over `phase >= reported`, refreshes counts, releases the lock | `/puzzle-orchestrator` | `plugin/skills/puzzle-orchestrator/SKILL.md` | Built & exercised |
| Dry-run planning | Logs the plan to `state/logs/run-YYYY-MM-DD.txt` without invoking any write | `/puzzle-orchestrator --dry-run` | same skill, Flags section | Built |
| Single-pass drain | One walk, exit when the queue drains or the budget is hit | `/puzzle-orchestrator --once` | same skill | Built & exercised |
| Budget enforcement | `per_puzzle_timeout_s: 1200` kills a runaway container and marks `build-failed` or `tested: unsolvable`; `night_budget_s: 14400` caps the walk and pushes the remainder to `state.json.carry_forward[]` | automatic | same skill, Budgets section; `manifest.sandbox` block | Built |
| Single-writer spine | The only component permitted to write the facility. Eight ops: `init`, `read`, `write`, `validate`, `allocate-id`, `advance-phase`, `scrub`, `lock`/`unlock` | `/puzzle-state <op>` | `plugin/skills/puzzle-state/SKILL.md` | Built & exercised — except `validate` |
| Id allocation | Scans and returns the next `PUZ-NNNN` or `COL-NNNN` | `/puzzle-state allocate-id PUZ` | same skill | Built & exercised — PUZ-0001…0018 allocated contiguously |
| Activity log | One append-only NDJSON event per substrate write | automatic via the spine | `state/activity.ndjson` | Built & exercised — 47 events |
| Facility validation | "Walk puzzles + collections, validate against schemas" | `/puzzle-state validate` | described in `puzzle-state/SKILL.md` | **Specced, not built** — prose only, no executable behind it. See §7 |

## 4 · Safety and Gating

The capability set that most distinguishes this project. Four independent layers.

| Feature | What it does | Invocation | Implementation | Status |
|---|---|---|---|---|
| Two-plane isolation | Host holds secrets and does reasoning and egress; a disposable per-puzzle container with `egress: registries-only`, 2 CPU, 4 GB builds and runs untrusted generated JS, LaTeX, and solver code. Generated code never executes in the host shell | automatic | spec §3 topology; `manifest.sandbox`; "Runs in the data plane" headers in `puzzle-builder` and `puzzle-tester` | Built & exercised |
| Secret scrub | Redacts known secret values from any outbound text, on every scrub invocation regardless of kind | `/puzzle-state scrub` | `plugin/skills/puzzle-state/SKILL.md`, Solution-redaction section | Built |
| Solution redaction | With `kind=public-output`, also redacts the contents of any referenced `solution.md` and any inline decoded plaintext or answer key | `/puzzle-state scrub kind=public-output` | same section — *"A puzzle published with its solution in the gist body is a defect"* | Built |
| Leak scan | Before any surface call, re-scans the outbound body; if any ≥40-character substring of `solution.md` appears, **abort and fail loudly** | automatic in `/puzzle-publisher` | `plugin/skills/puzzle-publisher/SKILL.md`, "Solution leak guard" | Built |
| Deploy-time private-file guard | `find`s the staging directory for `solution.md`, `puzzle.yaml`, `research.md`, `design.md` and aborts the deploy with exit 1 if any is present | automatic in `bash ~/bazaar/deploy.sh` | `~/bazaar/deploy.sh` | Built & exercised |
| Blind solver | The tester mounts `artifact/` read-only and withholds the solution sketch, so the playtest measures real solvability rather than replaying a known answer | automatic in `/puzzle-tester` | `plugin/skills/puzzle-tester/SKILL.md`, step 2 | Built & exercised |
| In-artifact flag vaults | Answers stored as SHA-256 hashes (cipher wing) or XOR-encrypted under a key derived from the finished board (logic wing), so the answer is not in the page's clear text | automatic in the artifacts | `~/bazaar/state/state.json` → `artifacts.flag_storage`; `PUZ-0007` `win_condition` | Built & exercised — **but undocumented in this repo** |

## 5 · Publishing and Distribution

| Feature | What it does | Invocation | Implementation | Status |
|---|---|---|---|---|
| Public gist | Creates a gist carrying `report.md` plus the artifact payload; records `outputs.gist_url` | `/puzzle-publisher` step 2 | `plugin/skills/puzzle-publisher/SKILL.md` | **Built, unexercised** — `gist_url: null` on all 18 |
| scsiwyg blog post | Composes and auto-publishes a post titled from slug + type + difficulty, body = the scrubbed `report.md`; records `outputs.blog_post_id` | `/puzzle-publisher` step 3 | same skill; `surfaces.blog` in the manifest template | Barely exercised — 1 of 18 has a `blog_post_id` |
| Gated solution gist | Creates a **secret**-visibility gist with `solution.md`; links to it only at the bottom of public surfaces, never inline near hints | `/puzzle-publisher` step 4 | same skill; `surfaces.gist.solution_gist.visibility: secret` | **Built, unexercised** — `solution_gist_url: null` on all 18 |
| work-state event | Emits a `puzzle.published` event carrying the PUZ id, type, difficulty, and three URLs | `/puzzle-publisher` step 5 | same skill; `surfaces.work_state.enabled` | **Built, unexercised** — `work_state_event_id: null` on all 18 |
| Findings publication | When upstream is `build-failed` or `tested:unsolvable`, still ships if `manifest.surfaces.blog.publish_findings`; titles prefixed `[finding]` | automatic | same skill, "Findings sense" | Built, unexercised |
| Static puzzle site | Stages `site/index.html` (also as `404.html`), each `puzzles/*/artifact/` to `/p/<PUZ-id>/`, and the engine's `deck/` to `/deck/`; guards; deploys to Netlify | `bash ~/bazaar/deploy.sh [--draft]` | `~/bazaar/deploy.sh` | Built & exercised — https://puzzle-state.netlify.app |
| Legacy Pages mirror | Publishes the same subset to https://worksona.github.io/bazaar/ | `bash ~/bazaar/deploy-pages.sh` | `~/bazaar/deploy-pages.sh` | Built, legacy |

**The most important discrepancy in this report.** Seventeen of eighteen puzzles sit at `phase: published`, yet across all eighteen records `gist_url`, `solution_gist_url`, and `work_state_event_id` are `null`, and only one carries a `blog_post_id`. In practice `published` has come to mean *"live on the Netlify site via `deploy.sh`"*, not *"went through the three-surface publisher fan-out"*. The publisher contract is complete and the fan-out is essentially untested against reality.

## 6 · Curation and Onboarding

| Feature | What it does | Invocation | Implementation | Status |
|---|---|---|---|---|
| Tag pass | Derives tags from `design.type` + `difficulty_target` + `research.theme` keywords, constrained to `manifest.curation.tag_taxonomy` (8 types + 3 difficulties + 5 tones) | `/puzzle-curator` | `plugin/skills/puzzle-curator/SKILL.md` | Built, unexercised |
| Collection assignment | Scores each puzzle against existing collections on theme overlap, type cohesion, and difficulty arc; may propose a new collection when ≥3 unassigned puzzles share a coherent frame | `/puzzle-curator` | same skill | **Built, unexercised** — `~/bazaar/collections/` is empty |
| Collection index | Writes `collections/COL-NNNN-slug/collection.yaml` with `puzzle_ids[]` plus a magazine-style `index.md` describing the throughline, suggested play order, and difficulty arc | `/puzzle-curator` | same skill | Built, unexercised |
| Onboarding deck | Fifteen dependency-free slides — install, the night shift, positioning, the one idea, two-plane isolation, the lifecycle, the substrate, twelve skills, the sandbox, taxonomy, "unsolvable is a finding", the deploy bundle, publishing fan-out, locked decisions, close. Hash routing, keyboard and touch nav, a HUD, per-slide speaker notes, and print CSS that yields one slide per PDF page | https://puzzle-state.netlify.app/deck/ | `deck/index.html` (96 KB, inline styles) + `deck/deck.js` (196 lines) | Built & exercised |
| Facility bootstrap | Creates `puzzles/`, `collections/`, `inbox/`, `state/logs/`; copies the manifest template; seeds `state.json`, `activity.ndjson`, `cursor.yaml`; writes `inbox/README.md`. Honors `$BAZAAR_ROOT`. Every write guarded — re-running prints `exists: … (left as-is)` | `bash scripts/init-facility.sh` | `scripts/init-facility.sh` | Built & exercised |
| One-plugin marketplace | The repo is directly `/plugin marketplace add`-able; skill discovery is by directory scan, so adding a skill is dropping a `SKILL.md` | `/plugin marketplace add <clone>` then `/plugin install puzzle-state@puzzle-state` | `.claude-plugin/marketplace.json` + `plugin/.claude-plugin/plugin.json` | Built & exercised |

## 7 · Specced but Not Built

Stated plainly, because three separate documents depend on the first item.

| Item | Where it is promised | Reality |
|---|---|---|
| `templates/types/<template_id>.template/` | spec §10 (*"Templates live in `templates/types/<template_id>.template/`"*, naming 20 template ids across 8 families); README taxonomy section; `puzzle-designer/SKILL.md` step 3; `puzzle-builder/SKILL.md` Inputs | **Does not exist.** `ls templates/types` → No such file or directory. `templates/` holds only `manifest.yaml.template` and `puzzle.yaml.template`. Every puzzle built so far was built without it |
| `/puzzle-state validate` | `puzzle-state/SKILL.md` operations table | Prose contract with no executable. Its absence is directly measurable: 3 of 18 live records carry `design.type` values outside the schema enum |
| `collection.schema.yaml` | `puzzle-state/SKILL.md` validate op — *"validate against schemas"* (plural) | `schemas/` contains only `puzzle.schema.yaml` |
| A schema for `state/state.json` | implied by the single-writer/validate discipline | None. Two undocumented top-level keys (`site`, `artifacts`) drifted in unnoticed |
| Spec sections 8, 9, 11–17 | The spec header claims it *"mirrors forge-state §1-§18"* | The file jumps 1,2,3,4,5,6,7 → 10 → 18. Eleven sections were never written |
| Automated tests / CI | `scripts/test-run.sh` is named like a test | Eight lines that `echo` two commands. Asserts nothing, exits 0 regardless. No `.github/` directory |
| `sources[]` kinds `rss` and `archive` | `puzzle-harvester-sources/SKILL.md` sub-mode B | Explicitly marked "(future)" in the contract |
| `durability.mirror.remote` | spec §18 decision 5; README required-setup step 4 | Ships `null` in `templates/manifest.yaml.template`; the durability invariant is unenforced by default |
| In-repo agent instructions | — | No `CLAUDE.md`, no `AGENTS.md`, no `CHANGELOG.md` |

## 8 · Built but Untested in Practice

Six of the eight advertised taxonomy families have never produced a puzzle. The eighteen live records break down as `cipher` ×5, `logic` ×10, plus `meta`, `modern-crypto`, and `stego` ×1 each — the last three being types the schema enum does not permit. Nothing is `paper`, `casual-web`, `arg`, `riddle`, `escape`, or `treasure-hunt`.

That gap cascades. The `docker-web`, `breadcrumb-pack`, `pdf`, and `scsiwyg-post` artifact kinds have no exercised instance, which means the packager's compose/Dockerfile branch, the GHCR push path (`ghcr.io/davidolsson`, `$GHCR_TOKEN`), the zipped breadcrumb pack, and the PDF print pipeline are all specified and unexercised. Every live artifact is `html-static`, and every live artifact directory contains exactly one file: `index.html`.

A related structural finding: seventeen of eighteen puzzle directories contain only `artifact/`, `puzzle.yaml`, and `solution.md`. Only `PUZ-0001-cipher-collection` has the full spec §4 shape (`research.md`, `design.md`, `build/`, `test/`, `deploy/`, `report.md`). The reasoning artifacts the reporter, researcher, and designer contracts promise as files were, for seventeen puzzles, folded into `puzzle.yaml` blocks instead — the research and design *content* is present and detailed in the YAML, but the standalone Markdown files the spec calls for are not on disk.

One more, small but telling: `deck/deck.js` still opens with `/* forge-state deck — vanilla nav, no deps */`, copied from the sibling project and never relabelled.

## Key Takeaways

- **The full twelve-skill lifecycle exists and works** — eighteen puzzles have been carried candidate-to-published and are live, with two documented artifact upgrade passes (widgets v2, then a v3 device-first pass that cut body prose 71%).
- **Intake reality diverges from intake design.** All eighteen puzzles came in as `source.surface: query`. The Slack 🧩 harvester and the inbox drain — the two headline intake paths — have never produced a live candidate; `last_cursor` is still `{}`.
- **The publisher fan-out is the biggest built-but-unexercised surface.** Seventeen puzzles are `published`, yet `gist_url`, `solution_gist_url`, and `work_state_event_id` are null on all eighteen. "Published" currently means "on Netlify".
- **Safety controls are the most complete feature set** — two-plane isolation, scrub, a 40-character leak scan, a deploy-time `find` guard, a blind solver, and hash/XOR flag vaults in the artifacts themselves.
- **Six of eight taxonomy families are untouched,** taking the `docker-web`, `breadcrumb-pack`, `pdf`, and `scsiwyg-post` paths and the whole GHCR push with them.
- **The single most load-bearing missing artifact is `templates/types/`** — referenced by the spec, the README, and two skill contracts, and absent from disk.
- **`validate` is the missing keystone.** It is the one spine operation with no implementation, and its absence is measurable: three live records violate the schema right now.

## Cross-References

- [Report 01: Project Overview](./01-project-overview.md) — what the project is, who it serves, the stack, and how to get started.
- [Report 01b: Technical Specification](./01b-technical-specification.md) — component architecture, data models, command surface, deployment topology, security architecture, and technical decisions.
