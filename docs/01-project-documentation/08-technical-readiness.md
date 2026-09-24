# puzzle-state Project Documentation — Report 08: Technical Readiness

> **Project:** puzzle-state | **Generated:** 2026-08-25 | **Repo:** worksona/puzzle-state (public) | **Version:** 0.1.0 (`1330cac`, 2 commits, no tags)

## Executive Summary

puzzle-state presents an unusual readiness profile: its *outputs* are in production — eighteen puzzles live at https://puzzle-state.netlify.app, seventeen at `phase: published`, two artifact upgrade passes completed — while its *engine repo* is a two-commit v0.1 scaffold with no tests, no CI, and a spec missing eleven of the eighteen sections it claims to mirror. Security is the standout dimension: solution gating is enforced by three independent mechanisms, one of which (the two-repo split) is structural rather than procedural. The standout gap is verification: nothing in the repo executes, so the schema is never applied, the guards are never exercised, and drift accumulates unobserved — three of the eighteen live records already carry `design.type` values the schema does not permit.

**Context note for every rating below:** this is a single-operator, human-triggered, local-first facility with zero runtime dependencies and no multi-user surface. Ratings are calibrated to that ambition, not to a hosted SaaS. Where a dimension is rated low, it is because the project's *own* stated guarantees are unverified — not because it lacks machinery it never claimed to need.

## Readiness Scorecard

| Dimension | Score | Maturity | Evidence | Gap |
|---|---|---|---|---|
| Test Coverage & Quality | 1/5 | 🔴 Critical | `scripts/test-run.sh` is eight lines of `echo`; `puzzle-tester` is a real domain-testing stage | No executable test asserts anything; the security-critical guards are untested |
| CI/CD & Deployment | 2/5 | 🟠 Developing | `~/bazaar/deploy.sh` stages, guards, and deploys; `netlify.toml` documents the link | No `.github/` directory at all; deployment is manual and unreviewable |
| Code Quality & Consistency | 3/5 | 🟡 Functional | `set -euo pipefail` + idempotent guards in Bash; strict `additionalProperties: false` schema; uniform SKILL.md frontmatter | No linter of any kind; copy-fork residue (`/* forge-state deck */`) unremoved |
| Documentation | 3/5 | 🟡 Functional | 7.7 KB README, 10.6 KB normative spec, 12 skill contracts, 15-slide deck with speaker notes | Spec jumps §7 → §10 → §18; `templates/types/` referenced by three docs and absent; contradictory install instructions |
| Security Posture | 4/5 | 🟢 Mature | Three-layer solution gating; two-plane isolation; sops-age refs only; registries-only egress; private data plane | Every control is unverified; `durability.mirror.remote` ships `null` |
| Observability & Monitoring | 3/5 | 🟡 Functional | Append-only `state/activity.ndjson` (47 events), per-run logs, `build/log.txt`, `test/log.txt`, `solver-trace.json` | Drift is provably unobserved: 3 invalid records, an empty `collections/`, two undocumented `state.json` keys |
| Dependency Health | 4/5 | 🟢 Mature | Zero dependency manifests in 29 tracked files; no lockfile to rot; no CVE surface | Docker base images pinned to mutable tags (`node:20`, `ubuntu:24.04`), not digests; deck depends on Google Fonts |
| Scalability Readiness | 3/5 | 🟡 Functional | Per-puzzle isolation; explicit budgets (1200 s/puzzle, 14400 s/night); `carry_forward[]`; lock prevents double-walk | `allocate-id` is a directory scan; single-writer forecloses parallelism; `PUZ-NNNN` caps at 9999 |
| Error Handling & Resilience | 4/5 | 🟢 Mature | `build-failed` and `unsolvable` advance rather than halt; timeouts map to named terminal states; `phase` is the resume checkpoint; publisher ABORTs loudly | Five-step publish fan-out has no transaction or compensation for a partial ship |
| Developer Experience | 3/5 | 🟡 Functional | One idempotent script from clone to facility; three-step quickstart; MIT; self-contained marketplace | Quickstart step 2 does nothing; four heavy prerequisites with no verifier; first real build hits a missing template tree |

**Overall: 30/50 — 🟡 Functional (3.0/5)**

## Detailed Assessments

### 1. Test Coverage & Quality — 🔴 Critical (1/5)

**Evidence:**
- `scripts/test-run.sh` is the only file named like a test. In full, after `set -euo pipefail`, it runs five `echo` statements telling a human to type `/puzzle-orchestrator --dry-run` and `/puzzle-orchestrator --once`. It executes nothing and exits 0 unconditionally.
- `schemas/puzzle.schema.yaml` is a well-formed JSON Schema 2020-12 document with `required: [id, slug, phase, created, updated, source]`, `additionalProperties: false` on every object, and regex-constrained id patterns. Nothing in the repo runs it.
- `/puzzle-state validate` is documented as "walk puzzles + collections, validate against schemas" — a row in a Markdown table in `plugin/skills/puzzle-state/SKILL.md`, with no implementation behind it.
- **Credit where due:** `plugin/skills/puzzle-tester/SKILL.md` defines a genuine testing stage. It spawns a solver container with `artifact/` mounted read-only, runs a solver "WITHOUT access to `design.solution_sketch` or `solution.md`", verifies against `design.win_condition`, and records `solvable` / `unsolvable` / `ambiguous` with a `test/log.txt` and `test/solver-trace.json`. That is domain testing, and it is well-designed.

**Gaps:**
- The single most important property in the system — solutions never reaching a public surface — is protected by three mechanisms and verified by none. There is no fixture that plants a solution string in a report body and asserts the scrub catches it.
- The schema's non-application is not hypothetical. Across `~/bazaar/puzzles/*/puzzle.yaml`, `design.type` values break down as: `logic` ×10, `cipher` ×5, and then `meta`, `modern-crypto`, and `stego` ×1 each. The last three are not in the schema's eight-value enum. Three of eighteen live records would fail validation today.
- No `.github/` directory, so nothing runs even if a test existed.

**Recommendation:** Write one Python or Node script, `scripts/validate.py`, that walks `$BAZAAR_ROOT/puzzles/*/puzzle.yaml` against `schemas/puzzle.schema.yaml` and exits non-zero on failure. the-dashes already ships this exact shape (`scripts/validate.py`, run before deploy). Then add a golden-file leak test: a `report.md` fixture containing a known 60-character solution substring, asserted to be rejected. Two files close the entire dimension.

### 2. CI/CD & Deployment — 🟠 Developing (2/5)

**Evidence:**
- There is no `.github/` directory. Nothing lints, tests, builds, scans, or gates.
- Deployment is nonetheless real and defensive. `~/bazaar/deploy.sh` stages `site/index.html` (also copied to `404.html`), each `puzzles/PUZ-*/artifact/` into `/p/<PUZ-id>/`, and `$PUZZLE_STATE_REPO/deck/` into `/deck/`; then at line 38 runs `find "$STAGE" \( -name 'solution.md' -o -name 'puzzle.yaml' -o -name 'research.md' -o -name 'design.md' \) | grep -q .` and aborts if anything matches; then `netlify deploy --dir <stage> --site 4c4e7ff5-… --prod`. `--draft` switches to a non-prod deploy.
- Plugin distribution is a genuine two-path story: root `.claude-plugin/marketplace.json` with `source: "./plugin"` makes the repo directly installable, and locally a symlink installs it as `puzzle-state@local-desktop-app-uploads`.
- `netlify.toml` carries an honest header comment: "The site is NOT built from this repo." `publish = "deck"` is documented as a fallback for ad-hoc CLI deploys.

**Gaps:**
- Environments: one. There is no staging URL; `--draft` is the only rehearsal mechanism and nothing in the README mentions using it.
- Rollback: unaddressed. Netlify retains prior deploys, but no script, doc, or runbook says so or names the recovery step.
- The deploy guard — the last line of defense against publishing a solution — lives in a script in a *different repo* than the spec that mandates it, and changes to it are reviewed by nobody.
- `.gitignore` excludes `.netlify`, yet `.netlify/state.json` and `.netlify/netlify.toml` are present on disk, as is a `.DS_Store` at the repo root. The ignore rules and the working tree disagree.

**Recommendation:** Add a minimal `.github/workflows/validate.yml` that runs the validator from dimension 1 plus a YAML-lint of every `SKILL.md` frontmatter block, on push. Separately, move the private-file guard from `deploy.sh` into a committed, testable script in *this* repo that `deploy.sh` sources — so the guard and the invariant that mandates it live together.

### 3. Code Quality & Consistency — 🟡 Functional (3/5)

**Evidence:**
- `scripts/init-facility.sh` is disciplined Bash: `set -euo pipefail`, `ROOT="${BAZAAR_ROOT:-$HOME/bazaar}"`, and every single write guarded by `if [[ ! -f … ]]` with an explicit `else echo "exists: … (left as-is)"` branch. Genuinely idempotent, and readable.
- All twelve `SKILL.md` files follow one shape: YAML frontmatter with `name` and a `description` carrying trigger phrases, then an H1, then sections drawn from a consistent vocabulary (`## When to use`, `## Inputs`, `## Behavior`, `## Outputs`, `## Idempotency`, `## Non-goal`). 414 lines total — the contracts are terse because they are contracts.
- The schema is strict by construction: `additionalProperties: false` at every level, enums for `phase`, `design.type`, `design.difficulty_target`, `build.artifact_kind`, `test.status`, `source.surface`, and regex patterns for `id` and `slug`.
- `deck/deck.js` is 196 lines of dependency-free vanilla JS; `deck/index.html` is 785 lines with an inline `:root` design-token block.

**Gaps:**
- Zero linters. No ESLint, Prettier, shellcheck, yamllint, or markdownlint config exists. Consistency here is achieved by one author's discipline, which does not survive a second author.
- Copy-fork residue: `deck/deck.js` line 1 is `/* forge-state deck — vanilla nav, no deps */`. Small, but it is the kind of artifact that tells a reader the fork was never audited.
- The schema is strict and the live data is not. Nothing reconciles them, so strictness currently buys nothing.

**Recommendation:** Add `shellcheck` for the two scripts and a `yamllint`/frontmatter check for the twelve skills in the same CI job as the validator. Fix the deck header comment.

### 4. Documentation Completeness — 🟡 Functional (3/5)

**Evidence:**
- The README (7.7 KB) is unusually complete for a v0.1: a "Where everything lives" table naming every repo and URL, a repo-layout block, a three-step quickstart, the full facility tree, the unit of work, an eight-row taxonomy table, the two-plane explanation, all twelve skills one-lined, a locked-configuration table, four required-setup items, and install instructions.
- `puzzle-state-spec.md` is normative and well-structured where it exists: eight numbered invariants, an ASCII topology diagram distinguishing host from container, a complete facility tree, a fully-populated `puzzle.yaml` example, an ASCII phase machine with failure branches, and §18 "Locked decisions" with six entries.
- Inline documentation is the *product*: the twelve SKILL.md contracts are simultaneously the developer docs and the machine's operating instructions.
- `deck/index.html` carries per-slide `data-speaker-notes` and `@media print` rules with `page-break-after` for one-slide-per-page PDF export.

**Gaps:**
- **The spec has holes.** Its header claims "Architecture mirrors forge-state §1-§18" but the file runs 1, 2, 3, 4, 5, 6, 7 → 10 → 18. Sections 8, 9, and 11–17 were never written. A reader following the forge-state correspondence will look for them.
- **Three documents reference a directory that does not exist.** Spec §10 says "Templates live in `templates/types/<template_id>.template/`" and names twenty template ids; the README repeats it; `plugin/skills/puzzle-designer/SKILL.md` says the designer chooses from it; `plugin/skills/puzzle-builder/SKILL.md` lists it as an input and a read-only container mount. `templates/` contains exactly two files: `manifest.yaml.template` and `puzzle.yaml.template`.
- **Engine docs lag the data plane.** `~/bazaar/state/state.json` records `"artifacts": {"version": "v3", "upgraded": 18, "flag_storage": "encrypted-under-solution (logic wing) / sha256-hash (cipher wing)"}` and a `"site": {…}` block. Neither artifact versioning, nor the flag-storage scheme, nor those state keys appear anywhere in this repo's spec, schema, skills, or README.
- No `CHANGELOG.md`, no `CONTRIBUTING.md`, no `CLAUDE.md` or `AGENTS.md`. An agent working in this repo has no in-repo operating instructions.
- The install instructions contradict themselves (see Report 07).

**Recommendation:** Three targeted edits, cheap and high-value: (1) mark the missing spec sections explicitly as "not yet written" so their absence is intentional rather than confusing; (2) either create `templates/types/` or change three documents to describe what actually happens; (3) add a `CHANGELOG.md` starting with the v3 artifact upgrade, which is currently recorded only in a JSON blob in another repo.

### 5. Security Posture — 🟢 Mature (4/5)

**Evidence:**
- **Solution gating at three independent layers.** (a) `/puzzle-state scrub kind=public-output` MUST redact secret values, the contents of any referenced `solution.md`, and "any decoded plaintext / answer key / cheat string embedded inline" — closing with "A puzzle published with its solution in the gist body is a defect." (b) `puzzle-publisher` step 1 is scrub-first, and its "Solution leak guard" section states: "If any substring of solution.md ≥40 chars appears in the body, ABORT and fail loudly." (c) `~/bazaar/deploy.sh` line 38 aborts the deploy if `solution.md`, `puzzle.yaml`, `research.md`, or `design.md` reached the staging directory.
- **A fourth layer that is structural rather than procedural.** Solutions live in `worksona/bazaar-data` (private). The public repo cannot leak them because it does not contain them. This is the strongest guarantee in the system precisely because no code has to run correctly for it to hold.
- **Two-plane isolation.** `puzzle-builder` and `puzzle-tester` both open with "Runs in the data plane" and state that generated code "touches the host only as bytes-on-disk written from inside the container." `manifest.sandbox.egress: registries-only` — "No outbound calls to user-controlled domains from inside the build."
- **Secrets never enter the repo.** `manifest.secrets` names a store (`sops-age`) and five refs by name (`anthropic, slack, github, scsiwyg, ghcr`). Grepping the 29 tracked files turns up no key material — only ref names and a `$GHCR_TOKEN` env-var reference in the README.
- Least-privilege containers: cpu 2, memory 4g, `per_puzzle_timeout_s: 1200`, artifact mounted read-only for the tester, template mounted read-only for the builder.

**Gaps:**
- Every one of the three procedural layers is unverified. The ≥40-character rule in particular is a heuristic with a failure mode nobody has probed: a solution key shorter than 40 characters, or one reformatted between `solution.md` and the report body, passes the guard.
- `durability.mirror.remote` ships as `null` in the template, and the README's required-setup item 4 says to set it "before relying on it" — so the durability invariant is off by default and enforced by memory.
- `packaging.push_image: true` with `registry: ghcr.io/davidolsson` is enabled by default in the shipped template, meaning a third-party installer's default configuration attempts to push to someone else's registry namespace.

**Recommendation:** Ship a leak-guard test fixture (dimension 1). Change `durability.mirror.remote: null` to a commented-out required field so `init-facility.sh` can refuse to seed a manifest without it. Flip `packaging.push_image` to `false` in the shipped template.

### 6. Observability & Monitoring — 🟡 Functional (3/5)

**Evidence:**
- `state/activity.ndjson` is append-only and populated: 47 events. `advance-phase` is defined as one atomic act that updates `puzzle.yaml`, appends an activity event, and refreshes `state.json` counts — so state changes and their audit record are produced together.
- `state/state.json` carries `counts_by_phase`, `last_run`, `last_cursor`, `carry_forward[]`. Live values: `{"reported": 1, "published": 17}`, `last_run: 2026-08-23T18:05:00Z`.
- Per-stage artifacts: `state/logs/run-YYYY-MM-DD.txt` per orchestrator walk, `build/log.txt` with `build.exit_code` and `build.duration_s`, `test/log.txt`, and `test/solver-trace.json`. The solver trace is decision logging in the strict sense — it records *how* the solver reached the win condition, not merely that it did.
- `--dry-run` writes the plan to the run log without invoking writes.

**Gaps:**
- **Drift is provably unobserved.** Three things went unnoticed in the live facility: (1) three records with out-of-enum `design.type` values; (2) `collections/` is empty despite eighteen puzzles at `phase >= reported`, meaning orchestrator step 4 (`/puzzle-curator`) either never ran or silently produced nothing; (3) `state.json` grew `site{}` and `artifacts{}` keys that no schema in this repo describes. The logging is good enough to reconstruct what happened and not good enough to notice what should have happened and didn't.
- `state/state.json` has no schema at all — which is exactly how (3) occurred.
- No alerting. A failed nightly walk produces a log line and nothing else.
- No user-side observability: the public site has no analytics, so nobody knows whether any of the eighteen puzzles has ever been solved by a visitor.

**Recommendation:** Add `schemas/state.schema.yaml` and `schemas/collection.schema.yaml` and include them in the validator. Have `/puzzle-orchestrator` end its walk by printing a three-line reconciliation — records validated, records failing, collections produced — so a no-op curator is visible in the run log rather than only in a directory listing.

### 7. Dependency Health — 🟢 Mature (4/5)

**Evidence:**
- There is no `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `requirements.txt`, or `platformio.ini` anywhere in 29 tracked files. There is no lockfile, therefore no lockfile rot, no transitive CVE surface, and no supply-chain exposure from the repo itself.
- The deck is dependency-free by construction: `deck/deck.js` is 196 lines of vanilla JS with the comment "no deps".
- Runtime dependencies are declared as *configuration*, not code: `manifest.sandbox.base_images` names `node:20` and `ubuntu:24.04`; `manifest.secrets.refs` names five secret refs; `manifest.surfaces` names three egress services.

**Gaps:**
- Docker base images are pinned to mutable tags, not digests. `node:20` on two different nights is two different images, which quietly undermines spec §2 invariant 6 ("Every published puzzle carries the exact prompt, seed, source-refs, and build commands that produced it") — the build commands are carried, the build *environment* is not.
- `deck/index.html` loads Montserrat and JetBrains Mono from `fonts.googleapis.com`. This is the only external asset dependency in the repo, and it makes the onboarding deck depend on network availability and a third-party CDN.
- Service dependencies (Slack, GitHub Gists, scsiwyg, GHCR, Netlify, Anthropic) are all single-provider with no documented fallback. Appropriate for the scope, worth naming.

**Recommendation:** Pin base images by digest in the manifest template and record the resolved digest in `build.base_image` so §2.6 reproducibility is actually true. Self-host or system-stack the two deck fonts.

### 8. Scalability Readiness — 🟡 Functional (3/5)

**Evidence:**
- The horizontal unit is a directory: one puzzle, one folder, one disposable container. Nothing is shared between puzzles at build time.
- Budgets are explicit and enforced at two levels: `per_puzzle_timeout_s: 1200` "kills any single puzzle's container after the limit; marks `build-failed` or `tested: unsolvable` accordingly", and `night_budget_s: 14400` caps total wall clock with remaining puzzles carried in `state.json.carry_forward[]`.
- `state/bazaar.lock` is acquired as step 1 of the walk; "If held, exit (another run is active)."
- `puzzles/` and `collections/` are durable while `state/` is "rebuildable" (spec §4) — the derived layer can be discarded and regenerated.

**Gaps:**
- `allocate-id` is specified as "scan and return next id" — an O(n) directory walk on every allocation, and a race if the lock ever fails to hold.
- Single-writer forecloses parallelism entirely. Eighteen puzzles is comfortable; two hundred puzzles at a 1200 s per-puzzle ceiling would exceed the nightly budget on a single stage.
- `PUZ-[0-9]{4}` caps the namespace at 9,999 records. Not a near-term concern, but it is a schema-level decision that would require a migration.
- `deploy.sh` re-stages every artifact on every deploy; there is no incremental path.

**Recommendation:** No action needed at current scale. If throughput becomes a concern, the cheapest first move is to allow parallel *sandbox* work (builder/tester) while keeping substrate writes serialized through the spine — the two-plane split already makes that separation available.

### 9. Error Handling & Resilience — 🟢 Mature (4/5)

**Evidence:**
- **Failure is designed, not caught.** Spec §2 invariant 5 — "Unsolvable is terminal-with-findings. A failed playtest advances to a report, not a halt." `puzzle-builder`: "On failure: `build.status: build-failed`, advance to `build-failed`. **This still advances**." The phase enum reserves a value for the failure state, so a failed puzzle is a valid record rather than a stuck one.
- Timeouts do not produce ambiguity: exceeding `per_puzzle_timeout_s` "marks `build-failed` or `tested: unsolvable` accordingly" — a named terminal state, not a partial result.
- **Resumability is structural.** "Re-running an interrupted night picks up where it stopped via per-puzzle phase." The `phase` field is simultaneously the routing key and the checkpoint, so crash recovery requires no separate journal.
- **Loud refusal over quiet degradation.** The publisher's leak guard says "ABORT and fail loudly." `deploy.sh` aborts on private-file detection. The orchestrator exits rather than queueing when the lock is held.
- Idempotency is stated per-skill: the Slack harvester keys on `source.message_ts` ("A message reacted twice produces one candidate"); the builder's "re-run after `built` is a no-op unless the puzzle is reset to `designed`."

**Gaps:**
- **The publish fan-out is not transactional.** `puzzle-publisher` runs five sequential steps writing `outputs.gist_url`, `outputs.blog_post_id`, `outputs.solution_gist_url`, then `outputs.work_state_event_id`, then advances phase. If step 3 (scsiwyg) fails after step 2 (gist) succeeded, the record sits at `reported` with a live public gist and no compensation path. The schema has no field to represent partial egress, and no skill describes cleanup.
- No retry-with-backoff on any external call. A transient Slack or GitHub failure is a failed run.
- No rollback path for a bad Netlify deploy is documented anywhere.

**Recommendation:** Make the publisher idempotent per surface — check `outputs.<field>` before each step and skip if already populated, so a re-run resumes rather than duplicates. That single change converts a five-step fan-out into a resumable one without needing a transaction.

### 10. Developer Experience — 🟡 Functional (3/5)

**Evidence:**
- Clone to running facility is one command: `bash scripts/init-facility.sh`, idempotent, honors `$BAZAAR_ROOT`, creates four directories, copies a manifest from template, seeds `state.json`, touches `activity.ndjson` and `cursor.yaml`, and writes an `inbox/README.md` documenting the accepted drop formats (`*.url`, `*.md`, `*.txt`, `*.query`, `*.pdf`, `*.png`, `*.jpg`).
- The shipped manifest has sensible defaults throughout — sandbox limits, a `require_unique_solution: false` that avoids failing on ambiguity, an eight-type allowed list, a fifteen-term tag taxonomy.
- Two env vars relocate either plane without editing code: `$BAZAAR_ROOT` and `$PUZZLE_STATE_REPO`.
- Adding a skill is dropping a `plugin/skills/<name>/SKILL.md` — `plugin.json` does not enumerate skills, so discovery is by directory.
- The 15-slide deck is a real onboarding asset with speaker notes, keyboard/touch navigation, hash routing, and print-to-PDF CSS.

**Gaps:**
- Quickstart step 2 — "Smoke-test the orchestrator in dry-run mode: `bash scripts/test-run.sh`" — does nothing. A new user's first feedback signal is a no-op that looks like success.
- Required setup is four heavy prerequisites (Docker Desktop, `$GHCR_TOKEN` with `write:packages`, a sops-age store with five refs, a private mirror repo) with no verification script. A user who has none of them will discover it mid-pipeline.
- The first real build hits a missing directory: `puzzle-designer` picks a template id, `puzzle-builder` mounts `templates/types/<template_id>.template/` read-only, and that tree does not exist.
- No `CONTRIBUTING.md`, no pre-commit hooks, no `Makefile`.

**Recommendation:** Turn `scripts/test-run.sh` into a real preflight — check for `docker info`, `$GHCR_TOKEN`, the manifest, and `templates/types/`, and report each pass/fail. It is the same eight lines' worth of effort and converts the quickstart's dead step into the project's most useful one.

## Top Strengths

1. **Security by structure, not by care.** Solutions cannot leak from the public repo because they are not in it. The two-repo split (`worksona/puzzle-state` public, `worksona/bazaar-data` private) is a guarantee that holds even if every line of guard code is wrong — and it is backed by three further runtime layers (`scrub`, the ≥40-char leak scan, the `deploy.sh` `find` abort).
2. **A failure doctrine that produces output instead of silence.** `build-failed` and `tested: unsolvable` advance to `reported` and publish with a `[finding]` prefix. The phase enum reserves values for them, the orchestrator dispatch table routes them, and the reporter has a failure sense. Most pipelines lose their failures; this one ships them.
3. **Zero dependency surface.** 29 tracked files, no manifest, no lockfile, no CVE exposure, no upgrade treadmill. The runtime dependencies that do exist (Docker images, five secret refs, three egress services) are declared as configuration in `manifest.yaml`, where they are visible and swappable.

## Top Risks

1. **The specced build path cannot be followed as written.** `templates/types/` is named by spec §10 (twenty template ids), the README, `puzzle-designer/SKILL.md`, and `puzzle-builder/SKILL.md` as a read-only container mount — and does not exist. The eighteen existing puzzles were therefore built by a path the documentation does not describe. **Impact:** a third-party installer following the README reaches a dead end; the operator's own practice and the contract have silently diverged, which is the exact condition the contracts were written to prevent.
2. **Nothing verifies anything, and drift has already occurred.** Three of eighteen live records carry `design.type` values outside the schema enum (`meta`, `modern-crypto`, `stego`); `state.json` grew two undocumented keys; `collections/` is empty despite eighteen eligible puzzles. **Impact:** the schema, the single-writer rule, and the three solution guards are all currently claims rather than guarantees. The first time one of them is wrong, the discovery mechanism is a live incident.
3. **Six of eight advertised taxonomy families have never been exercised.** All eighteen puzzles are cipher-wing or logic-wing. `paper`, `casual-web`, `arg`, `riddle`, `escape`, and `treasure-hunt` have no instance — and with them, the `pdf`, `docker-web`, and `breadcrumb-pack` artifact kinds and the entire GHCR push path are untested end to end. **Impact:** the plugin advertises a capability surface roughly four times larger than the one that has ever run.

## Recommended Investments

| Priority | Investment | Effort | Impact | Rationale |
|---|---|---|---|---|
| 1 | Write `scripts/validate.py` — walk `$BAZAAR_ROOT/puzzles/*/puzzle.yaml` against `schemas/puzzle.schema.yaml`, exit non-zero on failure | S | Converts a strict schema from decoration into enforcement; catches the three known-invalid records immediately | the-dashes already ships this exact script shape; three records are wrong right now and nobody knew |
| 2 | Add a solution-leak test fixture: a `report.md` containing a known 60-char solution substring, asserted rejected by the scrub op | S | Puts a test under the system's single most important guarantee | The three-layer defense is the project's best design and its most consequential untested surface |
| 3 | Resolve the `templates/types/` contradiction — create the tree, or amend spec §10, the README, and two SKILL.md files to describe reality | M | Restores agreement between contracts and practice; unblocks third-party install | Four documents currently describe a directory that does not exist |
| 4 | Add `.github/workflows/validate.yml` running the validator, `shellcheck`, and a SKILL.md frontmatter lint on push | S | Makes every subsequent guarantee runtime-enforced instead of remembered | Investments 1 and 2 have no teeth without something that runs them |
| 5 | Make `puzzle-publisher` idempotent per surface — skip any step whose `outputs.<field>` is already populated | S | Turns a five-step fan-out into a resumable one; removes the partial-publish orphan state | The only resilience gap in an otherwise strong dimension |
| 6 | Add `schemas/collection.schema.yaml` and `schemas/state.schema.yaml`; have the orchestrator print a reconciliation summary at end of walk | M | Closes the drift blind spot that let `site{}`/`artifacts{}` and an empty `collections/` go unnoticed | Both artifacts are written today with no schema governing them |
| 7 | Turn `scripts/test-run.sh` into a real preflight (docker, `$GHCR_TOKEN`, manifest, templates) | S | Removes the dead step from the quickstart; surfaces missing prerequisites before the pipeline does | Currently the new user's first experience is a no-op that resembles success |
| 8 | Pin sandbox base images by digest and record the resolved digest in `build.base_image` | M | Makes spec §2 invariant 6 (reproducibility) actually true | `node:20` is a mutable tag; the recorded build environment is currently approximate |
| 9 | Exercise one non-cipher, non-logic family end to end — a `paper` PDF is the cheapest — and one `docker-web` puzzle to prove the GHCR path | L | Validates 3 of 5 artifact kinds and the packaging push that have never run | Six of eight advertised families are unproven |
| 10 | Add `CHANGELOG.md` (starting with the v3 artifact upgrade), `CLAUDE.md`, and tag `v0.1.0` | S | Gives the repo a version history and an agent working in it an operating contract | Two commits, no tags, and a major data-plane upgrade recorded only in another repo's JSON |

## Production Readiness Verdict

**⚠️ Production Ready with Caveats — for its author-operator. 🚧 Needs Investment Before Production — as a distributable plugin.**

For the operator who built it, the system is already in production and behaving: eighteen puzzles shipped, seventeen published, two artifact upgrade passes completed, a live public site, and a deploy script with a real abort guard between the private data and the public web. The security design is the strongest in the portfolio and its most important layer is structural rather than procedural.

For anyone else, the README's install path leads to a facility whose designer and builder both read from a `templates/types/` tree that does not exist, whose smoke test asserts nothing, and whose default manifest pushes images to `ghcr.io/davidolsson`. Four small investments — a validator, a leak test, a CI job, and resolving the templates contradiction — move it across that line, and three of the four are afternoon-sized.

## Key Takeaways

- The outputs are production-grade; the engine repo is a v0.1 scaffold. Both statements are true simultaneously, and the gap between them is where every risk in this report lives.
- Solution gating is the design's best work: four layers, one of them structural (solutions are absent from the public repo, not merely scrubbed from it).
- Nothing in this repo executes. The schema, the single-writer rule, the scrub, the leak scan, and the `validate` op are all currently claims — and three live records already contradict one of them.
- Failure handling is a genuine strength: `build-failed` and `unsolvable` are reserved enum values that advance to publication with a `[finding]` prefix, and `phase` doubles as the crash-recovery checkpoint.
- Every top-priority remediation is small, and most have a working reference implementation elsewhere in the portfolio — an executable validator in the-dashes, a code-enforced substrate writer in sound-flow.

## Cross-References

- [Report 01: Project Overview](./01-project-overview.md) — what the project is and the engine/data-plane split.
- [Report 01b: Technical Specification](./01b-technical-specification.md) — component architecture, data models, and security architecture.
- [Report 04: Features & Capabilities](./04-features-capabilities.md) — what runs today, what is specced but unbuilt, what is built but untested.
- [Report 07: Portfolio Position](./07-portfolio-position.md) — where the remediation reference implementations already exist in sibling projects.
- [Report 09: Worksona Leadership Themes](./09-worksona-themes.md) — the measurement gap in leadership terms.
- [Report 10: Worksona First Principles](./10-worksona-first-principles.md) — the structural reading of the same evidence.
