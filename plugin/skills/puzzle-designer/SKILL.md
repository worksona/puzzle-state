---
name: puzzle-designer
description: Use to pick a puzzle taxonomy type for a researched puzzle, choose a template from templates/types/, and write design.md (mechanics, win condition, difficulty target, estimated solve time). Advances phase researched → designed. Trigger phrases include "/puzzle-designer", "design PUZ-0007", "pick a type for the latest researched puzzle".
---

# puzzle-designer

Translates research into a buildable spec.

## Inputs

- `puzzles/PUZ-NNNN-slug/puzzle.yaml` at `phase: researched`
- `research.md`

## Behavior

1. Read research + manifest `design.allowed_types`.
2. Pick `design.type` from the §10 taxonomy: cipher | logic | paper | casual-web | arg | riddle | escape | treasure-hunt.
3. Pick a template id from `templates/types/<type>.<template_id>.template/` (e.g. `cipher.simple-substitution`).
4. Write `design.md` with:
   - **Type + template** chosen and why
   - **Mechanics** — concrete rules, components, surfaces
   - **Win condition** — exact, testable (the tester uses this verbatim)
   - **Difficulty target** — beginner / intermediate / advanced; reasoning
   - **Estimated solve time** — minutes
   - **Solution sketch** — short paragraph (NOT the full solution — that's reporter's job)
5. Fill `puzzle.yaml.design.*` and advance via `/puzzle-state advance-phase PUZ-NNNN designed`.

## Win-condition discipline

The win condition is what `puzzle-tester` checks. If it cannot be expressed in a few crisp lines a solver can verify against, the design is not ready — iterate before advancing.
