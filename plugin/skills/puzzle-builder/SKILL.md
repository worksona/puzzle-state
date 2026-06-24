---
name: puzzle-builder
description: Use to generate the playable artifact for a designed puzzle inside the Docker sandbox — HTML pages, PDFs, ARG breadcrumb packs, or web-game bundles. Reads design.type + design.template, renders into puzzles/PUZ-NNNN-slug/artifact/. Advances phase designed → built (or build-failed; both advance). Trigger phrases include "/puzzle-builder", "build PUZ-0007", "render the artifact for the latest designed puzzle".
---

# puzzle-builder

Runs in the data plane. The build never executes in the host shell — generated game JS, LaTeX, or solver code touches the host only as bytes-on-disk written from inside the container.

## Inputs

- `puzzles/PUZ-NNNN-slug/puzzle.yaml` at `phase: designed`
- `design.md`
- `templates/types/<template_id>.template/`

## Behavior

1. Pick `build.artifact_kind` from the template (html-static | pdf | breadcrumb-pack | docker-web | scsiwyg-post).
2. Pick `build.base_image` from `manifest.sandbox.base_images` matching the artifact kind.
3. Start a per-puzzle container, mount `puzzles/PUZ-NNNN-slug/build/` rw and `templates/types/<template_id>.template/` ro.
4. Inside the container, render the artifact into `build/`, then copy/move to `artifact/`.
5. Capture stdout/stderr to `build/log.txt`. Set `build.exit_code`, `build.duration_s`.
6. On success: `build.status: built`, advance to `built`.
7. On failure: `build.status: build-failed`, advance to `build-failed`. **This still advances** — the reporter handles failure as a publishable finding (spec §2.5).

## Egress

Container egress is restricted to package registries (`manifest.sandbox.egress: registries-only`). No outbound calls to user-controlled domains from inside the build.

## Idempotency

A re-run after `built` is a no-op unless the puzzle is reset to `designed`.
