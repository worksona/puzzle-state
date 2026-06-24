#!/usr/bin/env bash
# init-facility.sh — create the puzzle-state facility at ~/bazaar (idempotent).
# No dot-directories: machinery lives in `state/`, not `.state/`.
set -euo pipefail

ROOT="${BAZAAR_ROOT:-$HOME/bazaar}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"

mkdir -p "$ROOT/puzzles"
mkdir -p "$ROOT/collections"
mkdir -p "$ROOT/inbox"
mkdir -p "$ROOT/state/logs"

if [[ ! -f "$ROOT/manifest.yaml" ]]; then
  cp "$REPO_ROOT/templates/manifest.yaml.template" "$ROOT/manifest.yaml"
  echo "wrote: $ROOT/manifest.yaml"
else
  echo "exists: $ROOT/manifest.yaml (left as-is)"
fi

if [[ ! -f "$ROOT/state/state.json" ]]; then
  cat > "$ROOT/state/state.json" <<'JSON'
{
  "counts_by_phase": {},
  "last_run": null,
  "last_cursor": {},
  "carry_forward": []
}
JSON
  echo "wrote: $ROOT/state/state.json"
else
  echo "exists: $ROOT/state/state.json (left as-is)"
fi

if [[ ! -f "$ROOT/state/activity.ndjson" ]]; then
  : > "$ROOT/state/activity.ndjson"
  echo "wrote: $ROOT/state/activity.ndjson"
else
  echo "exists: $ROOT/state/activity.ndjson (left as-is)"
fi

if [[ ! -f "$ROOT/state/cursor.yaml" ]]; then
  echo '{}' > "$ROOT/state/cursor.yaml"
  echo "wrote: $ROOT/state/cursor.yaml"
else
  echo "exists: $ROOT/state/cursor.yaml (left as-is)"
fi

if [[ ! -f "$ROOT/inbox/README.md" ]]; then
  cat > "$ROOT/inbox/README.md" <<'MD'
# inbox/

Drop puzzle source material here. The next nightly run will ingest it:

- `*.url` — single URL per file
- `*.md` / `*.txt` — free-form prompts, themes, or pasted source
- `*.pdf` / `*.png` / `*.jpg` — reference material
- `*.query` — one-line research query

Processed files move to `state/processed-inbox/<date>/`.
MD
  echo "wrote: $ROOT/inbox/README.md"
fi

echo
echo "puzzle-state bazaar ready at: $ROOT"
