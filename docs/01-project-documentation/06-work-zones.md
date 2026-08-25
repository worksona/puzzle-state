# puzzle-state Project Documentation — Report 06: Work Zones

> **Project:** puzzle-state | **Generated:** 2026-08-25 | **Repo:** worksona/puzzle-state (public)

## Executive Summary

puzzle-state's functionality divides into nine work zones spanning two repositories — the public engine (`worksona/puzzle-state`, 26 tracked files) and the private data plane (`worksona/bazaar-data`, working copy `~/bazaar/`). Three zones are healthy and doing real work (Artifact Authoring, Distribution & Onboarding, Contract Definition), three are specified in detail and have never executed (Sandbox & Build, Curation, Publishing Fan-Out), and one — Quality & Verification — is effectively empty. The highest-value next work is not in the zone with the most design; it is in Quality & Verification, because every other zone's guarantees currently rest on prose that nothing checks.

---

## Zone map

```
        ENGINE REPO (public)                    DATA PLANE (private)
  ┌───────────────────────────────┐      ┌──────────────────────────────┐
  │ 1. Contract & Schema          │      │ 5. Artifact Authoring        │
  │    spec · schemas · templates │──────│    puzzles/*/artifact/       │
  │                               │      │                              │
  │ 2. Skill Surface              │      │ 4. Sandbox & Build   DORMANT │
  │    plugin/skills/*  (12)      │      │    (container path)          │
  │                               │      │                              │
  │ 3. Substrate & State          │──────│    state/ · puzzles/         │
  │    init-facility.sh           │      │                              │
  │                               │      │ 6. Curation          DORMANT │
  │ 8. Distribution & Onboarding  │      │    collections/  (empty)     │
  │    .claude-plugin · deck      │──────│                              │
  │                               │      │ 7. Publishing & Egress       │
  │ 9. Quality & Verification     │      │    deploy.sh (live)          │
  │    test-run.sh   (empty)      │      │    gist/blog/wrk     DORMANT │
  └───────────────────────────────┘      └──────────────────────────────┘
```

---

## Zone 1 — Contract & Schema Definition

**What it covers.** The normative description of what a puzzle is, what phases it passes through, and what a facility looks like. This zone is the project's spine: every other zone is downstream of it.

**Files.**
- `puzzle-state-spec.md` — 10.6KB, v0.1 "draft for lock": purpose, 8 invariants, ASCII topology, facility layout, worked entity example, phase machine, skill list, §10 taxonomy, §18 locked decisions
- `schemas/puzzle.schema.yaml` — JSON Schema 2020-12, `$id: https://atomic47.co/puzzle-state/schemas/puzzle.schema.yaml`, `additionalProperties: false` throughout
- `templates/manifest.yaml.template` — 88 lines of facility config
- `templates/puzzle.yaml.template` — blank entity instance

**Current health: amber.** The invariants are unusually crisp and the schema is rigorously closed. But the spec has structural holes: its header claims the architecture "mirrors forge-state §1-§18" and the file runs 1,2,3,4,5,6,7 → **10** → **18**. Sections 8, 9, and 11–17 were never written. And the schema has fallen behind the corpus in four ways — `design.type: "meta"` (PUZ-0007) is not in the enum; `outputs.blog_url` and `outputs.pages_url` appear on all 18 records against an `additionalProperties: false` block; live tags (`nikoli`, `deduction`, `slitherlink`) sit outside `manifest.curation.tag_taxonomy`; and 18 live template ids match none of the 20 named in §10. Two entities written by the system — `collection.yaml` and `state/state.json` — have no schema at all.

**Likely next work.**
1. Add `meta` to the `design.type` enum and to §10 — the mechanic is already proven by PUZ-0007.
2. Add `outputs.pages_url` and `outputs.blog_url` as real properties, or delete them from the corpus.
3. Write `schemas/collection.schema.yaml` and `schemas/state.schema.yaml`.
4. Either write spec §§8–9, 11–17 or amend the header to stop claiming them.
5. Reconcile the template vocabulary: the corpus's mechanic-level ids (`logic.slitherlink`) are more useful than the spec's family-level ones (`logic.nikoli-family`).

---

## Zone 2 — Skill Surface (agent contracts)

**What it covers.** The twelve behavioral contracts that constitute the application. This is the entire "code" of the project.

**Files.** `plugin/skills/*/SKILL.md` — 12 contracts, 414 lines total:

| Contract | Role |
|---|---|
| `puzzle-state` | Substrate spine; the only permitted writer; owns init/read/write/validate/allocate-id/advance-phase/scrub/lock |
| `puzzle-orchestrator` | Router; lock → harvest → dispatch by phase → curate → refresh → unlock |
| `puzzle-harvester-slack` | 🧩 reactions in `#development`, cursor-tracked |
| `puzzle-harvester-sources` | Inbox drain + manifest source feeds |
| `puzzle-researcher` | `research.md`, bounded at 6 searches / 12 fetches |
| `puzzle-designer` | Type + template + `design.md` + win condition |
| `puzzle-builder` | Artifact generation in the sandbox |
| `puzzle-tester` | Solver pass; solvable / unsolvable / ambiguous |
| `puzzle-packager` | `deploy/` bundle, per-kind behavior table |
| `puzzle-curator` | Collections, tags, cross-links |
| `puzzle-reporter` | `report.md` + `solution.md`, three senses |
| `puzzle-publisher` | Gist + scsiwyg + solution gist + work-state event |

**Current health: green-amber.** The contracts are consistent in shape (description with trigger phrases, then Inputs / Behavior / Outputs / Idempotency), the separation of concerns is clean, and several carry genuinely good discipline notes — `puzzle-researcher`'s "Research is non-prescriptive… do not write it into `design.type` yet", `puzzle-designer`'s "If it cannot be expressed in a few crisp lines a solver can verify against, the design is not ready", `puzzle-curator`'s explicit "Non-goal: the curator does not publish."

Three dangling references mar it: `manifest.surfaces.blog.publish_findings` is branched on by `puzzle-tester` and `puzzle-publisher` but does not exist in the manifest template; `outputs.blog_post_id_solution` is named by `puzzle-reporter` but absent from the schema; and `design.solution_sketch` is a documented input to `puzzle-tester` but is not a property of the schema's `design` block, which is `additionalProperties: false` — so writing it would make the record invalid.

**Likely next work.** Close the three dangling references. Then decide whether `puzzle-publisher`'s fixed six-step surface order should become a loop over `manifest.surfaces` (see Zone 7).

---

## Zone 3 — Substrate & State

**What it covers.** Facility creation, the on-disk layout, id allocation, the activity log, the lock, and the derived state file. The durability story: `puzzles/` and `collections/` are durable; `state/` is rebuildable.

**Files.**
- `scripts/init-facility.sh` — idempotent bootstrap honoring `$BAZAAR_ROOT`
- `plugin/skills/puzzle-state/SKILL.md` — the eight-op contract
- Data plane: `~/bazaar/state/{state.json, activity.ndjson, cursor.yaml, bazaar.lock, logs/}`

**Current health: amber.** The bootstrap half is genuinely solid — every write in `init-facility.sh` is guarded by `if [[ ! -f ... ]]` with an explicit `exists: … (left as-is)` branch, it creates the inbox README documenting accepted drop formats, and it works against any root via env var. Re-running is free.

The runtime half is prose only. `validate`, `scrub`, `allocate-id`, `advance-phase` and `lock`/`unlock` are table rows in a Markdown file; there is no executable behind any of them. Two consequences are already visible in the live facility: `state/state.json` has grown `site{}` and `artifacts{}` blocks that no schema describes, and `last_cursor` is `{}` while the harvesters were never run — the file reflects a hand-maintained reality rather than a machine-maintained one.

The activity log is doing its job: 47 events in `state/activity.ndjson` against 18 puzzles.

**Likely next work.**
1. Make `validate` real — a script that walks `puzzles/*/puzzle.yaml` against the schema would have caught all four drift classes.
2. Make `scrub` real, since Zone 7's central guarantee depends on it.
3. Schema `state.json` so `site{}` and `artifacts{}` become declared rather than discovered.

---

## Zone 4 — Sandbox & Build *(dormant)*

**What it covers.** The two-plane isolation boundary: a disposable per-puzzle Docker container that renders untrusted generated code and runs the solver, with the host never executing generated JS, LaTeX or solver code.

**Files.**
- `puzzle-state-spec.md` §2 invariant 4, §3 ASCII topology
- `plugin/skills/puzzle-builder/SKILL.md` — mounts `build/` rw and the template dir ro, captures `build/log.txt`, sets `exit_code` and `duration_s`
- `plugin/skills/puzzle-tester/SKILL.md` — solver container with `artifact/` read-only, denied `design.solution_sketch` and `solution.md`
- `templates/manifest.yaml.template` — `sandbox.base_images` (node:20, ubuntu:24.04), `egress: registries-only`, `cpu: 2`, `memory: 4g`, `per_puzzle_timeout_s: 1200`, `night_budget_s: 14400`

**Current health: red — designed in detail, never executed.** Every one of the 18 puzzle records carries `build.base_image: null` and `build.duration_s: 0`. `PUZ-0001-cipher-collection` is the only puzzle with a `build/` or `test/` directory at all; the other 17 hold `puzzle.yaml`, `solution.md` and `artifact/` and nothing else. The artifacts were authored directly rather than rendered through the container path.

This zone is also blocked from below: `puzzle-builder` mounts `templates/types/<template_id>.template/` into the container, and that directory tree does not exist anywhere in the repo.

**Likely next work.**
1. Create `templates/types/` — this unblocks the zone and Zone 1's taxonomy work simultaneously.
2. Run one puzzle end-to-end through the container and let it write real `base_image`, `exit_code`, `duration_s` and `build/log.txt`. One demonstrated build is worth more to the project than five more puzzles.
3. Deliberately fail one build to exercise the `build-failed` branch, which has also never been taken.

---

## Zone 5 — Artifact Authoring & Answer Cryptography

**What it covers.** The playable output — what a solver actually opens — and the technique that lets a static page verify an answer without containing it.

**Files.** `~/bazaar/puzzles/PUZ-*/artifact/index.html` (18 files), `~/bazaar/puzzles/PUZ-*/solution.md`, and the convention recorded in `~/bazaar/state/state.json → artifacts`.

**Current health: green — the strongest zone in the project.** Eighteen self-contained single-file HTML artifacts with no external script dependencies (`PUZ-0012-sudoku` 302 lines, `PUZ-0007-meta-cabinet` 698). Answers validate in-browser via `crypto.subtle` SHA-256. The corpus spans two coherent wings:

- **Cipher wing** — substitution, transposition, playfair, rotor, steganography, two-time-pad
- **Logic wing** — light-up, lights-out, binairo, sudoku, nonogram, fill-a-pix, skyscrapers, numbrix, tents, slitherlink

plus `PUZ-0007-meta-cabinet`, a feeder-to-meta capstone that reuses "the five rung engines verbatim (decode direction)", gates each fragment on a per-word SHA-256, and assembles `CABINET{the_whole_cabinet_remembers_everything}`.

The zone has its own versioning discipline, recorded nowhere else: `"artifacts": {"version": "v3", "upgraded": 18, "flag_storage": "encrypted-under-solution (logic wing) / sha256-hash (cipher wing)"}`. Quality shows in the test notes too — PUZ-0018's record documents a 22-segment single-loop verification with all dot degrees 0/2.

**Likely next work.**
1. **Document `flag_storage` in the engine repo.** It is the technique that makes zero-backend distribution compatible with solution gating, and it appears in no spec, schema, skill or README. A `build.flag_storage` enum would make it inspectable and testable.
2. Extend beyond two wings — `paper`, `casual-web`, `arg`, `riddle`, `escape` and `treasure-hunt` have no instance, so the `pdf`, `docker-web` and `breadcrumb-pack` artifact kinds are unproven.
3. Backfill provenance: 17 of 18 puzzles lack `research.md`, `design.md` and `report.md`, which means spec §2 invariant 6 ("every published puzzle carries the exact prompt, seed, source-refs, and build commands") is only satisfied for PUZ-0001.

---

## Zone 6 — Curation *(dormant)*

**What it covers.** Turning N independent puzzles into a navigable inventory — themed collections, a controlled tag vocabulary, cross-links, difficulty arcs.

**Files.** `plugin/skills/puzzle-curator/SKILL.md`; `manifest.curation.{auto_collection, tag_taxonomy}`; `~/bazaar/collections/`; the `COL-[0-9]{4}` pattern in `schemas/puzzle.schema.yaml`.

**Current health: red — never run.** `~/bazaar/collections/` is empty. The curator's stated input is "all `puzzles/*/puzzle.yaml` at `phase >= reported`", and there are 18 of those. Its auto-collection rule ("may propose new collections when ≥3 unassigned puzzles share a coherent frame") would fire immediately: the corpus contains an obvious six-puzzle cipher wing and an eleven-puzzle logic wing. Every record carries `curation.collection_ids: []`.

Tags are populated but off-vocabulary — `nikoli`, `deduction`, `slitherlink` are not in `manifest.curation.tag_taxonomy`, which is exactly the constraint the curator is supposed to enforce ("constrained to the taxonomy"). Tags were written by hand during authoring; the taxonomy was never applied.

There is also no `collection.schema.yaml`, so the entity this zone produces has no contract.

**Likely next work.**
1. Run `/puzzle-curator` once. Two collections (cipher wing, logic wing) plus PUZ-0007 as the cipher wing's capstone are sitting there waiting.
2. Write `schemas/collection.schema.yaml` first, so the output is contracted.
3. Reconcile the tag taxonomy with what the corpus actually uses — the mechanic-level tags are more useful than the family-level list in the manifest.

---

## Zone 7 — Publishing & Egress

**What it covers.** Everything that leaves the host, and the guarantees that ride along with it — secret scrubbing, solution redaction, the leak guard, and the private-file abort.

**Files.**
- `plugin/skills/puzzle-reporter/SKILL.md` — the public/gated split
- `plugin/skills/puzzle-publisher/SKILL.md` — six-step order, `[finding]` prefixing, ≥40-char leak guard
- `plugin/skills/puzzle-state/SKILL.md` — `scrub kind=public-output`
- `templates/manifest.yaml.template` — `surfaces.{gist, blog, work_state}`
- `netlify.toml`, `.netlify/state.json` — project link documentation
- Data plane: `~/bazaar/deploy.sh` (Netlify), `~/bazaar/deploy-pages.sh` (legacy Pages mirror), `~/bazaar/site/index.html` (425 lines)

**Current health: split — green on the static path, red on the fan-out.**

*Green.* `deploy.sh` is real, defensive and recently touched (2026-08-23). It stages an allowlist into a temp dir (`site/index.html` → `/` and `/404.html`, each `puzzles/PUZ-*/artifact/` → `/p/<PUZ-id>/`, and the engine repo's `deck/` → `/deck/`), then runs a `find` denylist for `solution.md`, `puzzle.yaml`, `research.md`, `design.md` and aborts if any is present, then deploys to a pinned site id. It honors `$PUZZLE_STATE_REPO` and supports `--draft`. The site is live.

*Red.* The three-surface fan-out has never executed. All 18 records carry `outputs.gist_url: null`, `blog_post_id: null`, `solution_gist_url: null`, `work_state_event_id: null`. What actually happened is recorded in `outputs.pages_url` — an undeclared field pointing at the legacy GitHub Pages mirror. The `[finding]` path has never been taken either, since no puzzle has a failure status.

The zone's most important guarantee — solutions never ship — is enforced at three layers (scrub op, ≥40-char substring abort, deploy-time `find`) and tested at none.

**Likely next work.**
1. Publish one puzzle through the full fan-out and record real `outputs.*` values.
2. Reconcile `outputs.pages_url` / `blog_url` with the schema.
3. Add `publish_findings` to the manifest, since two skills already branch on it.
4. Consider making `puzzle-publisher` iterate `manifest.surfaces` rather than enumerating surfaces in prose — currently surfaces are configurable but not pluggable.

---

## Zone 8 — Distribution & Onboarding

**What it covers.** How the plugin reaches an installer and how a newcomer understands the system in fifteen minutes.

**Files.**
- `.claude-plugin/marketplace.json` — root one-plugin marketplace, `source: "./plugin"`
- `plugin/.claude-plugin/plugin.json` — name, v0.1.0, MIT, author David Olsson / atomic47.co
- `README.md` — 7.7KB: where-everything-lives table, layout, quickstart, taxonomy, all 12 skills, locked decisions, required setup
- `deck/index.html` (785 lines) + `deck/deck.js` (196 lines) — 15 slides, vanilla, hash routing, keyboard/touch nav, print-to-PDF CSS, per-slide speaker notes
- `LICENSE` — MIT, Copyright (c) 2026 David Olsson

**Current health: green-amber.** The self-marketplace design is elegant — the repo is directly `/plugin marketplace add`-able with no build step. The deck is a genuinely good onboarding artifact, and its slide labels ("The night shift", "Two-plane isolation", "The substrate", "Twelve skills", "Unsolvable is a finding", "Publishing fan-out", "Curiosity, curated nightly") teach the pattern rather than the domain. Google Fonts (Montserrat, JetBrains Mono) is the only external asset dependency anywhere in the repo.

Rough edges: the README carries two mutually inconsistent install stories (`puzzle-state@local-desktop-app-uploads` via symlink in the table, `puzzle-state@puzzle-state` in the Install section) without explaining that both are true for different setups. `deck/deck.js` line 1 still reads `/* forge-state deck — vanilla nav, no deps */`. There are two commits total, no tags and no `CHANGELOG.md`, so the `0.1.0` in `plugin.json` and `marketplace.json` is the only version marker. And `.gitignore` excludes `.netlify` while `.netlify/state.json` and `.netlify/netlify.toml` are present on disk, alongside a stray `.DS_Store` at the repo root that is also ignored.

There is no `CLAUDE.md` or `AGENTS.md`, so an agent working in this repo has no in-repo operating instructions.

**Likely next work.** Reconcile the two install stories; relabel `deck.js`; clean the ignored-but-present files; add a `CHANGELOG.md` and a `v0.1.0` tag; add a `CLAUDE.md` capturing the write-discipline invariant and the two-plane rule.

---

## Zone 9 — Quality & Verification

**What it covers.** Everything that would tell you the other eight zones still work.

**Files.** `scripts/test-run.sh` — and nothing else. There is no `.github/` directory.

**Current health: red — effectively empty.** `test-run.sh` is eight lines that `echo` the facility path and two orchestrator commands for a human to run. It asserts nothing and exits 0 regardless. Nothing validates `puzzle.yaml` against `schemas/puzzle.schema.yaml`, lints `SKILL.md` frontmatter, exercises `init-facility.sh`, or checks that `deploy.sh`'s private-file guard still catches what it claims to.

What testing *does* exist is domain testing, and it is excellent — but it belongs to Zone 4. `puzzle-tester` defines a real playtest with an LLM solve attempt plus a programmatic checker (a CSP solver for logic grids, frequency analysis for ciphers), win-condition verification, uniqueness checking and difficulty comparison. That is software-quality thinking applied to puzzles rather than to the software.

The gap is asymmetric in a way worth naming: the system verifies its *products* rigorously and its *guarantees* not at all. The solution-leak guard — the invariant the entire public/private split depends on — has no test.

**Likely next work,** in priority order, and this is the project's highest-leverage zone:
1. `scripts/validate.sh` — walk `puzzles/*/puzzle.yaml` against the schema. Would have caught `design.type: "meta"`, `outputs.pages_url`, and the off-taxonomy tags on day one.
2. `scripts/check-leaks.sh` — for each puzzle, grep every file under `artifact/` for ≥40-char substrings of its `solution.md`. Converts the central invariant from an assertion into a fact.
3. A `.github/workflows/` job running both on push, plus a `SKILL.md` frontmatter lint.
4. Make `test-run.sh` actually run `init-facility.sh` into a temp root and assert the resulting tree — it is already idempotent and env-var-driven, so this is nearly free.

---

## Zone health summary

| # | Zone | Health | Evidence |
|---|---|---|---|
| 1 | Contract & Schema | Amber | Spec missing §§8–9, 11–17; four classes of schema drift; two unschema'd entities |
| 2 | Skill Surface | Green-amber | 12 coherent contracts, 414 lines; three dangling references |
| 3 | Substrate & State | Amber | Bootstrap solid and idempotent; all eight runtime ops prose-only |
| 4 | Sandbox & Build | **Red / dormant** | `base_image: null`, `duration_s: 0` on 18/18; `templates/types/` missing |
| 5 | Artifact Authoring | **Green** | 18 self-contained HTML puzzles, hash-gated answers, v3 upgrade |
| 6 | Curation | **Red / dormant** | `collections/` empty against 18 eligible puzzles; tags off-taxonomy |
| 7 | Publishing & Egress | Split | `deploy.sh` live and defensive; all `outputs.*` fan-out fields null |
| 8 | Distribution & Onboarding | Green-amber | Self-marketplace + 15-slide deck; contradictory install docs |
| 9 | Quality & Verification | **Red** | `test-run.sh` asserts nothing; no CI; no validator; leak guard untested |

---

## Key Takeaways

- **Nine zones across two repos; three are healthy, three are dormant, one is empty.** The split is diagnostic: the *reasoning* zones (contracts, artifact authoring) ran and produced excellent output, while the *infrastructural* zones (sandbox, curation, publishing fan-out) were specified in detail and bypassed.
- **Artifact Authoring is the strongest zone** and the least documented — 18 self-contained HTML puzzles with `crypto.subtle` answer verification and a two-scheme `flag_storage` convention that appears in no spec, schema, skill or README.
- **Sandbox & Build is blocked from below.** `puzzle-builder` mounts `templates/types/<template_id>.template/` into the container and that tree has never been created, so creating it unblocks two zones at once.
- **Curation would fire immediately if run.** Eighteen puzzles at `phase >= reported`, an obvious cipher wing and logic wing, and an empty `collections/` directory.
- **Publishing is split cleanly:** the static path (`deploy.sh`, allowlist-copy then denylist-`find`, pinned site id) is real and defensive; the three-surface fan-out has never executed and the actual distribution is recorded in an undeclared `outputs.pages_url`.
- **Quality & Verification is the highest-leverage zone despite being the smallest.** Every guarantee in the other eight — including the solution-leak guard the public/private repo split depends on — is enforced by prose that nothing checks. Two scripts (`validate.sh`, `check-leaks.sh`) and one CI workflow would change the maturity assessment of the whole project.
- **The system verifies its products rigorously and its guarantees not at all** — `puzzle-tester` proves puzzles are solvable while nothing proves solutions do not leak.

---

## Cross-References

- [Report 01b — Technical Specification](01b-technical-specification.md) — the architecture the zones partition.
- [Report 02 — Business Benefits](02-business-benefits.md) — the operating value the green zones deliver and the dormant zones defer.
- [Report 03 — Innovation Themes](03-innovation-themes.md) — Zone 5's answer-cryptography as the project's keystone technique.
- [Report 08 — Technical Readiness](08-technical-readiness.md) — the maturity read on the dormant-zone evidence tabulated here.
- [Report 05 — Extensibility](05-extensibility.md) — the blockers in §5 mapped to the zones that own them, notably `templates/types/` (Zone 4) and the missing validator (Zone 9).
