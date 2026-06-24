---
name: puzzle-researcher
description: Use to research a candidate puzzle's theme, mechanics inspiration, comparables, and source refs. Reads source.url / source.prompt, performs web research, writes research.md and fills the research block on puzzle.yaml. Advances phase candidate → researched. Trigger phrases include "/puzzle-researcher", "research PUZ-0007", "fill out the research for the latest candidate".
---

# puzzle-researcher

The first reasoning pass on a candidate. Turns "here is a URL and a prompt" into "here is what this puzzle could be about, what mechanics are in scope, and what other puzzles it sits next to."

## Inputs

- `puzzles/PUZ-NNNN-slug/puzzle.yaml` at `phase: candidate`
- `source.url`, `source.prompt`, attached references in `build/inputs/`

## Behavior

1. Fetch + read `source.url` if present.
2. Do bounded web research: at most 6 searches, at most 12 fetches. Prefer primary / archival sources.
3. Compose `research.md` with five sections:
   - **Theme** — the atmospheric / conceptual frame
   - **Mechanics inspiration** — what puzzle mechanics the theme suggests (substitution? grid deduction? scavenger trail?)
   - **Comparables** — 3-5 existing puzzles in the same space
   - **Source refs** — URLs used
   - **Open hooks** — questions the designer should answer next
4. Fill `puzzle.yaml.research.{theme, mechanics_inspiration, comparables, source_refs}`.
5. Advance via `/puzzle-state advance-phase PUZ-NNNN researched`.

## Output discipline

Research is non-prescriptive — it suggests directions, it does not lock the design type. The designer picks the type in the next phase. If research surfaces a single obvious type, note it in **Open hooks**, do not write it into `design.type` yet.
