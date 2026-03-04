#!/usr/bin/env bash
set -euo pipefail

# Session close helper for markdown-memory skill
# Usage: session-close.sh [workspace]

WORKSPACE="${1:-$(pwd)}"
MEMORY_DIR="${WORKSPACE}/memory"
CORE_DIR="${MEMORY_DIR}/CORE"
TODAY="$(date '+%Y-%m-%d')"
NOW="$(date '+%Y-%m-%d %H:%M:%S %z')"
DAILY_FILE="${MEMORY_DIR}/daily/${TODAY}.md"
STATE_FILE="${CORE_DIR}/current-state.md"

mkdir -p "$MEMORY_DIR/daily" "$CORE_DIR"

echo "=== markdown-memory: session close ==="
echo "timestamp: $NOW"

# 0) run auto-tagger first (local ollama small model)
TAGGER_SCRIPT="$WORKSPACE/skills/markdown-memory/scripts/memory-auto-tag.py"
if [[ -x "$TAGGER_SCRIPT" ]]; then
  echo "run tagger(review): memory-auto-tag.py"
  python3 "$TAGGER_SCRIPT" "$WORKSPACE" --mode review || echo "warning: auto-tagger failed"
fi

if [[ ! -f "$DAILY_FILE" ]]; then
  cat > "$DAILY_FILE" <<EOF
# Daily Log - ${TODAY}

## What happened

## Decisions

## Completed

## Next

EOF
  echo "created: ${DAILY_FILE#$WORKSPACE/}"
fi

cat >> "$DAILY_FILE" <<EOF

---
### Session Note (${NOW})
- Summary: session closed
- Follow-up: review current-state and update if task status changed
EOF

echo "appended session note: ${DAILY_FILE#$WORKSPACE/}"

if [[ -f "$STATE_FILE" ]]; then
  echo "state file exists: ${STATE_FILE#$WORKSPACE/}"
  echo "reminder: update 'last_updated' and active tasks if anything changed."
else
  echo "warning: missing ${STATE_FILE#$WORKSPACE/}"
fi

echo "done."
