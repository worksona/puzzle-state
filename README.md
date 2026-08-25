# puzzle-state

![Status](https://img.shields.io/badge/status-functional-yellow)
![Version](https://img.shields.io/badge/version-0.1.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Claude Code Plugin](https://img.shields.io/badge/Claude_Code-plugin-D97757?logo=anthropic&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-scripts-4EAA25?logo=gnubash&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-sandbox-2496ED?logo=docker&logoColor=white)
![Netlify](https://img.shields.io/badge/Netlify-deployed-00C7B7?logo=netlify&logoColor=white)
![CI](https://img.shields.io/badge/CI-none-red)

> A local-first bazaar of puzzles and puzzling things — drop a 🧩 reaction, a URL, or a one-line query, and an agent pipeline researches it, designs a puzzle, builds the playable artifact, playtests it for solvability, and publishes the writeup while the answer stays gated in a private repo.

**Last Updated:** 2026-08-25

---

## Description

puzzle-state is the **engine**, not the puzzles. This repository is a Claude Code plugin of twelve `/puzzle-*` skills, a normative spec, a JSON Schema for the puzzle record, facility templates, two bootstrap scripts, and a fifteen-slide onboarding deck — 26 tracked files with **no dependency manifest of any kind**. There is no `package.json`, no `pyproject.toml`, no lockfile. The application layer is 414 lines of Markdown `SKILL.md` contracts.

The puzzles live somewhere else on purpose. The data plane is a separate **private** repo (`worksona/bazaar-data`, working copy `~/bazaar/`) holding eighteen real puzzles, their research, designs, artifacts, test logs, and — critically — their solution keys. The public site receives `site/index.html`, each `puzzles/*/artifact/`, and this repo's `deck/`, and nothing else. Solutions cannot leak from the public repo because they are not in it.

The unit of work is a **puzzle**: one `PUZ-NNNN-slug` directory carried through a fixed lifecycle by one skill per stage — `candidate → researched → designed → built → tested → packaged → reported → published`. Two of the nine phase values are failure states, and both still advance: `build-failed` and `tested: unsolvable` are **terminal-with-findings**, published with a `[finding]` prefix rather than swallowed. A puzzle that turns out to have no unique solution is an honest, shippable result.

puzzle-state is one member of a family of local-first state facilities (`forge-state`, `work-state`, `notella`, `sound-state`, `home-state`, `project-state`, …) built on the same three commitments: file-per-entity YAML with append-only NDJSON logs, a single-writer spine, and two-plane host/sandbox isolation. `puzzle-state-spec.md` says so in its first line: *"Architecture mirrors forge-state §1-§18 with puzzle-domain substitutions."*

## State of Development

**Maturity: Functional (Beta) — with an unusual split.** The *outputs* are in production: eighteen puzzles exist in `~/bazaar/puzzles/`, seventeen at `phase: published`, all live at https://puzzle-state.netlify.app, having been through two documented in-place artifact upgrade passes (a "widgets v2" rebuild of the cipher wing, then a "v3 device-first" pass that added flag vaults and cut body prose 71%). The *engine repo* is a v0.1 scaffold: two commits, no tags, no CHANGELOG, no tests, no CI, and a spec that claims to mirror forge-state §1–§18 but runs 1–7 → 10 → 18.

| Dimension | Status | Note |
|---|---|---|
| Core Functionality (pipeline) | 🟢 Stable | 18 puzzles carried candidate→published; 47 events in `state/activity.ndjson` |
| Contract Surface (12 skills) | 🟢 Stable | All twelve `SKILL.md` contracts complete and uniform |
| Solution Gating / Security | 🟢 Stable | Four layers, one structural (private data plane) — but none are tested |
| Documentation | 🟡 In Progress | Strong README + 10.6 KB spec + 15-slide deck; spec missing §8–§9 and §11–§17 |
| Schema Enforcement | 🔴 Not Started | `/puzzle-state validate` has no implementation; 3 of 18 live records violate the enum |
| Test Coverage | 🔴 Not Started | `scripts/test-run.sh` only `echo`s two commands and exits 0 |
| CI/CD Pipeline | 🔴 Not Started | No `.github/` directory; deploy is a manual script from the data plane |
| Taxonomy Coverage | 🟡 In Progress | Only `cipher` and `logic` families exercised; 6 of 8 have no instance |
| Template Library | 🔴 Not Started | `templates/types/` is referenced by four documents and does not exist |
| Production Readiness | 🟡 In Progress | ⚠️ Ready-with-caveats for its author-operator; needs investment as a distributable plugin |

**Known limitations, stated plainly:**

- **`templates/types/` does not exist.** Spec §10 names twenty template ids and says templates live there; the README (this file, below), `puzzle-designer/SKILL.md`, and `puzzle-builder/SKILL.md` all reference it. `templates/` contains only `manifest.yaml.template` and `puzzle.yaml.template`. The eighteen existing puzzles were built by a path the docs do not describe.
- **Nothing executes.** The schema is strict (`additionalProperties: false` throughout) and unenforced. Three live records carry `design.type` values — `meta`, `modern-crypto`, `stego` — outside the eight-value enum, and nothing noticed.
- **Three headline capabilities are specified but unobserved.** The Docker sandbox (all 18 records carry `build.base_image: null`, `build.duration_s: 0`), the curator (`collections/` is empty despite 18 eligible puzzles), and the three-surface publishing fan-out (`gist_url`, `blog_post_id`, `work_state_event_id` are null on all 18). "Published" today means "on Netlify".
- **`state.json` and `collection.yaml` have no schema**, which is how the undocumented `site{}` and `artifacts{}` keys — including the whole `flag_storage` convention — drifted into the data plane unrecorded.
- **`durability.mirror.remote` ships as `null`**, so the durability invariant is off by default.

## Tech Stack

| Layer | Technology | Notes |
|---|---|---|
| Agent runtime / distribution | Claude Code plugin, self-contained one-plugin marketplace | `.claude-plugin/marketplace.json` (root, `source: "./plugin"`) + `plugin/.claude-plugin/plugin.json`, both v0.1.0 |
| Application logic | Markdown `SKILL.md` contracts with YAML frontmatter | 12 files, 414 lines total. No executable application code anywhere |
| Schema / validation | JSON Schema draft 2020-12, expressed in YAML | `schemas/puzzle.schema.yaml`, `$id: https://atomic47.co/puzzle-state/schemas/puzzle.schema.yaml`; `additionalProperties: false` at every level |
| Persistence | Flat files — YAML per entity, append-only NDJSON, JSON counters, filesystem lock | `state/state.json` · `state/activity.ndjson` · `state/cursor.yaml` · `state/bazaar.lock` |
| Scripting / tooling | Bash, `set -euo pipefail`, idempotent by construction | `scripts/init-facility.sh` (every write guarded), `scripts/test-run.sh`, `~/bazaar/deploy.sh` |
| Sandbox / data plane | Docker — `node:20`, `ubuntu:24.04`; egress `registries-only`; 2 CPU / 4 GB / 1200 s per puzzle | `sandbox` block in `templates/manifest.yaml.template` |
| Frontend (deck) | Vanilla HTML + CSS custom properties + dependency-free JS | `deck/index.html` (785 lines, 15 `<section data-label>` slides, print-to-PDF CSS), `deck/deck.js` (196 lines). Google Fonts is the only external asset |
| Frontend (artifacts) | Single-file static HTML, answers verified in-browser via `crypto.subtle` SHA-256 | Lives in the data plane; served at `/p/<PUZ-id>/` |
| Hosting | Netlify — project `puzzle-state`, team `worksona`, site id `4c4e7ff5-28b3-4923-807b-bcac8fc0a1e6` | Legacy GitHub Pages mirror at `worksona.github.io/bazaar` |
| Container registry | GHCR (`ghcr.io/davidolsson`) for `docker-web` / `arg-pack` artifacts | Requires `$GHCR_TOKEN` with `write:packages`. Never exercised |
| Secrets | sops-age store; refs `anthropic, slack, github, scsiwyg, ghcr` | Only ref *names* appear in the repo; no key material |
| CI/CD | **None** | No `.github/` directory. Deploy is `bash ~/bazaar/deploy.sh` |
| Testing | **None automated.** Domain testing is a pipeline stage (`puzzle-tester`) | `scripts/test-run.sh` asserts nothing |
| License | MIT | `LICENSE`, © 2026 David Olsson |

## User Experience

There is no UI in this repo. The experience is a filesystem, a slash-command surface, and a public static site — and it serves four distinct people.

### The author-operator (primary, and today the only real one)

You are working, and something puzzling crosses your desk. You react 🧩 to it in `#development`, or drop a `.url` / `.md` / `.query` file into `~/bazaar/inbox/`. That is the whole capture gesture — the job statement the architecture answers is *"capture in one gesture, without the capture turning into a project I have to schedule."*

Later you open a Claude Code session and type `/puzzle-orchestrator --once`. The router acquires `state/bazaar.lock`, drains both harvesters, then walks every puzzle by phase — oldest first, exactly one skill per puzzle per walk — curates anything at `phase >= reported`, refreshes the counts, and releases the lock. It decides nothing the per-puzzle `phase` field does not already imply. If the walk is interrupted, re-running resumes exactly where it stopped, because `phase` *is* the checkpoint.

Between runs, the facility is browsable. `state/` is visible rather than `.state/` — a deliberate, documented choice — so debugging is `cat`ing files: `puzzle.yaml` for the record, `research.md` and `design.md` for the reasoning, `test/log.txt` and `test/solver-trace.json` for how the solver got there, `state/activity.ndjson` for the audit trail.

When you want the puzzles live, you run `bash ~/bazaar/deploy.sh` from the data plane. It stages the allowlist, then runs a denylist `find` that aborts the entire deploy if `solution.md`, `puzzle.yaml`, `research.md`, or `design.md` reached the staging directory, then pushes to Netlify.

### The solver

A visitor lands on https://puzzle-state.netlify.app, picks a puzzle, and opens `/p/PUZ-00NN-slug/`. It is a single self-contained HTML page — no accounts, no backend, no analytics. They work the mechanic (an Alberti disk, a tabula-recta carriage, a slitherlink grid), type the answer, and the page verifies it in-browser with `crypto.subtle` SHA-256 against a stored hash. The page never contains the answer, which is why the cheapest hosting is also the safest. Failed puzzles that shipped anyway carry a `[finding]` prefix, so expectations are set before the click rather than after.

### The plugin adopter

A Claude Code user clones the repo, adds it as a marketplace, installs the plugin, restarts, and gets twelve `/puzzle-*` skills. One `bash scripts/init-facility.sh` creates their own `~/bazaar/`. What they mostly want is a well-shaped multi-skill facility to read — and they will hit two rough edges: two install stories in one README (see Getting Started, which now reconciles them), and a first real build that reaches for `templates/types/` and finds nothing.

### The pattern reader

Someone evaluating the portfolio who wants the house `*-state` pattern in its smallest legible form. This is arguably the best exhibit: 26 tracked files, a 10.6 KB spec, and a fifteen-slide deck at [/deck/](https://puzzle-state.netlify.app/deck/) whose slide labels — "Two-plane isolation", "The substrate", "Unsolvable is a finding" — are the *pattern's* vocabulary, not the puzzle domain's. The deck has speaker notes, hash routing, keyboard and touch navigation, and prints one slide per page to PDF.

## Getting Started

### Prerequisites

| Requirement | Why | Required for |
|---|---|---|
| Claude Code | The twelve skills are a Claude Code plugin | Everything |
| Bash + `git` | Bootstrap scripts | Everything |
| Docker Desktop, running | The data plane / sandbox where builds and playtests execute | Full pipeline runs |
| `$GHCR_TOKEN` with `write:packages` | Image push for `docker-web` and `arg-pack` artifacts | Only those two artifact kinds |
| sops-age secret store with refs `anthropic, slack, github, scsiwyg, ghcr` | Host-plane credentials; never enter the repo or the sandbox | Harvesting + publishing |
| A private GitHub mirror repo | `durability.mirror.remote` — ships `null`, so set it before relying on it | Durability invariant |
| Netlify CLI, authenticated | Publishing the public site | Only the operator |

> There is no preflight script that checks any of these. A user missing one discovers it mid-pipeline. Turning `scripts/test-run.sh` into a real preflight is investment #7 in [Report 08](./docs/01-project-documentation/08-technical-readiness.md).

### Installation

```bash
# 1. Clone the engine repo — it is its own one-plugin marketplace
git clone https://github.com/worksona/puzzle-state ~/src/puzzle-state
```

Then, inside a Claude Code session:

```
/plugin marketplace add ~/src/puzzle-state
/plugin install puzzle-state@puzzle-state
```

Restart Claude Code so the twelve `/puzzle-*` skills load.

**Two install stories, reconciled.** The command above is the clean third-party path. The *author's local development setup* is different: the plugin is symlinked into an existing marketplace —
`~/.claude/plugins/marketplaces/local-desktop-app-uploads/puzzle-state → ./plugin` — and therefore installs as `puzzle-state@local-desktop-app-uploads`. Both are correct; use whichever matches your setup. Earlier versions of this README stated both without saying so.

### Configuration

```bash
# 2. Create the facility on disk. Idempotent — every write is guarded,
#    re-running prints "exists: … (left as-is)". Honors $BAZAAR_ROOT.
bash ~/src/puzzle-state/scripts/init-facility.sh

# Relocate either plane without editing code:
export BAZAAR_ROOT=~/bazaar                       # data plane (default)
export PUZZLE_STATE_REPO=~/src/puzzle-state       # read by ~/bazaar/deploy.sh for deck/
```

The script creates `puzzles/`, `collections/`, `inbox/`, `state/logs/`, copies `manifest.yaml` from the template, seeds `state.json`, touches `activity.ndjson` and `cursor.yaml`, and writes an `inbox/README.md` documenting the accepted drop formats (`*.url`, `*.md`, `*.txt`, `*.query`, `*.pdf`, `*.png`, `*.jpg`).

Then edit `~/bazaar/manifest.yaml`:

```yaml
intake:
  slack:  { channel: "#development", marker: "🧩", markers_self_only: true }
  inbox:  { path: "~/bazaar/inbox" }
  sources: []                       # declarative recurring feeds

packaging:
  registry: ghcr.io/davidolsson     # ← CHANGE THIS. Ships pointing at the author's namespace
  push_image: true                  # ← consider false until you need docker-web

durability:
  mirror: { remote: null }          # ← set this before relying on the durability invariant
```

### Running the Project

```
# Plan a walk without writing anything
/puzzle-orchestrator --dry-run

# Walk the queue once
/puzzle-orchestrator --once
```

Individual stages can be driven directly — `/puzzle-researcher`, `/puzzle-designer`, `/puzzle-builder`, `/puzzle-tester`, `/puzzle-packager`, `/puzzle-reporter`, `/puzzle-publisher`, `/puzzle-curator` — and all substrate reads and writes route through `/puzzle-state`.

Publishing runs from the **data plane**, not this repo:

```bash
bash ~/bazaar/deploy.sh            # stages allowlist, runs the private-file guard, deploys --prod
bash ~/bazaar/deploy.sh --draft    # non-prod deploy
```

### Running Tests

There is no automated test suite.

```bash
bash scripts/test-run.sh    # ⚠️ echoes two orchestrator commands, asserts nothing, always exits 0
```

What *does* test things is a pipeline stage: `/puzzle-tester` spawns a solver container with `artifact/` mounted read-only, runs a solver **without access to `design.solution_sketch` or `solution.md`**, verifies against `design.win_condition`, corroborates with a programmatic checker where the domain allows (a CSP solver for logic grids, frequency analysis for ciphers), and records `solvable` / `unsolvable` / `ambiguous` plus `test/log.txt` and `test/solver-trace.json`. That is genuine domain testing. It does not test the *engine*.

## Light Spec

### Architecture Overview

Two repos, three tiers, distinguished by what may write and what may execute.

```
~/WORKSONA/puzzle-state/          ENGINE  (public — worksona/puzzle-state, MIT)
  .claude-plugin/marketplace.json   one-plugin marketplace manifest
  plugin/
    .claude-plugin/plugin.json      Claude Code plugin definition (v0.1.0)
    skills/<12 dirs>/SKILL.md       the twelve /puzzle-* contracts, 414 lines
  puzzle-state-spec.md              normative spec — invariants, topology, phase machine
  schemas/puzzle.schema.yaml        JSON Schema 2020-12 for puzzle.yaml
  templates/                        manifest.yaml.template, puzzle.yaml.template
  scripts/                          init-facility.sh, test-run.sh
  deck/                             15-slide onboarding deck → /deck/ on the public site
  docs/                             this documentation suite
  netlify.toml                      documents the site link; the site is NOT built here

~/bazaar/                          DATA PLANE  (private — worksona/bazaar-data)
  manifest.yaml                     facility config, from the template
  inbox/                            drop URLs / files / one-line queries here
  puzzles/PUZ-NNNN-slug/
    puzzle.yaml  research.md  design.md
    build/  artifact/  test/  deploy/
    solution.md                     GATED — never in a gist or blog body
    report.md
  collections/COL-NNNN-slug/        curator output: collection.yaml + index.md
  state/                            state.json · activity.ndjson · cursor.yaml · bazaar.lock · logs/
  site/index.html                   the public landing page
  deploy.sh                         the only publishing entry point
```

- **Tier 1 — the spine.** `/puzzle-state` is the *only* component permitted to write the facility (spec §2 invariant 3). The other eleven skills route persistence through it.
- **Tier 2 — host reasoning skills.** Harvesters, researcher, designer, reporter, curator, publisher. They hold secrets and reach the network.
- **Tier 3 — sandboxed execution skills.** Builder, tester, packager. They run inside a disposable per-puzzle Docker container with `egress: registries-only` and no secrets. Generated game JS, LaTeX, and solver code "touch the host only as bytes-on-disk written from inside the container."
- **The router.** `/puzzle-orchestrator` acquires the lock, harvests, dispatches one skill per puzzle by phase, curates, refreshes counts, releases the lock. It decides nothing the phase does not already imply.

Machinery lives in a **visible** `state/`, not `.state/` — the facility is meant to be browsable with `ls`. The one exception is `plugin/.claude-plugin/plugin.json`, because the Claude Code loader requires that exact dotted path.

### Data Model

| Entity | Where | Schema | Shape |
|---|---|---|---|
| `puzzle.yaml` | `puzzles/PUZ-NNNN-slug/` | ✅ `schemas/puzzle.schema.yaml` | required `[id, slug, phase, created, updated, source]`; id `^PUZ-[0-9]{4}$`, slug `^[a-z0-9][a-z0-9-]{0,49}$`; optional blocks `research` / `design` / `build` / `test` / `package` / `report` / `curation` / `outputs` |
| `phase` | field on every puzzle | ✅ 9-value enum | `candidate · researched · designed · built · build-failed · tested · packaged · reported · published` |
| `design.type` | field | ✅ 8-value enum | `cipher · logic · paper · casual-web · arg · riddle · escape · treasure-hunt` — **3 live records violate this** (`meta`, `modern-crypto`, `stego`) |
| `build.artifact_kind` | field | ✅ 5-value enum | `html-static · pdf · breadcrumb-pack · docker-web · scsiwyg-post` |
| `test.status` | field | ✅ enum | `solvable · unsolvable · ambiguous · null`, plus `solver_passed`, `unique_solution`, `difficulty_actual` |
| `source` | block | ✅ | `surface` enum `slack \| inbox \| query`, plus `channel`, `message_ts`, `marked_by`, `marked_with`, `url`, `prompt` |
| `outputs` | block | ✅ | `gist_url`, `blog_post_id`, `solution_gist_url` (gated), `work_state_event_id` |
| `collection.yaml` | `collections/COL-NNNN-slug/` | ❌ **none** | Written by `/puzzle-curator`; `COL-[0-9]{4}` pattern only appears as a cross-reference in the puzzle schema |
| `manifest.yaml` | `~/bazaar/` | ❌ template only | `intake · sandbox · design · testing · packaging · surfaces · curation · durability · secrets` |
| `state/state.json` | `~/bazaar/state/` | ❌ **none** | `counts_by_phase`, `last_run`, `last_cursor`, `carry_forward[]` — plus undocumented `site{}` and `artifacts{}` keys that drifted in unnoticed |
| `state/activity.ndjson` | `~/bazaar/state/` | — | Append-only event log; 47 events today |

`puzzles/` and `collections/` are **durable**; `state/` is **rebuildable** (spec §4).

### API Surface

**Slash commands** (twelve, all installed by the plugin):

| Skill | Role |
|---|---|
| `/puzzle-state` | Substrate spine and only permitted writer — `init · read · write · validate · allocate-id · advance-phase · scrub · lock/unlock` |
| `/puzzle-orchestrator` | Nightly conductor; `--once`, `--dry-run`; honors `state/bazaar.lock` |
| `/puzzle-harvester-slack` | Drains 🧩 reactions in `#development` into candidates; per-channel cursor keyed on `source.message_ts` |
| `/puzzle-harvester-sources` | Drains `~/bazaar/inbox/` and manifest `intake.sources[]` |
| `/puzzle-researcher` | Fills theme / lore / facts / mechanics / source-refs → `research.md` |
| `/puzzle-designer` | Picks taxonomy type, mechanics, win condition, difficulty target → `design.md` |
| `/puzzle-builder` | Renders the artifact in the sandbox. On failure: `build-failed` — **this still advances** |
| `/puzzle-tester` | Blindfolded solver pass → `solvable` / `unsolvable` / `ambiguous` (all three advance) |
| `/puzzle-packager` | Emits the `deploy/` bundle (Dockerfile + compose + RUN.md) |
| `/puzzle-curator` | Collections, tags, cross-links, difficulty maps over everything at `phase >= reported` |
| `/puzzle-reporter` | Composes `report.md` in three narrative senses, plus the solution key |
| `/puzzle-publisher` | Gist + scsiwyg + work-state event; **scrub FIRST**, leak-guard, then ship |

**Scripts:** `scripts/init-facility.sh` (idempotent bootstrap, honors `$BAZAAR_ROOT`), `scripts/test-run.sh` (currently a no-op), `~/bazaar/deploy.sh` (the only publishing entry point).

**Schema:** `schemas/puzzle.schema.yaml` is published under a resolvable `$id` (`https://atomic47.co/puzzle-state/schemas/puzzle.schema.yaml`) so external consumers can validate a `puzzle.yaml` without this repo.

### Key Technical Decisions

1. **Skills as Markdown contracts, not code.** Twelve prose files, 414 lines, zero dependencies. *Gains:* every stage is legible and modifiable by a non-programmer; adding a stage is dropping a directory (`plugin.json` does not enumerate skills); nothing to install, patch, or version. *Costs:* nothing is executable, therefore nothing is testable and nothing enforces the contracts — which is precisely how three schema-violating `design.type` values reached the live facility unnoticed.

2. **Two repos rather than one repo with a `.gitignore`.** *Gains:* the strongest guarantee in the system, and the only one that needs no code to run correctly — a mistake in this repo cannot leak an answer, because answers are not in this repo. *Costs:* two working copies to sync, and documentation drift with nothing to catch it (the `v3` artifact versioning and the whole `flag_storage` scheme exist only in the data plane's unschema'd `state.json`).

3. **Unsolvable is terminal-with-findings** (spec §2 invariant 5). *Gains:* the queue never jams on a bad puzzle, and honest negative results become content — so no overnight run is wasted, which is what makes an unattended pipeline economically sane for a solo operator. *Costs:* the publish path carries three narrative senses, and every downstream skill branches on them.

4. **Single-writer via a filesystem lock.** Only `/puzzle-state` writes; `state/bazaar.lock` is step 1 of every walk. *Gains:* no write races, no partial states, a trivially correct mental model, and `phase` doubling as the crash-recovery checkpoint. *Costs:* strictly serial throughput; `allocate-id` is an O(n) directory scan; parallelism is foreclosed.

5. **Answer-hash artifacts on static hosting.** Puzzles are single-file HTML that verify submissions in-browser via `crypto.subtle` SHA-256 (with XOR-under-solution flag vaults in the logic wing). *Gains:* this resolves the tension between "solutions never ship" and "hosting is a static directory" — the cheapest architecture is also the safest, and an eight-year-old puzzle will still open. *Costs:* the technique is the project's best undocumented idea; `flag_storage` appears exactly once, in an unschema'd key in another repo's `state.json`.

6. **Manual deploy rather than CI.** *Gains:* the private-file guard runs on a machine the author controls; no CI secret ever holds data-plane credentials. *Costs:* publishing depends on one person running one script, the guard lives in a different repo from the invariant that mandates it, and nothing lints, validates, or regression-tests on push.

### Solution Gating — the defining control

Four layers, in order of strength:

1. **Structural.** Solutions live in private `worksona/bazaar-data`. The public repo does not contain them.
2. **Scrub.** `/puzzle-state scrub kind=public-output` redacts secret values, referenced `solution.md` contents, and inline answer keys. Its contract closes: *"A puzzle published with its solution in the gist body is a defect."*
3. **Leak guard.** `/puzzle-publisher` step 1 is scrub-first; then, *"If any substring of solution.md ≥40 chars appears in the body, ABORT and fail loudly."*
4. **Deploy abort.** `~/bazaar/deploy.sh` runs a `find` over the staging directory for `solution.md`, `puzzle.yaml`, `research.md`, `design.md` and exits 1 if any is present.

Layers 2–4 are unverified. There is no fixture that plants a known solution string and asserts it is caught. This is the single highest-value test the project could write.

## Resources & Links

| Resource | Link |
|---|---|
| Repository (engine, public) | [worksona/puzzle-state](https://github.com/worksona/puzzle-state) |
| Repository (data plane, **private**) | `worksona/bazaar-data` — working copy `~/bazaar/` |
| Live site | [puzzle-state.netlify.app](https://puzzle-state.netlify.app) |
| Onboarding deck | [puzzle-state.netlify.app/deck/](https://puzzle-state.netlify.app/deck/) — source in [`deck/`](./deck/) |
| Legacy Pages mirror | [worksona.github.io/bazaar](https://worksona.github.io/bazaar/) |
| Normative spec | [`puzzle-state-spec.md`](./puzzle-state-spec.md) |
| Record schema | [`schemas/puzzle.schema.yaml`](./schemas/puzzle.schema.yaml) |
| Documentation suite | [`docs/`](./docs/) · [Executive Summary](./docs/01-project-documentation/00-executive-summary.md) |
| — Project Overview | [Report 01](./docs/01-project-documentation/01-project-overview.md) |
| — Technical Specification | [Report 01b](./docs/01-project-documentation/01b-technical-specification.md) |
| — Business Benefits | [Report 02](./docs/01-project-documentation/02-business-benefits.md) |
| — Innovation Themes | [Report 03](./docs/01-project-documentation/03-innovation-themes.md) |
| — Features & Capabilities | [Report 04](./docs/01-project-documentation/04-features-capabilities.md) |
| — Extensibility | [Report 05](./docs/01-project-documentation/05-extensibility.md) |
| — Work Zones | [Report 06](./docs/01-project-documentation/06-work-zones.md) |
| — Portfolio Position | [Report 07](./docs/01-project-documentation/07-portfolio-position.md) |
| — Technical Readiness | [Report 08](./docs/01-project-documentation/08-technical-readiness.md) |
| — Worksona Leadership Themes | [Report 09](./docs/01-project-documentation/09-worksona-themes.md) |
| — Worksona First Principles | [Report 10](./docs/01-project-documentation/10-worksona-first-principles.md) |
| Sibling projects | `forge-state` (closest sibling — same machine, different domain) · `work-state` · `notella` · `sound-flow` · `the-dashes` |
| CI/CD dashboard | *none — there is no `.github/` directory* |

## License

MIT — see [LICENSE](./LICENSE). Copyright © 2026 David Olsson, Atomic 47 Labs.

The **engine** is MIT-licensed and given away by design. The **puzzles** live in a private repo and their license is unstated.
