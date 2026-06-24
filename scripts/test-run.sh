#!/usr/bin/env bash
# test-run.sh — smoke-test the puzzle-state orchestrator in dry-run mode.
set -euo pipefail
echo "puzzle-state test run (dry-run)"
echo "facility: ${BAZAAR_ROOT:-$HOME/bazaar}"
echo
echo "From inside a Claude Code session, run:"
echo "  /puzzle-orchestrator --dry-run"
echo "  /puzzle-orchestrator --once"
