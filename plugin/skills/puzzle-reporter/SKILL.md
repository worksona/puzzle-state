---
name: puzzle-reporter
description: Use to compose report.md and solution.md for a packaged (or build-failed / unsolvable) puzzle. Reports handle three senses — success, build-failed, unsolvable — each with its own honest framing. Solution.md is always written but never embedded in public outputs (spec §2.7). Advances phase packaged → reported. Trigger phrases include "/puzzle-reporter", "report PUZ-0007", "write up the latest packaged puzzle".
---

# puzzle-reporter

The narrative pass. Two files, one phase advance.

## report.md (public-safe)

The user-facing writeup. Goes into the gist body and the scsiwyg post body. Contains:

- The pitch — what the puzzle is, where it came from
- The provenance — research summary + source refs
- The build receipt — base image, commands, exit, duration
- The playtest — solver outcome (solvable / unsolvable / ambiguous), difficulty actual vs target
- How to play / run — extracted from `deploy/RUN.md`
- Link out to the gated solution

**Never includes** the solution, decoded plaintext, win-condition specifics that give the puzzle away, or any secret values.

## solution.md (gated)

The full key. Published separately under `outputs.solution_gist_url` (secret gist) and/or `outputs.blog_post_id_solution` (subscribers-only scsiwyg post). Contains:

- The intended solution path
- Alternate paths the tester found
- Where the puzzle leaks (if `ambiguous`)
- Designer notes — what was tried, what was cut

## Three senses

| from_status | report framing |
|---|---|
| `solvable` | "puzzle ships, here's the writeup" |
| `build-failed` | "tried to build, here's what broke" — honest finding |
| `unsolvable` / `ambiguous` | "puzzle as designed has no unique path / no path" — finding |

All three advance to `reported`.
