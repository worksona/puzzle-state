---
name: puzzle-publisher
description: Use to ship a reported puzzle — create a public gist with the report + artifact, publish an scsiwyg post (auto), publish a gated solution gist, emit a work-state event. Routes outputs through /puzzle-state scrub kind=public-output FIRST to redact secrets AND solutions. Advances phase reported → published. Trigger phrases include "/puzzle-publisher", "publish PUZ-0007", "ship the latest reported puzzle".
---

# puzzle-publisher

The egress skill. Three surfaces, one event, strict scrub-first discipline.

## Order of operations

1. `/puzzle-state scrub kind=public-output` on `report.md`, `artifact/index.html` (and any other public asset). Must pass clean.
2. **Public gist** — create gist with `report.md` + `artifact/` payload. Record `outputs.gist_url`.
3. **scsiwyg post** — compose post (title from puzzle.slug + design.type + difficulty); body is the scrubbed `report.md`; auto-publish. Record `outputs.blog_post_id`.
4. **Gated solution gist** — create secret gist with `solution.md`. Record `outputs.solution_gist_url`. Add a link to it ONLY at the bottom of the public surfaces, never inline near hints.
5. **work-state event** — emit a `puzzle.published` event with PUZ id, type, difficulty, and the three URLs. Record `outputs.work_state_event_id`.
6. Advance to `published`.

## Findings sense

When the upstream phase is `build-failed` or `tested:unsolvable`, the publisher still ships if `manifest.surfaces.blog.publish_findings` is true. Gist title and scsiwyg post title prefix with `[finding]` to set reader expectations.

## Solution leak guard

Before any surface call, re-scan the outbound body for the contents of `solution.md`. If any substring of solution.md ≥40 chars appears in the body, ABORT and fail loudly. A leaked solution is a defect.
