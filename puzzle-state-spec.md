# puzzle-state — Specification

**Version:** 0.1 (draft for lock)
**Status:** Architecture mirrors forge-state §1-§18 with puzzle-domain substitutions.
**Pattern family:** local-first state facility (sibling to forge-state, desk-state, work-state, notella).

---

## 1. Purpose

puzzle-state is a **bazaar of puzzles and puzzling things**. You drop an input — a Slack 🧩 reaction, a source URL, a research query, a theme — and nightly the facility researches it, designs a puzzle from it, builds the artifact in a sealed sandbox, playtests it for solvability, packages it, and ships a writeup + a runnable bundle. Unsolvable puzzles are kept as findings, not discarded; "this puzzle as designed has no unique solution" is publishable.

The unit of work is a **puzzle**: one commission carried through a fixed lifecycle. Each puzzle is independent and idempotent.

---

## 2. Invariants

1. **Local-first.** Facility lives on your machine. "Deploy" means outputs leave the host for surfaces (gist, blog, registry); the facility itself never moves.
2. **File-per-entity YAML, append-only NDJSON.** One record per file. Logs only append. Index is derived and disposable.
3. **Single-writer.** Nightly run is the only writer. `state/bazaar.lock` prevents collisions.
4. **Two-plane isolation.** Host = control plane (secrets, reasoning, publishing). Docker container = data plane (no secrets, runs untrusted generators/solvers/playtesters). Generated game code never executes in the host shell.
5. **Unsolvable is terminal-with-findings.** A failed playtest advances to a report, not a halt.
6. **Reproducible artifact.** Every published puzzle carries the exact prompt, seed, source-refs, and build commands that produced it.
7. **Solution gating.** `solution.md` is NEVER embedded in gist body or blog post body. Solutions ship as a separate, gated artifact (gist with restricted visibility, or scsiwyg subscriber-only post).
8. **Secrets never reach the data plane or the outputs.** Outputs scrubbed before they ship.

---

## 3. Topology

```
┌─────────────────────────── HOST (control plane) ────────────────────────────┐
│  secrets: Anthropic, Slack, GitHub, scsiwyg, GHCR                            │
│  egress: anthropic, slack, github, scsiwyg, package registries              │
│                                                                             │
│  puzzle-orchestrator                                                        │
│    ├── puzzle-harvester-slack    (🧩 reactions in #development)              │
│    ├── puzzle-harvester-sources  (URL/file/query intake)                    │
│    ├── puzzle-researcher                                                    │
│    ├── puzzle-designer           (taxonomy + design.md)                     │
│    ├── puzzle-reporter                                                      │
│    ├── puzzle-curator            (collections, cross-links)                 │
│    └── puzzle-publisher                                                     │
│                                                                             │
│           ◄── artifact, test logs ──┐                                       │
│                                     │                                       │
│           ── puzzle + spec ──►  ┌───┴──── DOCKER (data plane) ──────┐       │
│                                 │  no secrets                       │       │
│                                 │  egress: registries only          │       │
│                                 │  puzzle-builder   (render game)   │       │
│                                 │  puzzle-tester    (solver run)    │       │
│                                 │  puzzle-packager  (bundle)        │       │
│                                 └── disposable, per-puzzle ─────────┘       │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Facility layout

```
~/bazaar/                          # visible — browsable
  manifest.yaml                    # facility config
  inbox/                           # drop URLs / files / one-line queries here
  puzzles/
    PUZ-0007-cipher-of-the-lake/
      puzzle.yaml                  # canonical record
      research.md
      design.md
      build/                       # source files
        log.txt
      artifact/                    # the playable thing
        index.html
        assets/
      solution.md                  # GATED — never in gist body or blog body
      test/
        log.txt
        solver-trace.json
      deploy/                      # if needed
        Dockerfile
        compose.yaml
        RUN.md
      report.md
  collections/                     # curator output
    COL-0001-ciphers-of-summer/
      collection.yaml
      index.md
  state/
    state.json
    activity.ndjson
    cursor.yaml
    bazaar.lock
    logs/run-YYYY-MM-DD.txt
```

`puzzles/` and `collections/` are durable. `state/` is rebuildable.

---

## 5. Entity — `puzzles/PUZ-NNNN-slug/puzzle.yaml`

```yaml
id: PUZ-0007
slug: cipher-of-the-lake
phase: published
created: 2026-06-21T03:14:00Z
updated: 2026-06-21T03:41:12Z

source:
  surface: slack            # slack | inbox | query
  channel: "#development"
  message_ts: "1718900000.001200"
  marked_by: david
  marked_with: "🧩"
  url: https://en.wikipedia.org/wiki/Voynich_manuscript
  prompt: "make a beginner cipher inspired by the Voynich"

research:
  theme: "Voynich-style botanical script"
  mechanics_inspiration: "polyalphabetic with herbal key"
  comparables: [Kryptos, Beale, Cicada-3301]
  source_refs:
    - https://...

design:
  type: cipher              # cipher | logic | paper | casual-web | arg | riddle | escape | treasure-hunt
  template: cipher.simple-substitution
  difficulty_target: beginner
  win_condition: "decoded plaintext equals 'come find the lake at dawn'"
  estimated_solve_time_min: 20

build:
  artifact_kind: html-static  # html-static | pdf | breadcrumb-pack | docker-web
  base_image: node:20         # null for pure paper puzzles
  exit_code: 0
  duration_s: 38
  status: built               # built | build-failed

test:
  solver_passed: true
  unique_solution: true
  difficulty_actual: beginner-medium
  notes: "Solver found alt path via letter frequency; intended path also works."
  status: solvable            # solvable | unsolvable | ambiguous

package:
  bundle_ref: deploy/
  image: null                 # ghcr ref if pushed

report:
  ref: report.md
  solution_ref: solution.md   # gated; not embedded in outputs

curation:
  collection_ids: [COL-0001]
  tags: [cipher, beginner, voynich, atmospheric]

outputs:
  gist_url: https://gist.github.com/...
  blog_post_id: scsiwyg:published:1421
  solution_gist_url: https://gist.github.com/...  # private/gated
  work_state_event_id: WRK-44219
```

---

## 6. Phase machine

```
candidate ─► researched ─► designed ─► built ─► tested ─► packaged ─► reported ─► published
                                          │
                                          └─► build-failed ──┐
                                                             ▼
                                                          reported (failure sense)
                                          tested:unsolvable ──┐
                                                              ▼
                                                          reported (unsolvable sense)
```

`build-failed` and `tested:unsolvable` are both terminal-with-findings: they advance to report and publish.

---

## 7. Skills (one §-per-skill, brief)

See each skill's `SKILL.md` for the full contract. Same write-discipline as forge-state: **only `/puzzle-state` writes the substrate.**

1. **puzzle-state** — substrate spine.
2. **puzzle-harvester-slack** — 🧩 reactions → candidates.
3. **puzzle-harvester-sources** — `~/bazaar/inbox/` + `manifest.sources[]` → candidates.
4. **puzzle-researcher** — research.md + source_refs.
5. **puzzle-designer** — pick taxonomy type + design.md.
6. **puzzle-builder** — generate artifact in sandbox.
7. **puzzle-tester** — solver pass; outcome solvable / unsolvable / ambiguous.
8. **puzzle-packager** — deploy bundle.
9. **puzzle-curator** — collections, cross-links, tag maps.
10. **puzzle-reporter** — report.md + solution.md.
11. **puzzle-publisher** — gist + scsiwyg + work-state.
12. **puzzle-orchestrator** — nightly walk.

---

## 10. Puzzle taxonomy (template families)

| type | template id | artifact kind |
|---|---|---|
| cipher | `cipher.simple-substitution`, `cipher.polyalphabetic`, `cipher.steganographic` | html-static |
| logic | `logic.grid-deduction`, `logic.nikoli-family`, `logic.lateral` | html-static or pdf |
| paper | `paper.crossword`, `paper.maze`, `paper.fold-and-cut` | pdf |
| casual-web | `web.match-n-bridge`, `web.platformer-micro`, `web.text-adventure` | docker-web |
| arg | `arg.breadcrumb-trail`, `arg.dead-drop`, `arg.character-pov` | breadcrumb-pack |
| riddle | `riddle.lateral`, `riddle.poem-with-key` | scsiwyg-post |
| escape | `escape.linear-locks`, `escape.scene-graph` | html-static |
| treasure-hunt | `hunt.clue-chain`, `hunt.geo-pinned` | breadcrumb-pack |

Templates live in `templates/types/<template_id>.template/`.

---

## 18. Locked decisions

1. **Intake** — `#development` channel, `🧩` marker, self-only. Sources harvester also active (`~/bazaar/inbox/` + manifest `sources[]`).
2. **Packaging push** — YES for `docker-web` and `breadcrumb-pack` artifacts; static HTML and PDF do not require a push.
3. **Blog publishing** — auto-publish to scsiwyg.
4. **Solution gating** — solution.md never embedded in gist body or blog body. Ships as a separately-gated gist or scsiwyg subscriber-only post; `outputs.solution_gist_url` carries the gated ref.
5. **Durability mirror** — GitHub private repo; set `durability.mirror.remote` in manifest before relying on it.
6. **Facility location** — `~/bazaar/` visible, `state/` (not `.state/`) for machinery.
