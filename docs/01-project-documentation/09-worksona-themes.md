# puzzle-state Project Documentation — Report 09: Worksona Leadership Themes

> **Project:** puzzle-state | **Generated:** 2026-08-25 | **Repo:** worksona/puzzle-state (public)

*Assessed against the seven commands of the Worksona Leadership Runbook (`worksona-themes` skill, bundled reference `worksona-leadership-runbook.md`). Every rating below traces to one of those seven commands; none are invented. For the complementary structural rubric, see [Report 10](./10-worksona-first-principles.md).*

## Executive Summary

puzzle-state is a map-first project that shipped: the spec was written before the scaffold, the phase machine was drawn before it ran, and eighteen puzzles are live at https://puzzle-state.netlify.app. It is strongest on `/map-before-make`, `/demonstrate-not-decorate`, and `/mandate-interoperability` — the spec, the working bazaar, and a public JSON Schema with a resolvable `$id` are all real. It is weakest, by a wide margin, on `/enforce-measurement`: the facility counts its own throughput (`counts_by_phase: {published: 17, reported: 1}`) but has no metric for whether a single visitor has ever solved a single puzzle. The most interesting theme it contributes to the portfolio is *published failure* — a pipeline whose contracts make "this puzzle has no unique solution" a shippable result rather than a swallowed error.

## Principle Alignment Scorecard

| Principle | Alignment | Summary |
|---|---|---|
| /demonstrate-not-decorate | 🟢 Strong | 18 live puzzles, a public site, and two artifact upgrade passes — against 29 tracked engine files and zero dependencies |
| /map-before-make | 🟢 Strong | Spec, ASCII topology, phase machine, JSON Schema, and §18 locked decisions all precede the build — but the map has eleven missing sections and one region never built |
| /drive-through-documentation | 🟡 Moderate | Documentation *is* the executable surface (414 lines of SKILL.md), yet no freshness check, no CHANGELOG, no decision log, and docs that lag the data plane |
| /orchestrate-by-theme | 🟢 Strong | One theme, twelve subordinate skills, an explicit "thin router" orchestrator, and a curator whose whole job is theme-shaping |
| /enforce-measurement | 🔴 Weak | Process counters only. No north star, no site analytics, no aggregation of the per-puzzle difficulty data already being collected |
| /champion-adoptability | 🟡 Moderate | One idempotent setup script, MIT, self-contained marketplace, a real onboarding deck — against a no-op smoke test and four unverified prerequisites |
| /mandate-interoperability | 🟢 Strong | JSON Schema 2020-12 with a public `$id`, plain YAML/NDJSON/JSON on disk, pluggable surfaces, `$BAZAAR_ROOT` relocation, directory-based skill discovery |

**Alignment Levels:** 🟢 Strong — clear, consistent evidence · 🟡 Moderate — present but inconsistent · 🔴 Weak — little or no evidence

## Detailed Principle Assessments

### /demonstrate-not-decorate
> *Ship proof, not polish. Favor the Smallest Valuable Slice (≤7 days) and tangible demos over polish.*

**Alignment:** 🟢 Strong

**Evidence:**
- The proof is running. `~/bazaar/` holds `PUZ-0001` through `PUZ-0018`; `state/state.json` reports `counts_by_phase: {published: 17, reported: 1}` with `last_run: 2026-08-23T18:05:00Z`, and 47 events in `state/activity.ndjson`. Every one of those puzzles is playable at `/p/<PUZ-id>/`.
- Polish theater is structurally blocked. There is no `package.json`, no build step, no framework. `deck/deck.js` is 196 lines of vanilla JS carrying the comment "no deps". Twenty-nine tracked files produce a live site.
- Iterative delivery is visible in the data plane rather than the git log: `state.json` records `"artifacts": {"version": "v3", "upgraded": 18, "upgraded_at": "2026-08-23T18:05:00Z"}` — a second in-place upgrade pass across all eighteen artifacts.
- The 15-slide deck at `deck/index.html` is a demo instrument in the runbook's exact sense — per-slide `data-speaker-notes`, keyboard and touch navigation, and `@media print` rules with `page-break-after` so it exports one-slide-per-page to PDF. This is the 90-second demo script, built.

**Gaps:**
- The runbook's demo loop ends in "Analyze user-visible signals." There are none. The public site has no analytics; no user-visible signal from any of the eighteen shipped artifacts reaches back into the facility.
- Two commits total (`4ebd37d` initial scaffold, `c9d73dc` site→deck reorganization) means the incremental-slice discipline is invisible in the engine repo's history even where it clearly happened in practice.

**Recommendation:** Add the missing half of the loop. One privacy-respecting counter on `/p/<PUZ-id>/` — puzzle opened, win condition reached — turns eighteen shipped artifacts into eighteen demo signals and feeds `/enforce-measurement` at the same time.

### /map-before-make
> *Draw the terrain, then march. Always produce shared maps (journeys, workflows, interfaces) before building.*

**Alignment:** 🟢 Strong

**Evidence:**
- `puzzle-state-spec.md` is the map and it came first — the header declares "Architecture mirrors forge-state §1-§18 with puzzle-domain substitutions," i.e. the terrain was surveyed from a known atlas before any marching.
- Every artifact type the runbook asks for is present: an **interface diagram** (§3, an ASCII topology explicitly separating the host control plane from the disposable Docker data plane, with the mount arrows drawn); a **workflow diagram** (§6, the phase machine with both failure branches drawn as edges); an **entity contract** (§5, a fully populated `puzzle.yaml` example); a **machine-checkable interface** (`schemas/puzzle.schema.yaml`, JSON Schema 2020-12); and a **decision record** (§18 "Locked decisions", six numbered entries with values).
- Ownership boundaries are declared, not implied: eight numbered invariants in §2, of which invariant 3 ("Single-writer") and invariant 4 ("Two-plane isolation") are ownership statements. Each SKILL.md declares its inputs and its phase transition, and several declare a non-goal — `puzzle-curator`: "The curator does not publish."
- The map decomposes into thin slices: twelve skills, one per phase transition, 414 lines total.

**Gaps:**
- **The map has holes it does not admit to.** The spec claims to mirror §1–§18 and runs 1, 2, 3, 4, 5, 6, 7 → 10 → 18. Sections 8, 9, and 11–17 were never written, and nothing marks their absence as intentional.
- **One mapped region was never built.** §10 names twenty template ids and states "Templates live in `templates/types/<template_id>.template/`." The README repeats it; `puzzle-designer` and `puzzle-builder` both read from it. It does not exist. The map drifted ahead of the territory and nothing reconciled them.
- The runbook's loop closes with "Update maps and spread discipline." The maps have not been updated: the data plane's artifact v3 upgrade and its flag-storage scheme appear nowhere in the spec.

**Recommendation:** Run the loop's final step. Mark the missing spec sections explicitly as unwritten, and either build `templates/types/` or amend the four documents that promise it. A map with a known hole is a map; a map with an unmarked hole is a hazard.

### /drive-through-documentation
> *Docs are a control surface. Treat documentation as a leadership instrument and living asset.*

**Alignment:** 🟡 Moderate

**Evidence:**
- This project takes the principle more literally than any other in the portfolio: **the documentation is the executable.** `plugin/skills/*/SKILL.md` is simultaneously the developer documentation and the machine's operating instructions. There is no other implementation for it to drift from.
- The scaffold the runbook prescribes is largely present: README (7.7 KB, with a "Where everything lives" table, quickstart, taxonomy table, all twelve skills, a locked-configuration table, and required setup), a normative SPEC, and per-skill contracts. §18 "Locked decisions" is a decision log in substance.
- Discoverability is deliberate: `state/` is visible rather than `.state/`, and the README explains why — "Machinery lives in `state/` (visible), not `.state/` — same convention as forge-state." Documentation-by-filesystem-layout.
- `netlify.toml` is commented specifically to prevent a misreading: "The site is NOT built from this repo."

**Gaps:**
- **No freshness mechanism.** The runbook's loop is "Build scaffolds and CI for docs → Run doc freshness check → Update CI policies." There is no `.github/` directory, so no freshness check runs. Three symptoms follow: the `templates/types/` promise, the eleven missing spec sections, and the data plane's `artifacts: v3` / `flag_storage` scheme that appears in `~/bazaar/state/state.json` and nowhere in this repo.
- **No CHANGELOG, no DECISIONS file.** The runbook explicitly prescribes README/DECISIONS/RUNBOOK/CHANGELOG. Two of four exist. Notably, the runbook ships a decision-log template (`DECISION / WHY / ALTERNATIVES / OWNER / DATE / NEXT REVIEW`) and §18 uses none of its fields — no owner, no date, no next review, so nothing schedules a re-examination of a "locked" decision.
- **Contradiction inside one document.** The README states two mutually exclusive install paths (`puzzle-state@local-desktop-app-uploads` via symlink, and `/plugin install puzzle-state@puzzle-state` after adding the clone) without saying they serve different setups.
- **Copy-fork residue:** `deck/deck.js` opens `/* forge-state deck — vanilla nav, no deps */`. A doc-freshness check would have caught a one-line label from a different project.

**Recommendation:** Convert §18 into a `DECISIONS.md` using the runbook's own six-field template, so each locked decision carries a NEXT REVIEW date. Add a CI job that fails when a path named in the docs (`templates/types/`) does not exist — the cheapest possible freshness check, and it catches the exact class of drift already present.

### /orchestrate-by-theme
> *Fewer, bigger, better. Align under fewer, bigger themes that compound across teams.*

**Alignment:** 🟢 Strong

**Evidence:**
- **One theme, no sprawl.** Every one of the twelve skills is a stage of a single lifecycle. `plugin/skills/puzzle-orchestrator/SKILL.md` states the subordination explicitly: "Thin router. Decides nothing the per-puzzle phase doesn't already imply; it just sequences and budgets." The theme *is* the phase machine, and the router has no independent agenda.
- **The theme compounds across the portfolio.** puzzle-state is one member of a family (`forge-state`, `work-state`, `notella`, `desk-state`, and the wider `*-state` cohort) sharing single-writer, file-per-entity, and two-plane discipline. The spec names the lineage in its header; the README names four siblings in its second paragraph. This is theme reuse across projects, which is the compounding the runbook asks for.
- **Curation is theme-orchestration made into a skill.** `puzzle-curator` exists to turn "N independent puzzles into a navigable inventory" — collections, cross-links, a tag map, difficulty arcs. It is the runbook's "theme hub" as a pipeline stage, and it is constrained by a controlled vocabulary (`manifest.curation.tag_taxonomy`, fifteen terms across type / difficulty / tone).
- Naming is thematically consistent throughout: twelve `/puzzle-*` commands, `PUZ-NNNN` / `COL-NNNN`, `~/bazaar/`, "the shopkeeper of the bazaar."

**Gaps:**
- **The theme hub has never been published.** `collections/` in the live facility is empty, despite eighteen puzzles at `phase >= reported` — the exact input `puzzle-curator` specifies. Orchestrator step 4 either never ran or silently produced nothing, and no run log surfaced the discrepancy.
- **The theme is narrower in practice than in the map.** All eighteen puzzles are cipher-wing or logic-wing. Six of the eight declared families (`paper`, `casual-web`, `arg`, `riddle`, `escape`, `treasure-hunt`) have no instance. That is arguably *good* focus — but it means the declared theme is four times wider than the executed one, which is dilution in the map rather than in the work.

**Recommendation:** Either run the curator and publish the first collections, or narrow `manifest.design.allowed_types` to the two wings actually in operation. Both are consistent with "fewer, bigger, better"; the current state — a specced hub with no output and six unexercised families — is neither.

### /enforce-measurement
> *Evidence or it didn't happen. Define north star, counters, and leading/lagging metrics.*

**Alignment:** 🔴 Weak

**Evidence (what exists):**
- Process counters are real and maintained: `state/state.json` carries `counts_by_phase`, `last_run`, `carry_forward[]`; `state/activity.ndjson` holds 47 append-only events; `advance-phase` refreshes counts as part of the same atomic act.
- Per-record instrumentation is genuinely rich: `build.exit_code`, `build.duration_s`, `test.solver_passed`, `test.unique_solution`, `test.difficulty_actual`, and `test.notes` are all captured per puzzle. `test/solver-trace.json` records *how* a solver reached the win condition.
- Two trade-off knobs are declared in config: `testing.solver.require_unique_solution: false` and `max_solve_time_s: 600`.

**Gaps:**
- **No north star.** Nothing in the README, spec, manifest, or any SKILL.md names a success metric for the bazaar. Is it puzzles published? Puzzles solved? Solve-rate accuracy against `difficulty_target`? Unstated.
- **The counters measure the factory, not the product.** `{published: 17, reported: 1}` says the pipeline ran. It says nothing about whether any human has ever solved one of the eighteen artifacts — the site has no analytics, and no feedback path exists from `/p/<PUZ-id>/` back to the facility.
- **Collected data is never aggregated.** `difficulty_target` versus `difficulty_actual` is captured on every record and is a ready-made leading indicator of design calibration. Nothing compares them. No dashboard, no report, no rollup — despite `puzzle-curator` already reading across all records for other purposes.
- **A Goodhart decision was made without data.** `require_unique_solution: false` is the permissive setting — ambiguity is noted, not failed. That is a legitimate speed-versus-rigor trade-off, and the runbook's critique step ("Probe Goodhart's Law risks") would ask what evidence supports it. There is none; it is a default nobody has revisited.
- **Drift is unmeasured.** Three of eighteen live records carry `design.type` values outside the schema enum (`meta`, `modern-crypto`, `stego`) and nothing counted them.

**Recommendation:** The cheapest complete fix is one metric tree with three levels, all computable from data already on disk: **north star** — solved-by-a-visitor rate per published puzzle (requires one counter on the site); **leading** — `difficulty_actual` vs `difficulty_target` agreement, and `test.status` distribution across `solvable` / `unsolvable` / `ambiguous`; **lagging** — records failing schema validation, and puzzles at `phase >= reported` not yet in a collection. Two of the three need no new instrumentation at all — only aggregation.

### /champion-adoptability
> *Adoption is the product. Success = ease of adoption, time-to-value, reduced friction.*

**Alignment:** 🟡 Moderate

**Evidence:**
- Time-to-facility is one command. `scripts/init-facility.sh` is fully idempotent — every write guarded by `if [[ ! -f … ]]` with an explicit "exists: … (left as-is)" branch — and it seeds four directories, a manifest from template, `state.json`, `activity.ndjson`, `cursor.yaml`, and an `inbox/README.md` that documents the accepted drop formats.
- Sensible defaults throughout the shipped manifest: sandbox limits, an eight-type allowed list, a fifteen-term tag taxonomy, three surfaces pre-wired.
- Distribution friction is near zero: MIT-licensed, and the root `.claude-plugin/marketplace.json` makes the repo its own one-plugin marketplace — `/plugin marketplace add <clone>` then `/plugin install`.
- The deck is a real onboarding instrument, not decoration: fifteen slides, speaker notes, hash routing, HUD, keyboard and touch navigation, print-to-PDF, published at `/deck/`.
- Progressive disclosure is respected: the intake gesture is a single emoji reaction or a file drop; nothing about the twelve-skill pipeline is exposed at the point of use.

**Gaps:**
- **Quickstart step 2 is a no-op.** "Smoke-test the orchestrator in dry-run mode: `bash scripts/test-run.sh`" runs five `echo` statements and exits 0. A new adopter's first feedback signal is a success that means nothing.
- **Four unverified prerequisites.** Docker Desktop, `$GHCR_TOKEN` with `write:packages`, a sops-age store with five refs, and a private mirror repo — with no preflight to check any of them. Failures surface mid-pipeline.
- **The first real build hits a missing directory.** `puzzle-builder` mounts `templates/types/<template_id>.template/` read-only. It does not exist.
- **Contradictory install instructions** in one README (see `/drive-through-documentation`).
- **Single-tenant defaults ship to third parties.** `packaging.registry: ghcr.io/davidolsson` with `push_image: true`, `intake.slack.channels: ["#development"]`, and `markers_self_only: true` are all in the template a new adopter receives.

**Recommendation:** Rewrite `scripts/test-run.sh` as a preflight that checks `docker info`, `$GHCR_TOKEN`, manifest presence, and `templates/types/`, reporting pass/fail per item. Same eight lines of effort; converts the quickstart's dead step into its most useful one and measures time-to-value honestly for the first time.

### /mandate-interoperability
> *Open by default. Default to open, discoverable interfaces; prevent silos.*

**Alignment:** 🟢 Strong

**Evidence:**
- **A real, published contract.** `schemas/puzzle.schema.yaml` is JSON Schema draft 2020-12 with `$id: https://atomic47.co/puzzle-state/schemas/puzzle.schema.yaml` — a resolvable, versionable public identifier, not an internal type definition.
- **Standard formats end to end.** YAML per entity, NDJSON for logs, JSON for state. No proprietary encoding anywhere. `~/bazaar/` is browsable with `ls`, `cat`, `grep`, and any YAML parser — which is how the drift in this report's evidence was found.
- **Egress is pluggable, not hardcoded.** `manifest.surfaces` declares three independent targets (`gist`, `blog` → scsiwyg, `work_state`), each with its own `enabled` / `auto` / visibility settings. Disabling a surface is a config edit.
- **Relocatable by environment variable:** `$BAZAAR_ROOT` (`init-facility.sh`) and `$PUZZLE_STATE_REPO` (`deploy.sh`) move either plane without touching code.
- **Extension by convention, not registration.** `plugin.json` does not enumerate skills — discovery is by directory, so adding `plugin/skills/<name>/SKILL.md` adds a capability with no manifest edit.
- **Open by license and distribution:** MIT (`LICENSE`, and `license` in `plugin.json`), public repo, self-contained marketplace.
- **Downstream interop is wired:** every published puzzle emits a work-state event (`outputs.work_state_event_id`), making the facility a producer into a shared ledger rather than a silo.

**Gaps:**
- **Two of three entity types have no schema.** `collection.yaml` is written by `puzzle-curator` and `state.json` by the spine; `schemas/` contains only `puzzle.schema.yaml`. The `validate` op claims to "walk puzzles + collections, validate against schemas" against a schema that does not exist. The undocumented `site{}` and `artifacts{}` keys in live `state.json` are the direct consequence.
- **Versioning is nominal.** `0.1.0` appears in `plugin.json` and `marketplace.json`, hand-kept in sync, with no tags, no CHANGELOG, and no deprecation policy. An open interface without a versioning policy is open today and unpredictable tomorrow.
- **The runtime is a lock-in of a kind.** The skills are Claude Code plugins; the contracts are not portable to another agent runtime without translation. Reasonable, and worth naming.
- **No machine-readable index of the published bazaar.** The site serves HTML artifacts; there is no `manifest.json`, `llms.txt`, or feed. Sibling project the-dashes generates exactly this from equivalent source data.

**Recommendation:** Add `schemas/collection.schema.yaml` and `schemas/state.schema.yaml` — the `validate` op already promises the first. Then generate a `manifest.json` for the public site from the eighteen `puzzle.yaml` records, which makes the bazaar machine-readable using metadata already captured.

## Theme Map

### AI Innovation Themes

**1. Adversarial self-evaluation as a pipeline stage.** The most novel AI pattern here is `puzzle-tester`: an LLM-driven solver is run against the artifact "WITHOUT access to `design.solution_sketch` or `solution.md`", its output verified against `design.win_condition`, and its reasoning captured to `test/solver-trace.json`. The generator and the grader are deliberately separated, and the grader is blindfolded. That is an eval harness built into the production loop rather than bolted on — and it is combined with programmatic checkers where the domain allows ("a CSP solver for logic grids, a frequency-analysis pass for ciphers"), so the LLM judge is corroborated rather than trusted.

**2. Model failure as publishable content.** Spec §2 invariant 5 makes `unsolvable` a finding rather than an error, and `puzzle-publisher` ships it with a `[finding]` prefix. This inverts the usual reflex to hide generation failures, and turns the eval signal into an artifact.

**3. Untrusted-generation containment.** Generated game JS, LaTeX, and solver code are treated as hostile by default. `puzzle-builder`: the build "never executes in the host shell — generated game JS, LaTeX, or solver code touches the host only as bytes-on-disk written from inside the container," with `egress: registries-only`. A concrete, reusable answer to "what do you do with code a model just wrote?"

**4. Agent pipeline as an explicit state machine.** Twelve skills, one nine-value phase enum, a router that "decides nothing the per-puzzle phase doesn't already imply." Agency is bounded by a data field, not by prompt discipline.

### Technology Themes

- **Markdown as the program.** 414 lines of `SKILL.md` with YAML frontmatter constitute the entire application layer; there is no dependency manifest in 29 tracked files. The technology choice is *to have almost no technology*.
- **File-per-entity + append-only log + derived index.** YAML records, `activity.ndjson`, and a rebuildable `state/` (spec §4: "`puzzles/` and `collections/` are durable. `state/` is rebuildable"). Event-sourcing discipline with no event-sourcing framework.
- **Single-writer via filesystem lock.** `state/bazaar.lock`, acquired as step 1 of the walk, released at the end. Concurrency control in one file.
- **Two-plane host/sandbox split as a *security* boundary, not a deployment one.** The container exists to isolate untrusted output, not to scale.
- **Zero-dependency delivery artifacts.** The deck and the puzzle artifacts are static HTML with no build step, which is why an eight-year-old puzzle will still open.

### User Experience Themes

- **One-gesture capture.** The entire intake UX is a 🧩 reaction in Slack or a file dropped in `~/bazaar/inbox/`. `inbox/README.md`, written by the init script, documents the accepted formats at the point of use.
- **The filesystem as the interface.** `state/` is visible rather than `.state/`, a deliberate README-documented choice. Everything is `cat`-able. The facility is designed to be *read by a human*, not only by the pipeline.
- **Honest failure surfacing.** A `[finding]`-prefixed post sets reader expectations before the click. Users are told what they are getting rather than discovering a broken puzzle.
- **Onboarding as a designed artifact.** Fifteen slides with speaker notes, hash routing, HUD, keyboard/touch navigation, and print-to-PDF — a real first-run experience for a repo with no UI.
- **Two audiences, cleanly separated.** The solver sees `/p/<PUZ-id>/` and a writeup. The operator sees YAML. Neither is asked to understand the other's surface.

### Worksona Principles Themes

What this project reveals about the working culture:

- **Structure before output, consistently.** The spec, invariants, topology, phase machine, and schema were all written before the pipeline ran. This is a team that maps first and means it.
- **Failure is treated as information, not embarrassment.** Two of nine phase values are failure states, and both advance to publication. That is a cultural stance encoded in an enum.
- **Security is designed structurally, not procedurally.** The strongest guarantee in the system — solutions are in a different repo — needs no code to run correctly. That instinct (make the bad outcome impossible rather than forbidden) is the portfolio's most transferable habit.
- **Verification is the consistent blind spot.** The same pattern recurs: rich contracts, no runner. A `validate` op with no implementation, a `test-run.sh` that tests nothing, no CI, no north star. The culture writes excellent specifications and does not build the thing that checks them.
- **Documentation is treated as the product, which is both the strength and the trap.** When docs *are* the executable, doc drift is not cosmetic — it is a functional defect. `templates/types/` is exactly that: a documented interface with no implementation, invisible until someone follows the instructions.

## Portfolio Contribution

puzzle-state contributes three things the rest of the portfolio does not have.

**A working model of published failure.** forge-state has `build-failed`; puzzle-state extends the doctrine to semantic failure — the artifact built fine and simply doesn't work as a puzzle — and ships it. Any portfolio project with a generation step could adopt this.

**A gated-output template.** It is the only facility that must publish an artifact while withholding part of it, and the four-layer answer (private repo + scrub op + ≥40-char leak scan + deploy-time `find` abort) generalizes to any future public/private output split.

**A demonstration that the `*-state` pattern is genuinely portable.** The spec declares the port from forge-state openly, and eighteen live puzzles prove it took. That de-risks the pattern for every future facility.

Where it *drains* portfolio strength is in duplication: forge-state and puzzle-state are two maintained copies of one machine, and the stale `/* forge-state deck */` comment in `deck/deck.js` is the fork made visible. Under `/orchestrate-by-theme`, that is the portfolio-level dilution to address.

## Key Takeaways

- puzzle-state is a map-first project that shipped — spec, topology, phase machine, and schema all preceded the build, and eighteen live puzzles followed.
- `/enforce-measurement` is the one clear gap and the most consequential: the facility counts its own throughput and has no idea whether a single puzzle has ever been solved.
- `/drive-through-documentation` is unusually high-stakes here because the docs *are* the executable — which makes `templates/types/`, promised by four documents and existing in none, a functional defect rather than a formatting one.
- The strongest AI-innovation theme is the blindfolded in-pipeline solver: generator and grader deliberately separated, LLM judgment corroborated by programmatic checkers where the domain allows.
- The cultural signature across all seven commands is the same: excellent contracts, no runner. Every remediation in [Report 08](./08-technical-readiness.md) is a variation on "build the thing that checks the thing you already wrote."

## Cross-References

- [Report 01: Project Overview](./01-project-overview.md) — what the project is and who it serves.
- [Report 01b: Technical Specification](./01b-technical-specification.md) — architecture, data models, and technical decisions.
- [Report 04: Features & Capabilities](./04-features-capabilities.md) — the built/specced/untested inventory behind the `/orchestrate-by-theme` assessment.
- [Report 07: Portfolio Position](./07-portfolio-position.md) — the forge-state duplication and the integration opportunities named above.
- [Report 08: Technical Readiness](./08-technical-readiness.md) — the engineering evidence underlying the measurement and documentation gaps.
- [Report 10: Worksona First Principles](./10-worksona-first-principles.md) — the structural rubric; complements this runbook assessment.
