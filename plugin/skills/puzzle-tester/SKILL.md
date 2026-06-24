---
name: puzzle-tester
description: Use to playtest a built puzzle in the sandbox — runs a solver pass against the artifact, checks the win condition, evaluates difficulty and solution uniqueness. Outcome is solvable, unsolvable, or ambiguous; all three advance. Advances phase built → tested. Trigger phrases include "/puzzle-tester", "test PUZ-0007", "playtest the latest built puzzle".
---

# puzzle-tester

Runs in the data plane. The solver is an LLM-driven attempt at the puzzle plus, where applicable, a programmatic checker (e.g. a CSP solver for logic grids, a frequency-analysis pass for ciphers).

## Inputs

- `puzzles/PUZ-NNNN-slug/puzzle.yaml` at `phase: built`
- `artifact/`
- `design.win_condition`
- `design.solution_sketch` (used for verification, not given to the solver)

## Behavior

1. Spawn solver container with `artifact/` mounted read-only.
2. Run the solver against the artifact WITHOUT access to `design.solution_sketch` or `solution.md`.
3. Capture solver trace to `test/solver-trace.json`, log to `test/log.txt`.
4. Verify solver output against `design.win_condition`.
5. Determine status:
   - `solvable` — solver reached win condition, solution matches sketch
   - `unsolvable` — solver could not reach win condition within `manifest.testing.solver.max_solve_time_s`
   - `ambiguous` — solver reached a valid win-condition state via an unintended path; `manifest.testing.solver.require_unique_solution` toggles whether this fails or just gets noted
6. Fill `puzzle.yaml.test.*`, advance to `tested` (all three statuses).

## Findings discipline

`unsolvable` and `ambiguous` are publishable findings (spec §2.5). The reporter prints them honestly; the publisher routes them as a "failed-but-interesting" post on scsiwyg if `manifest.surfaces.blog.publish_findings` is true.
