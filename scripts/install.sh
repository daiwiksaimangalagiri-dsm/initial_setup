#!/usr/bin/env bash
# Machine-level install of everything in docs/intitial_setup.md. Safe to re-run: anything present is skipped.
#   ./scripts/install.sh                  install what is missing
#   ./scripts/install.sh --update-skills  also replace custom skills that changed in the repo
# Versions are pinned to what the team verified; bump them here and in the doc together.
set -euo pipefail

NVM_VERSION=v0.39.7
PLAYWRIGHT_VERSION=1.63.0
PLAYWRIGHT_MCP_VERSION=0.0.83
PLAYWRIGHT_CLI_VERSION=0.1.22
RUFLO_VERSION=3.51.1
HEADROOM_VERSION=0.39.1
BUN_VERSION=1.4.2
GH_VERSION=2.102.0
OPENSPEC_VERSION=1.14.0
MERMAID_CLI_VERSION=12.0.0
LIKEC4_VERSION=1.59.4
DEPCRUISE_VERSION=18.5.0
DEPCRUISE_TS_VERSION=5.9.3   # dependency-cruiser 18.5 needs TypeScript < 7; with TS 7 it silently finds nothing
GRAPHVIZ_WASM_VERSION=1.11.3
TACH_VERSION=0.35.2
DRAWIO_VERSION=31.7.0
DRAWIO_SHA256=bf52537fdc6454b6ff994e428d37032050e0baadbce78104b5a46405444ade81
CLAUDE_PLUGINS="superpowers@claude-plugins-official playwright@claude-plugins-official context7@claude-plugins-official frontend-design@claude-plugins-official figma@claude-plugins-official claude-code-setup@claude-plugins-official"

REPO=$(cd "$(dirname "$0")/.." && pwd)
step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }
export PATH="$HOME/.local/bin:$PATH"

step "Xcode Command Line Tools (git)"
xcode-select -p >/dev/null 2>&1 || { xcode-select --install; echo "Finish the Xcode CLT dialog, then re-run."; exit 1; }

step "nvm + Node.js LTS"
if [ ! -s "$HOME/.nvm/nvm.sh" ]; then
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash
fi
. "$HOME/.nvm/nvm.sh"
nvm ls --no-colors 'lts/*' >/dev/null 2>&1 || nvm install --lts
nvm alias default 'lts/*' >/dev/null

step "uv (Python tool installer)"
have uv || curl -LsSf https://astral.sh/uv/install.sh | sh

step "Bun (runtime the claude-mem plugin's hooks need, without it every session start fails)"
[ -x "$HOME/.bun/bin/bun" ] || curl -fsSL https://bun.sh/install | bash -s "bun-v$BUN_VERSION"

step "GitHub CLI (gh)"
if ! have gh; then
  T=$(mktemp -d); Z="gh_${GH_VERSION}_macOS_arm64.zip"
  curl -fsSL -o "$T/$Z" "https://github.com/cli/cli/releases/download/v$GH_VERSION/$Z"
  curl -fsSL -o "$T/sums" "https://github.com/cli/cli/releases/download/v$GH_VERSION/gh_${GH_VERSION}_checksums.txt"
  (cd "$T" && grep "$Z" sums | shasum -a 256 -c) && unzip -qo "$T/$Z" -d "$T" && cp "$T/gh_${GH_VERSION}_macOS_arm64/bin/gh" "$HOME/.local/bin/gh"
fi
gh auth status >/dev/null 2>&1 || echo "Sign in once with: gh auth login --git-protocol https --web"
# Once signed in, let git push and pull use the gh sign-in
if gh auth status >/dev/null 2>&1 && ! git config --global --get-all credential.https://github.com.helper | grep -q "gh auth git-credential"; then
  gh auth setup-git && echo "  git credentials: now use gh"
fi

step "Google Chrome"
[ -d "/Applications/Google Chrome.app" ] || echo "Install Chrome manually from https://www.google.com/chrome/ (no package manager on this machine)."

step "Playwright library, MCP server, CLI + ruflo"
npm_pin() { npm ls -g --depth=0 "$1@$2" >/dev/null 2>&1 || npm install -g "$1@$2"; }
npm_pin playwright "$PLAYWRIGHT_VERSION"
npm_pin @playwright/mcp "$PLAYWRIGHT_MCP_VERSION"
npm_pin @playwright/cli "$PLAYWRIGHT_CLI_VERSION"
npm_pin ruflo "$RUFLO_VERSION"

step "OpenSpec (spec-driven development: specs, changes, archive)"
npm_pin @fission-ai/openspec "$OPENSPEC_VERSION"
openspec config set telemetry.enabled false >/dev/null

step "Diagram tools (Mermaid CLI, LikeC4, dependency-cruiser, Graphviz WASM, tach)"
# mermaid-cli renders with your installed Chrome (diagram-render sets PUPPETEER_EXECUTABLE_PATH), so skip its 150 MB Chromium
PUPPETEER_SKIP_DOWNLOAD=1 npm_pin @mermaid-js/mermaid-cli "$MERMAID_CLI_VERSION"
npm_pin likec4 "$LIKEC4_VERSION"
npm_pin dependency-cruiser "$DEPCRUISE_VERSION"
npm_pin typescript "$DEPCRUISE_TS_VERSION"
npm_pin @hpcc-js/wasm-graphviz-cli "$GRAPHVIZ_WASM_VERSION"
tach --version 2>/dev/null | grep -q "$TACH_VERSION" || uv tool install --force "tach==$TACH_VERSION"

step "draw.io desktop (export + auto-layout for the draw.io plugin)"
if [ ! -d "/Applications/draw.io.app" ]; then
  T=$(mktemp -d); DMG="$T/drawio.dmg"
  curl -fsSL -o "$DMG" "https://github.com/jgraph/drawio-desktop/releases/download/v$DRAWIO_VERSION/draw.io-arm64-$DRAWIO_VERSION.dmg"
  echo "$DRAWIO_SHA256  $DMG" | shasum -a 256 -c
  MNT=$(hdiutil attach -nobrowse -readonly "$DMG" | tail -1 | awk -F'\t' '{print $NF}')
  cp -R "$MNT/draw.io.app" /Applications/ && hdiutil detach -quiet "$MNT"
  codesign --verify --deep /Applications/draw.io.app
fi

step "Playwright Chromium"
playwright install chromium

step "Claude Code"
have claude || curl -fsSL https://claude.ai/install.sh | bash

step "Claude Code plugins"
INSTALLED=$(claude plugin list 2>/dev/null || true)
for p in $CLAUDE_PLUGINS; do
  echo "$INSTALLED" | grep -q "❯ $p" || claude plugin install "$p"
done
# Third-party marketplaces: add once, then install
echo "$INSTALLED" | grep -q "❯ claude-mem@thedotmack" || { claude plugin marketplace add thedotmack/claude-mem; claude plugin install claude-mem@thedotmack; }
echo "$INSTALLED" | grep -q "❯ headroom@headroom-marketplace" || { claude plugin marketplace add headroomlabs-ai/headroom; claude plugin install headroom@headroom-marketplace; }
echo "$INSTALLED" | grep -q "❯ ponytail@ponytail" || { claude plugin marketplace add DietrichGebert/ponytail; claude plugin install ponytail@ponytail; }
echo "$INSTALLED" | grep -q "❯ drawio@drawio" || { claude plugin marketplace add jgraph/drawio-mcp; claude plugin install drawio@drawio; }

step "User-scope MCP servers (load in every session)"
claude mcp get ruflo >/dev/null 2>&1 || claude mcp add ruflo -s user -- ruflo mcp start
# GitHub's official MCP server. The token comes from gh / the keychain at connect time, never stored in config.
claude mcp get github >/dev/null 2>&1 || claude mcp add-json github -s user \
  "{\"type\":\"http\",\"url\":\"https://api.githubcopilot.com/mcp/\",\"headersHelper\":\"$REPO/scripts/github-mcp-headers.sh\"}"

step "Headroom (token-saving proxy, started by the headroom plugin at every session start)"
if ! headroom --version 2>/dev/null | grep -q "$HEADROOM_VERSION"; then
  uv tool install --force --python 3.13 "headroom-ai[all]==$HEADROOM_VERSION"
fi
# Durable deployment: launchd watchdog + ANTHROPIC_BASE_URL in shell profiles. Claude Code only.
headroom install status 2>/dev/null | grep -q "Healthy:    yes" \
  || headroom deploy --providers manual --target claude --no-telemetry

step "Custom skills → ~/.claude/skills"
# New skills are installed; changed ones are replaced only with --update-skills (old copy backed up).
mkdir -p "$HOME/.claude/skills"
for dir in "$REPO"/skills/*/; do
  s=$(basename "$dir"); dest="$HOME/.claude/skills/$s"
  if [ ! -d "$dest" ]; then
    cp -R "$dir" "$dest"; echo "installed $s"
  elif ! diff -rq --exclude .DS_Store "$dir" "$dest" >/dev/null; then
    if [ "${1:-}" = "--update-skills" ]; then
      mv "$dest" "$dest.bak-$(date +%Y%m%d%H%M%S)"; cp -R "$dir" "$dest"; echo "updated $s (backup kept)"
    else
      echo "$s differs from the repo copy — re-run with --update-skills to replace it"
    fi
  fi
done

step "Global defaults (~/.claude/CLAUDE.md, ~/.claude/settings.json)"
GLOBAL="$HOME/.claude/CLAUDE.md"
touch "$GLOBAL"
grep -q "task-observer" "$GLOBAL" || cat >> "$GLOBAL" <<'EOF'

At the start of every task-oriented session — before using tools to produce deliverables — invoke the `task-observer` skill.
EOF
# Replace the managed block (between the initial_setup markers) with the current template
python3 - "$GLOBAL" "$REPO/templates/global-CLAUDE.md" <<'EOF'
import re, sys
path, tpl = sys.argv[1], open(sys.argv[2]).read().strip()
s = open(path).read()
pat = re.compile(r'<!-- initial_setup:start.*?<!-- initial_setup:end -->', re.S)
s = pat.sub(lambda _: tpl, s) if pat.search(s) else s.rstrip() + "\n\n" + tpl + "\n"
open(path, "w").write(s)
EOF
# Default effort for every session
python3 - "$HOME/.claude/settings.json" <<'EOF'
import json, os, sys
p = sys.argv[1]
d = json.load(open(p)) if os.path.exists(p) else {}
d.setdefault("effortLevel", "xhigh")
json.dump(d, open(p, "w"), indent=2)
EOF

step "Status line (model, tokens, prompt cache, savings, repo, subagent models)"
# Sets ours unless you already have your own status line
python3 - "$HOME/.claude/settings.json" "$REPO/statusline" <<'EOF'
import json, os, sys
p, d = sys.argv[1], sys.argv[2]
s = json.load(open(p)) if os.path.exists(p) else {}
for key, script, extra in (("statusLine", "statusline.py", {"refreshInterval": 15}), ("subagentStatusLine", "subagent-statusline.py", {})):
    cur = s.get(key, {}).get("command", "")
    if not cur or "initial_setup" in cur or "statusline-debug" in cur:
        s[key] = {"type": "command", "command": f"python3 {d}/{script}", **extra}
    else:
        print(f"kept your own {key}: {cur}")
json.dump(s, open(p, "w"), indent=2)
EOF

step "initial-setup command"
mkdir -p "$HOME/.local/bin"
ln -sf "$REPO/setup.sh" "$HOME/.local/bin/initial-setup"
ln -sf "$REPO/scripts/diagrams-render.sh" "$HOME/.local/bin/diagram-render"
ln -sf "$REPO/scripts/diagrams-deps.sh" "$HOME/.local/bin/diagram-deps"
echo "Run 'initial-setup' inside any repo to set it up."
