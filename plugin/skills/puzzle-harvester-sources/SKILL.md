---
name: puzzle-harvester-sources
description: Use to drain user-provided source material into candidate puzzles — files dropped into ~/bazaar/inbox/ and recurring source feeds declared in manifest.yaml under intake.sources[]. Handles URLs (*.url), prompts (*.md, *.txt, *.query), reference media (*.pdf, *.png, *.jpg), and seed entries. The non-Slack intake path; new vs forge-state because research-driven puzzles need an explicit source pipeline. Trigger phrases include "/puzzle-harvester-sources", "ingest the inbox", "harvest puzzle sources", "process new source feeds".
---

# puzzle-harvester-sources

The non-Slack intake path. Two sub-modes:

## A. Inbox drain

1. List files in `~/bazaar/inbox/` (skip `README.md`).
2. For each file, classify:
   - `.url` → single URL, one candidate with `source.surface=inbox` and `url=<contents>`
   - `.query` / first-line of `.txt` / `.md` → research query, one candidate with `prompt=<contents>`
   - `.pdf` / `.png` / `.jpg` → reference media, attach as `puzzles/PUZ-NNNN-slug/build/inputs/<filename>` and create a candidate prompted "build a puzzle inspired by the attached reference"
3. Call `/puzzle-state allocate-id PUZ` per candidate, write `puzzle.yaml` at `phase: candidate`.
4. Move processed files to `state/processed-inbox/YYYY-MM-DD/`.

## B. Source feeds

For each entry in `manifest.intake.sources[]`:

- `kind: prompt-seed` — emit one candidate per cadence window (weekly / monthly) using `value` as the prompt.
- `kind: rss` (future) — fetch feed, dedupe vs cursor, emit candidates for new entries.
- `kind: archive` (future) — walk an archive URL/directory on cadence.

Cursor for each source feed lives in `state/cursor.yaml` under `sources.<name>`.

## Outputs

- N new `puzzles/PUZ-NNNN-slug/puzzle.yaml` at `phase: candidate`
- Inbox files moved to `state/processed-inbox/`
- One activity event per write
