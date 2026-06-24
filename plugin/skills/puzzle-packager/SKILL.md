---
name: puzzle-packager
description: Use to emit the deploy/ bundle for a tested puzzle — Dockerfile + compose + RUN.md for docker-web and arg-pack kinds; static-site index for html-static; print-ready PDF copy for paper. Optionally pushes web/ARG images to ghcr.io. Advances phase tested → packaged. Trigger phrases include "/puzzle-packager", "package PUZ-0007", "bundle the latest tested puzzle".
---

# puzzle-packager

Produces the runnable artifact a user can take home.

## Inputs

- `puzzles/PUZ-NNNN-slug/puzzle.yaml` at `phase: tested`
- `artifact/`
- `build.artifact_kind`

## Behavior by kind

| artifact_kind | emit |
|---|---|
| `html-static` | `deploy/RUN.md` ("open artifact/index.html"); no compose |
| `pdf` | `deploy/RUN.md` (print + solve); copy PDF into deploy/ |
| `docker-web` | `deploy/Dockerfile`, `deploy/compose.yaml`, `deploy/RUN.md`; build image; push to ghcr if `manifest.packaging.push_image` |
| `breadcrumb-pack` | `deploy/RUN.md` (where to plant each breadcrumb); zip pack |
| `scsiwyg-post` | `deploy/RUN.md` is the post-publish receipt; no bundle |

## Push policy

Only `docker-web` and `breadcrumb-pack` need pushed images (rarely). Static HTML and PDF do not push anything to a registry. `package.image` is the ghcr ref when pushed, else null.

## Idempotency

Re-running on `packaged` is a no-op. Re-running after a content change requires resetting to `tested`.
