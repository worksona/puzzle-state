---
name: puzzle-orchestrator
description: Nightly conductor for the bazaar. Acquires state/bazaar.lock, walks the queue once, dispatches the right puzzle-* skill per puzzle based on its phase. Supports --once (one walk and exit) and --dry-run (plan without writing). Honors per-puzzle and night budgets from manifest. Trigger phrases include "/puzzle-orchestrator", "/puzzle-orchestrator --once", "/puzzle-orchestrator --dry-run", "run the nightly", "walk the bazaar queue".
---

# puzzle-orchestrator

Thin router. Decides nothing the per-puzzle phase doesn't already imply; it just sequences and budgets.

## Walk order

1. Acquire `state/bazaar.lock`. If held, exit (another run is active).
2. **Harvest** — `/puzzle-harvester-slack`, then `/puzzle-harvester-sources`.
3. **Walk puzzles by phase**, oldest first:
   - `candidate` → `/puzzle-researcher`
   - `researched` → `/puzzle-designer`
   - `designed` → `/puzzle-builder`
   - `built` → `/puzzle-tester`
   - `build-failed` → `/puzzle-reporter` (failure sense)
   - `tested` → `/puzzle-packager` (if solvable) OR `/puzzle-reporter` (if unsolvable/ambiguous)
   - `packaged` → `/puzzle-reporter`
   - `reported` → `/puzzle-publisher`
   - `published` → skip
4. **Curate** — `/puzzle-curator` over puzzles at `phase >= reported`.
5. Refresh `state/state.json` counts. Release lock.

## Flags

- `--once` — single pass, exit when queue is drained or budget hit
- `--dry-run` — log the plan to `state/logs/run-YYYY-MM-DD.txt`, do not invoke writes

## Budgets

- `manifest.sandbox.per_puzzle_timeout_s` — kills any single puzzle's container after the limit; marks `build-failed` or `tested: unsolvable` accordingly
- `manifest.sandbox.night_budget_s` — caps total wall clock; remaining puzzles carry forward via `state.json.carry_forward[]`

## Idempotency

Re-running an interrupted night picks up where it stopped via per-puzzle phase. The lock prevents two simultaneous walks.
