---
name: puzzle-harvester-slack
description: Use to drain 🧩 reactions from configured Slack channels (default `#development`) into candidate puzzle records under ~/bazaar/puzzles/. Tracks per-channel cursor in state/cursor.yaml so it never re-processes. Trigger phrases include "/puzzle-harvester-slack", "harvest slack for puzzles", "check #development for 🧩".
---

# puzzle-harvester-slack

Reads the configured channels, finds messages reacted with the intake marker (default `🧩`, self-only by default), and writes one candidate per new message via `puzzle-state`.

## Behavior

1. Read `manifest.yaml` → `intake.slack.channels`, `intake.slack.marker`, `intake.slack.markers_self_only`.
2. Read `state/cursor.yaml` → per-channel last-processed `message_ts`.
3. For each channel, query Slack for messages after the cursor; filter to those with the marker reaction.
4. For each new message: call `/puzzle-state allocate-id PUZ` and write a candidate `puzzle.yaml` populated from the message (url if present, prompt text, marked_by, message_ts).
5. Advance cursor only after successful write.

## Idempotency

`source.message_ts` is the key. Re-running with the same cursor yields zero new candidates. A message reacted twice produces one candidate.

## Outputs

- N new `puzzles/PUZ-NNNN-slug/puzzle.yaml` records at `phase: candidate`
- One activity event per write
- Updated `state/cursor.yaml`
