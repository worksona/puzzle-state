---
name: puzzle-state
description: Use when any puzzle-* skill or user request needs to read, write, or validate the puzzle-state facility at ~/bazaar/ — including init, allocating a PUZ-NNNN id, advancing a puzzle's phase, scrubbing secrets and solutions from outputs, or appending to state/activity.ndjson. The only skill permitted to write the substrate to disk. Trigger phrases include "/puzzle-state", "init the bazaar", "validate the puzzle facility", "advance PUZ-0007 to packaged", "scrub this report", or any puzzle-* skill that needs persistence.
---

# puzzle-state — substrate spine

The shared memory of the bazaar. Every other puzzle-* skill routes its reads and writes through this one — no skill writes the substrate directly (spec §2 invariant).

## When to use

- A puzzle skill needs to read or update a `puzzles/PUZ-NNNN-slug/puzzle.yaml` record.
- The orchestrator needs to allocate a new puzzle id, advance a phase, append to activity log, refresh `state/state.json`.
- The user asks to init the facility, validate it, or audit drift.
- A publisher needs to scrub secrets AND redact solutions before shipping.

## Facility layout (canonical — spec §4)

```
~/bazaar/
  manifest.yaml
  inbox/
  puzzles/PUZ-NNNN-slug/
    puzzle.yaml         # canonical record
    research.md
    design.md
    build/log.txt
    artifact/           # the playable thing
    solution.md         # GATED — never embedded in gist/blog body
    test/log.txt
    deploy/{Dockerfile,compose.yaml,RUN.md}
    report.md
  collections/COL-NNNN-slug/{collection.yaml,index.md}
  state/
    state.json
    activity.ndjson
    cursor.yaml
    bazaar.lock
    logs/run-YYYY-MM-DD.txt
```

`puzzles/` and `collections/` are durable. `state/` is rebuildable.

## Operations

| op | inputs | effect |
|---|---|---|
| `init` | (none) | run `scripts/init-facility.sh`; idempotent |
| `read` | path | return YAML/JSON/markdown contents |
| `write` | path, content | validate (schema for YAML), write |
| `validate` | (none) | walk puzzles + collections, validate against schemas |
| `allocate-id` | kind (PUZ \| COL) | scan and return next id |
| `advance-phase` | id, new_phase | update puzzle.yaml; append activity event; refresh state.json counts |
| `scrub` | text, kind | redact secrets (always) AND solutions (if kind=public-output) → return scrubbed |
| `lock` / `unlock` | (none) | acquire/release `state/bazaar.lock` for the nightly run |

## Solution-redaction (spec §2.7)

`scrub` with `kind=public-output` MUST redact:
- known secret values from the secret store
- the contents of any `solution.md` for any puzzle referenced in the text
- any decoded plaintext / answer key / cheat string embedded inline

A puzzle published with its solution in the gist body is a defect.
