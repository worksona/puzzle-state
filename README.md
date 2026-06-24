# puzzle-state

A local-first bazaar of puzzles and puzzling things. You drop an input — a query, a source URL, a theme, a Slack 🧩 reaction — and nightly the facility researches it, designs a puzzle from it (cipher / logic / paper / casual web game / ARG / riddle / escape / treasure-hunt), builds the artifact inside a sealed sandbox, playtests it for solvability, packages it, and ships two outputs — a writeup with solution key (gist + scsiwyg blog post) and a runnable bundle (HTML game, printable PDF, ARG breadcrumb pack, or Dockerized service).

Sibling to `forge-state`, `desk-state`, `work-state`, and `notella`. Models the same single-writer / file-per-entity / two-plane pattern as forge-state; the domain is puzzles, not open-source code.

## Quickstart

```bash
# 1. Create the facility on disk (idempotent)
bash scripts/init-facility.sh

# 2. Smoke-test the orchestrator in dry-run mode
bash scripts/test-run.sh

# 3. From inside a Claude Code session, walk the queue once:
#    /puzzle-orchestrator --once
```

## Facility location

```
~/bazaar/
  manifest.yaml
  puzzles/PUZ-NNNN-<slug>/
    puzzle.yaml          # canonical record
    research.md
    design.md
    build/               # source files for the artifact
    artifact/            # the playable thing (HTML, PDF, breadcrumbs)
    solution.md          # solution key (gated — never in gist body)
    test/log.txt
    deploy/{Dockerfile,compose.yaml,RUN.md}  # if web/ARG
    report.md
  collections/           # curated bundles (themes, difficulty tiers, story arcs)
  state/
    state.json
    activity.ndjson
    cursor.yaml
    bazaar.lock
    logs/run-YYYY-MM-DD.txt
```

Machinery lives in `state/` (visible), not `.state/` — same convention as forge-state. The one exception is `plugin/.claude-plugin/plugin.json` (Claude Code plugin loader requires that exact dotted path).

## Unit of work

A **puzzle** — one PUZ-NNNN-slug carried through a fixed lifecycle:

```
candidate → researched → designed → built → tested → packaged → reported → published
```

Like forge-state's "build-failed is terminal-with-findings", puzzle-state treats `tested:unsolvable` as a finding worth publishing — an honest record of a puzzle that didn't survive playtest is more useful than a quiet failure.

## Puzzle taxonomy (§10-equivalent)

| type | what it is | typical artifact |
|---|---|---|
| `cipher` | substitution / steganographic / classical-crypto puzzle | single HTML page + downloadable text |
| `logic` | grid / deduction / Nikoli-family | interactive HTML or printable PDF |
| `paper` | print-and-solve | PDF + PNG preview |
| `casual-web` | small browser game | static site bundle |
| `arg` | alternate-reality breadcrumb trail | multi-surface pack (HTML pages, gist drops, hidden URLs) |
| `riddle` | text / lateral thinking | scsiwyg post + comments thread |
| `escape` | room-style sequence of locks | HTML scene graph |
| `treasure-hunt` | clue-chain leading to a target | sequenced hint pack |

The `puzzle-designer` skill picks the type from research output + user hints; templates live in `templates/types/<type>.template/`.

## Two-plane isolation

Same as forge-state. The host (control plane) holds secrets and runs reasoning, research, and publishing. The Docker sandbox (data plane) builds and runs untrusted assets — Pyodide notebooks, ARG-payload renderers, anything that executes solver code or generated game JS. Secrets never enter the sandbox; outputs are scrubbed before they ship.

## The skills

- `/puzzle-state` — substrate spine; only writer to disk.
- `/puzzle-harvester-slack` — drains 🧩 reactions in `#development` into candidate records.
- `/puzzle-harvester-sources` — ingests user-provided source material (URLs, files, queries) as candidate records. New vs forge-state — research-driven puzzles need an explicit source pipeline.
- `/puzzle-researcher` — fills theme / lore / facts / mechanics / source-refs.
- `/puzzle-designer` — picks taxonomy type, writes `design.md` (mechanics + win condition + difficulty target).
- `/puzzle-builder` — produces the artifact (HTML, PDF, ARG pack) in the sandbox.
- `/puzzle-tester` — solver pass + solvability check; outcome: `solvable` or `unsolvable` (both advance).
- `/puzzle-packager` — emits `deploy/` bundle (compose / static-site / printable / ARG pack).
- `/puzzle-curator` — bazaar curation: collections, tags, cross-links between puzzles, difficulty maps.
- `/puzzle-reporter` — composes `report.md` (success and unsolvable senses) + solution key.
- `/puzzle-publisher` — gist + scsiwyg blog (auto-publish) + work-state event; secret-scrub + solution-redaction before send.
- `/puzzle-orchestrator` — nightly walk, thin router, `--once` and `--dry-run`.

## Locked configuration decisions

| Item | Locked value |
|---|---|
| Intake channel + marker | `#development` with `🧩`, self-only |
| Sources harvester | enabled; reads from `~/bazaar/inbox/` and manifest `sources[]` |
| Solution gating | solution.md NEVER goes in gist body or blog post body — only as a separately-published gated artifact |
| Blog publishing | Auto-publish to scsiwyg |
| Packaging push | YES — push to `ghcr.io/davidolsson` for ARG/web puzzles that need a runtime |
| Durability mirror | GitHub private repo — set `durability.mirror.remote` in manifest before relying on it |
| Facility location | `~/bazaar/` visible, `state/` (not `.state/`) for machinery |

## Required setup

1. **Docker Desktop** running (data plane).
2. **`$GHCR_TOKEN`** with `write:packages` scope, for ARG/web puzzle artifacts.
3. **Secrets** in your sops-age store under the refs listed in `manifest.secrets.refs` (`anthropic`, `slack`, `github`, `scsiwyg`, `ghcr`).
4. **GitHub mirror repo** (private), then set `durability.mirror.remote` in the manifest.

## Install

One-plugin Claude Code marketplace — `.claude-plugin/marketplace.json` at the root makes it directly installable.

```
git clone <repo-url> ~/src/puzzle-state
/plugin marketplace add ~/src/puzzle-state
/plugin install puzzle-state@puzzle-state
```

After install, restart Claude Code so the 12 `/puzzle-*` skills load, then run `bash scripts/init-facility.sh` to create `~/bazaar/`.

## Spec

See [puzzle-state-spec.md](puzzle-state-spec.md).
