#!/usr/bin/env bash
# Copy your live custom skills (~/.claude/skills) back into this repo after you change them.
#   ./scripts/sync-skills.sh            sync every skill already in skills/
#   ./scripts/sync-skills.sh my-skill   also add a new skill to the repo
set -euo pipefail
REPO=$(cd "$(dirname "$0")/.." && pwd)
LIVE="$HOME/.claude/skills"
names=$(ls "$REPO/skills"; [ $# -gt 0 ] && printf '%s\n' "$@")
for s in $(echo "$names" | sort -u); do
  [ -f "$LIVE/$s/SKILL.md" ] || { echo "skip $s (not in $LIVE)"; continue; }
  rsync -a --delete --exclude .DS_Store "$LIVE/$s/" "$REPO/skills/$s/"
  echo "synced $s"
done
git -C "$REPO" status --short skills/
