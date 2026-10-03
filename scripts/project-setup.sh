#!/usr/bin/env bash
# Set up one repo (new or existing). Adds only what is missing, never overwrites your files.
#   ./scripts/project-setup.sh [dir]   (default: current directory)
set -euo pipefail

DEST=$(mkdir -p "${1:-$PWD}" && cd "${1:-$PWD}" && pwd)
REPO=$(cd "$(dirname "$0")/.." && pwd)
NAME=$(basename "$DEST")
[ "$DEST" = "$REPO" ] && { echo "Skipping project setup inside the initial_setup repo itself."; exit 0; }
echo "Project: $DEST"

# git
[ -d "$DEST/.git" ] || { git -C "$DEST" init -q; echo "  git init"; }

# CLAUDE.md: team rules, project name and setup-repo path filled in
if [ ! -f "$DEST/CLAUDE.md" ]; then
  sed -e "s#{{PROJECT_NAME}}#$NAME#g" -e "s#{{SETUP_REPO}}#$REPO#g" "$REPO/templates/CLAUDE.md" > "$DEST/CLAUDE.md"
  echo "  added CLAUDE.md"
fi

# .mcp.json: merge in our servers, keep any the project already has
python3 - "$DEST/.mcp.json" "$REPO/templates/mcp.json" <<'PY'
import json, os, sys
dst, tpl = sys.argv[1], json.load(open(sys.argv[2]))
d = json.load(open(dst)) if os.path.exists(dst) else {}
servers = d.setdefault("mcpServers", {})
added = [k for k in tpl["mcpServers"] if k not in servers]
for k in added: servers[k] = tpl["mcpServers"][k]
json.dump(d, open(dst, "w"), indent=2)
if added: print("  .mcp.json: added " + ", ".join(added))
PY

# .gitignore: append any missing lines
touch "$DEST/.gitignore"
while IFS= read -r line; do
  [ -z "$line" ] && continue
  grep -qxF -- "$line" "$DEST/.gitignore" || { echo "$line" >> "$DEST/.gitignore"; echo "  .gitignore: $line"; }
done < "$REPO/templates/gitignore"

# OpenSpec: specs folder plus the /opsx commands for Claude Code. Runs every time: it keeps
# config.yaml and existing specs, and restores missing or outdated commands.
(cd "$DEST" && openspec init --tools claude --no-animation >/dev/null)
echo "  openspec init"
# Existing CLAUDE.md files miss template sections added later: copy each one in if absent
python3 - "$DEST/CLAUDE.md" "$REPO/templates/CLAUDE.md" <<'PY'
import re, sys
dst, tpl = sys.argv[1], open(sys.argv[2]).read()
s = open(dst).read()
# Specs: stops superpowers writing a second spec folder.
for title in ("Specs (OpenSpec)",):
    if f"## {title}" in s: continue
    sec = re.search(rf"^## {re.escape(title)}\n.*?(?=^## )", tpl, re.S | re.M).group(0)
    s = s.replace("## The loop", sec + "## The loop", 1) if "## The loop" in s else s.rstrip() + "\n\n" + sec
    print(f"  CLAUDE.md: added {title} section")
open(dst, "w").write(s)
PY

# ruflo: minimal project init (skills, hooks config, .claude-flow runtime). No sign-up, no global edits.
if [ ! -d "$DEST/.claude-flow" ]; then
  (cd "$DEST" && RUFLO_NO_SKILLS_SH=1 ruflo init --minimal --no-signup --no-global --no-mods --no-codex-detect --no-skills-sh >/dev/null 2>&1)
  echo "  ruflo init (minimal)"
fi
# ruflo pins an older model and a status line whose helper it doesn't ship; remove both
python3 - "$DEST/.claude/settings.json" <<'PY'
import json, os, sys
p = sys.argv[1]
if not os.path.exists(p): sys.exit()
d = json.load(open(p)); before = json.dumps(d)
d.pop("model", None); d.get("claudeFlow", {}).pop("modelPreferences", None)
if "statusline.cjs" in d.get("statusLine", {}).get("command", "") and not os.path.exists(os.path.join(os.path.dirname(p), "helpers/statusline.cjs")):
    d.pop("statusLine", None)
if json.dumps(d) != before:
    json.dump(d, open(p, "w"), indent=2); print("  .claude/settings.json: removed ruflo model pin / dead status line")
PY

echo "Done. Open with: cd $DEST && claude   (approve the playwright-chrome MCP server when asked)"
