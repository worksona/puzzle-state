# puzzle-state Project Documentation — Report 01: Project Overview

> **Project:** puzzle-state | **Generated:** 2026-08-25 | **Repo:** worksona/puzzle-state (public)

## Executive Summary

puzzle-state is a local-first "bazaar of puzzles and puzzling things": you drop an input — a Slack 🧩 reaction, a URL, a file, a one-line research query — and an agent pipeline researches it, designs a puzzle from it, builds the playable artifact in a sealed Docker sandbox, playtests it for solvability, packages it, and publishes a writeup while keeping the solution key gated. This repository is the **engine**, not the puzzles: a Claude Code plugin of twelve `/puzzle-*` skills, a normative spec, a JSON Schema for the puzzle record, facility templates, bootstrap scripts, and a fifteen-slide onboarding deck. The puzzles themselves live in a separate private data-plane repo (`worksona/bazaar-data`, working copy `~/bazaar/`), which today holds eighteen real puzzles published live at https://puzzle-state.netlify.app.

## What This Project Is

The clearest way to understand puzzle-state is to notice what it deliberately is *not*. It is not an application. There is no `package.json`, no `pyproject.toml`, no `Cargo.toml` — twenty-nine tracked files, zero dependency manifests. The "code" is twelve Markdown contracts totalling 414 lines at `plugin/skills/*/SKILL.md`, plus two Bash scripts and a static HTML deck.

What it *is*: a **local-first state facility** in a family of siblings (`forge-state`, `desk-state`, `work-state`, `notella`), all built on the same three-part pattern — file-per-entity YAML with append-only NDJSON logs, a single-writer discipline, and two-plane host/sandbox isolation. `puzzle-state-spec.md` opens by saying so explicitly: *"Architecture mirrors forge-state §1-§18 with puzzle-domain substitutions."* The domain here is puzzles instead of open-source repos; the machinery is the same shape.

The unit of work is a **puzzle**: one commission, identified `PUZ-NNNN`, carried through a fixed lifecycle by one skill per stage. Each puzzle is an independent, idempotent directory on disk.

### The problem it solves

Three problems, stacked:

1. **Curiosity is lossy.** An interesting source — a Wikipedia page on the Voynich manuscript, a paper on rotor machines, a stray thought — decays unless something catches it. puzzle-state gives that impulse a one-gesture capture: react 🧩 in `#development`, or drop a file in `~/bazaar/inbox/`. The 🧩 becomes a `puzzle.yaml` at `phase: candidate` and enters a queue.

2. **Generated puzzles are usually untested and usually unsafe to run.** A generated puzzle that has no solution — or three — is worse than no puzzle. `puzzle-tester` runs a real solver pass and records `solvable` / `unsolvable` / `ambiguous`. And because the generated game JS is untrusted output, it never executes in the host shell: `puzzle-builder` and `puzzle-tester` both open with *"Runs in the data plane"* and work only inside a disposable per-puzzle container with registries-only egress.

3. **Publishing a puzzle means not publishing its answer.** This is the sharpest constraint in the design and gets enforced at three independent layers (see Report 01b, Security Architecture). Spec §2 invariant 7 states it; `plugin/skills/puzzle-state/SKILL.md` closes with *"A puzzle published with its solution in the gist body is a defect."*

The distinctive design decision — worth calling out because it inverts the usual reflex — is invariant 5: **unsolvable is terminal-with-findings, not a halt.** A puzzle that fails its playtest advances to `reported` and gets published anyway, prefixed `[finding]`. The system treats "this puzzle as designed has no unique solution" as an honest, publishable result. The same applies to `build-failed`.

### Who it serves

- **The author-operator** (David Olsson, Atomic 47 Labs) — the primary and, today, only operator. Intake is `markers_self_only: true`; the id namespace, the manifest, and the GHCR registry (`ghcr.io/davidolsson`) are all single-tenant.
- **Puzzle solvers** — anyone who visits https://puzzle-state.netlify.app and plays one of the eighteen artifacts at `/p/<PUZ-id>/`.
- **Anyone installing the public plugin** — the repo is MIT-licensed and is its own one-plugin Claude Code marketplace, so a third party can install the twelve skills and run their own bazaar against their own `~/bazaar/`.

## Tech Stack

| Layer | Technology | Evidence |
|---|---|---|
| Agent runtime / distribution | Claude Code plugin, published as a self-contained one-plugin marketplace | `.claude-plugin/marketplace.json` (root, makes the repo directly `/plugin marketplace add`-able) and `plugin/.claude-plugin/plugin.json` — both v0.1.0 |
| Application logic | Markdown `SKILL.md` contracts with YAML frontmatter. No executable application code anywhere | 12 files at `plugin/skills/*/SKILL.md`, 414 lines total; no dependency manifest exists in 29 tracked files |
| Schema / validation | JSON Schema draft 2020-12, expressed in YAML, `additionalProperties: false` throughout | `schemas/puzzle.schema.yaml` — `$id: https://atomic47.co/puzzle-state/schemas/puzzle.schema.yaml` |
| Persistence | Flat files: one YAML per entity, append-only NDJSON log, JSON counters, filesystem lock | spec §2 invariant 2; `scripts/init-facility.sh` seeds `state/state.json`, `state/activity.ndjson`, `state/cursor.yaml`; `state/bazaar.lock` per spec §4 |
| Scripting / tooling | Bash with `set -euo pipefail`, idempotent by construction | `scripts/init-facility.sh` (every write guarded by `if [[ ! -f … ]]` with an "exists: … (left as-is)" branch), `scripts/test-run.sh`, `~/bazaar/deploy.sh` |
| Sandbox / data plane | Docker — `node:20` and `ubuntu:24.04` base images, registries-only egress, 2 CPU / 4 GB / 1200 s per puzzle | `sandbox` block in `templates/manifest.yaml.template`; "Runs in the data plane" headers in `puzzle-builder/SKILL.md` and `puzzle-tester/SKILL.md` |
| Frontend (deck) | Vanilla HTML + CSS custom properties + dependency-free JS; Google Fonts (Montserrat, JetBrains Mono) | `deck/index.html` (96 KB, inline `<style>`, `:root` token block, 15 `<section data-label>` slides) and `deck/deck.js` (196 lines) |
| Hosting | Netlify (project `puzzle-state`, team worksona), plus a legacy GitHub Pages mirror | `netlify.toml`, `.netlify/state.json` (siteId `4c4e7ff5-28b3-4923-807b-bcac8fc0a1e6`), `~/bazaar/deploy.sh`, `~/bazaar/deploy-pages.sh` |
| Container registry | GHCR (`ghcr.io/davidolsson`) for `docker-web` and `arg-pack` artifacts | `packaging.registry` / `packaging.push_image` in `templates/manifest.yaml.template`; README required-setup step 2 (`$GHCR_TOKEN`, `write:packages`) |
| Secrets | sops-age store; refs `anthropic, slack, github, scsiwyg, ghcr` | `secrets` block in `templates/manifest.yaml.template`; README required-setup step 3 |
| License | MIT | `LICENSE` (Copyright © 2026 David Olsson) and the `license` field in `plugin/.claude-plugin/plugin.json` |

## Architecture and Key Directories

### Two repos, two planes

The single most important structural fact: **puzzles and engine live in different repositories, on purpose, so solutions never touch a public repo.**

```
~/WORKSONA/puzzle-state/          ENGINE  (public — worksona/puzzle-state)
  .claude-plugin/marketplace.json   one-plugin marketplace manifest
  plugin/
    .claude-plugin/plugin.json      Claude Code plugin definition (v0.1.0, MIT)
    skills/<12 dirs>/SKILL.md       the twelve /puzzle-* contracts
  puzzle-state-spec.md              normative spec — invariants, topology, phase machine
  schemas/puzzle.schema.yaml        JSON Schema 2020-12 for puzzle.yaml
  templates/                        manifest.yaml.template, puzzle.yaml.template
  scripts/                          init-facility.sh, test-run.sh
  deck/                             15-slide onboarding deck → /deck/ on the public site
  netlify.toml                      documents the site link; the site is NOT built here

~/bazaar/                          DATA PLANE  (private — worksona/bazaar-data)
  manifest.yaml                     facility config, from the template
  inbox/                            drop URLs / files / one-line queries here
  puzzles/PUZ-NNNN-slug/            one directory per puzzle
    puzzle.yaml  research.md  design.md
    build/  artifact/  test/  deploy/
    solution.md                     GATED — never in a gist or blog body
    report.md
  collections/COL-NNNN-slug/        curator output: collection.yaml + index.md
  state/                            state.json · activity.ndjson · cursor.yaml · bazaar.lock · logs/
  site/index.html                   the public landing page
  deploy.sh                         the only publishing entry point
```

Note the convention, stated in both the README and spec §18: machinery lives in a **visible** `state/`, not a hidden `.state/` — the facility is meant to be browsable with `ls`. The one exception is `plugin/.claude-plugin/plugin.json`, because the Claude Code loader requires that exact dotted path.

### How the pieces fit

```
intake  ──► candidate ──► researched ──► designed ──► built ──► tested ──► packaged ──► reported ──► published
 🧩 Slack                                                │                    │
 inbox/ drop                                             └─► build-failed ────┤
 manifest sources[]                              tested:unsolvable ───────────┘
                                                        (both still report and publish)
```

`plugin/skills/puzzle-orchestrator/SKILL.md` is the router that walks this. Its loop is deliberately dumb — *"Decides nothing the per-puzzle phase doesn't already imply; it just sequences and budgets"*:

1. Acquire `state/bazaar.lock`; exit if held.
2. Harvest — `/puzzle-harvester-slack`, then `/puzzle-harvester-sources`.
3. Walk puzzles by phase, oldest first, dispatching exactly one skill per puzzle.
4. Curate — `/puzzle-curator` over everything at `phase >= reported`.
5. Refresh `state/state.json` counts, release the lock.

Two disciplines make this safe to re-run. **Single-writer:** only `/puzzle-state` touches the substrate; the other eleven skills route reads and writes through it. **Phase-as-resume-point:** an interrupted night picks up exactly where it stopped, because each puzzle's phase field *is* the checkpoint.

Publishing is the one thing the orchestrator does not own end to end. `~/bazaar/deploy.sh` runs from the data plane, stages only `site/index.html` plus each `puzzles/*/artifact/`, copies this repo's `deck/`, then runs a `find` guard that aborts the deploy outright if `solution.md`, `puzzle.yaml`, `research.md`, or `design.md` reached the staging directory.

## Getting Started

```bash
# 1. Install the plugin (the repo is its own marketplace)
git clone https://github.com/worksona/puzzle-state ~/src/puzzle-state
# then, inside a Claude Code session:
/plugin marketplace add ~/src/puzzle-state
/plugin install puzzle-state@puzzle-state
# restart Claude Code so the twelve /puzzle-* skills load

# 2. Create the facility on disk (idempotent; honors $BAZAAR_ROOT)
bash ~/src/puzzle-state/scripts/init-facility.sh

# 3. Plan a run without writing anything
/puzzle-orchestrator --dry-run

# 4. Walk the queue once
/puzzle-orchestrator --once
```

Step 1 has a documented wrinkle worth knowing before you hit it. The README's "Where everything lives" table says the plugin installs as `puzzle-state@local-desktop-app-uploads` via a symlink at `~/.claude/plugins/marketplaces/local-desktop-app-uploads/puzzle-state → ./plugin`, while the "Install" section gives `/plugin install puzzle-state@puzzle-state`. Both are correct — the first is the author's local development setup, the second is the clean third-party path — but the README does not say so, and the mismatch will look like an error the first time.

Before a full nightly run works end to end you also need, per README "Required setup": Docker Desktop running (the data plane); `$GHCR_TOKEN` with `write:packages` if you intend to build `docker-web` or `arg-pack` artifacts; secrets in a sops-age store under the refs `anthropic, slack, github, scsiwyg, ghcr`; and a private mirror repo with `durability.mirror.remote` set in the manifest — it ships as `null`, so the durability invariant is unenforced out of the box.

Two honest caveats about step 3. `scripts/test-run.sh` is eight lines that only `echo` the two orchestrator commands for a human to run; it asserts nothing and exits 0 regardless. And `templates/types/` — the template tree that the spec §10 table, the README, and `puzzle-designer/SKILL.md` all reference as the source of the twenty template ids — **has never been created**. `templates/` holds only `manifest.yaml.template` and `puzzle.yaml.template`. In practice the designer and builder have been working without it.

## Current State

The engine repo and the data plane are at very different maturities, and conflating them gives a misleading picture.

**The pipeline works and is in production use.** `~/bazaar/` holds eighteen puzzles (`PUZ-0001` through `PUZ-0018`); `state/state.json` reports `counts_by_phase: {published: 17, reported: 1}` with `last_run: 2026-08-23T18:05:00Z` and 47 events in `state/activity.ndjson`. The artifacts have been through two documented in-place upgrades — a "widgets v2" pass rebuilding the cipher wing as operable machines (Alberti disk, tabula-recta carriage, Playfair plate, rotor deck) and a "v3 device-first pass" adding flag vaults and cutting body prose 71%. The output is live.

**The engine repo is a v0.1 scaffold.** Two commits, no tags, no CHANGELOG; `plugin.json` and `marketplace.json` both say `0.1.0`; the spec is marked *"Version: 0.1 (draft for lock)"* and, despite claiming to mirror forge-state §1–§18, jumps 1,2,3,4,5,6,7 → 10 → 18. Sections 8, 9, and 11–17 were never written. There is no `.github/` directory, so nothing lints the skill frontmatter, validates records against the schema, or checks the deploy guard still holds. There is no `CLAUDE.md` or `AGENTS.md`, so an agent working in this repo has no in-repo operating instructions.

The gap between those two facts has consequences, documented in detail in Report 01b: three of the eighteen live records use `design.type` values (`meta`, `modern-crypto`, `stego`) that the schema's enum does not permit, and would fail validation today if a validator existed to run.

## Key Takeaways

- **This repo is the engine, not the puzzles.** Twelve `SKILL.md` contracts, a spec, a schema, two templates, two scripts, and a deck — 29 tracked files with no dependency manifest anywhere.
- **The two-repo split is a security control, not filing preference.** Solutions live only in the private `worksona/bazaar-data`; the public site receives `site/index.html`, `puzzles/*/artifact/`, and `deck/` and nothing else.
- **Failure is a first-class output.** `build-failed` and `tested:unsolvable` advance to `reported` and publish with a `[finding]` prefix rather than halting the queue (spec §2 invariant 5).
- **Two disciplines make the nightly walk safely re-runnable:** only `/puzzle-state` writes the substrate, and each puzzle's `phase` field doubles as its resume checkpoint.
- **Solution gating is enforced three times** — a `scrub` op, a ≥40-character leak scan in the publisher, and a `find`-based abort in `deploy.sh`.
- **The pipeline is production-proven; the repo documenting it is not.** Eighteen live puzzles and two artifact upgrade passes on one side; v0.1.0, two commits, no tests, no CI, a spec missing eleven of its eighteen sections, and a `templates/types/` tree that three documents reference and that does not exist on the other.

## Cross-References

- [Report 01b: Technical Specification](./01b-technical-specification.md) — component architecture, data models, command surface, deployment topology, security architecture, and technical decisions with their trade-offs.
- [Report 04: Features & Capabilities](./04-features-capabilities.md) — the concrete inventory of what runs today, what is specced but unbuilt, and what is built but untested.
