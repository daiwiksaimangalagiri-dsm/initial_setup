#!/usr/bin/env bash
# Verify every tool, plugin, skill, MCP server and session default in docs/intitial_setup.md.
#   ./scripts/verify.sh [--smoke] [project-dir]
#   --smoke       also drive real browsers (Chrome via CLI, Chromium via library)
#   project-dir   also check that repo's setup (CLAUDE.md, .mcp.json, ruflo, .gitignore)
set -u

SMOKE=; PROJECT=
for a in "$@"; do case $a in --smoke) SMOKE=1;; *) PROJECT=$a;; esac; done
REPO=$(cd "$(dirname "$0")/.." && pwd)
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"

PASS=0; FAIL=0; WARN=0
ok()   { printf '  \033[32m✔\033[0m %-30s %s\n' "$1" "$2"; PASS=$((PASS+1)); }
bad()  { printf '  \033[31m✘\033[0m %-30s %s\n' "$1" "$2"; FAIL=$((FAIL+1)); }
warn() { printf '  \033[33m!\033[0m %-30s %s\n' "$1" "$2"; WARN=$((WARN+1)); }

# check <label> <command...>: passes if the command succeeds, prints its first output line
check() {
  local label=$1; shift
  local out
  if out=$("$@" 2>/dev/null | head -1) && [ -n "$out" ]; then ok "$label" "$out"; else bad "$label" "not found"; fi
}

[ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh" >/dev/null 2>&1

echo "System"
ok "macOS" "$(sw_vers -productVersion) ($(uname -m))"
check "git" git --version
check "Xcode CLT" xcode-select -p

echo "Runtimes"
check "nvm" nvm --version
check "node" node -v
check "npm" npm -v
check "bun" bun --version
check "uv" uv --version

echo "Browsers"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if [ -x "$CHROME" ]; then ok "Google Chrome" "$("$CHROME" --version)"; else bad "Google Chrome" "not in /Applications"; fi
if ls "$HOME/Library/Caches/ms-playwright" 2>/dev/null | grep -q '^chromium-'; then
  ok "Playwright Chromium" "$(ls "$HOME/Library/Caches/ms-playwright" | grep '^chromium-' | tr '\n' ' ')"
else bad "Playwright Chromium" "run: playwright install chromium"; fi

echo "CLI tools"
check "playwright" playwright --version
check "playwright-mcp" playwright-mcp --version
check "playwright-cli" playwright-cli --version
check "ruflo" ruflo --version
check "openspec" openspec --version
check "headroom" headroom --version
check "gh" gh --version
if gh auth status >/dev/null 2>&1; then ok "gh auth" "signed in"; else warn "gh auth" "run: gh auth login --git-protocol https --web"; fi
git config --global --get-all credential.https://github.com.helper 2>/dev/null | grep -q "gh auth git-credential" && ok "git → gh credentials" "git push uses gh sign-in" || warn "git → gh credentials" "run: gh auth setup-git (after gh auth login)"

echo "Diagram tools"
check "mermaid-cli (mmdc)" mmdc --version
check "likec4" likec4 --version
check "dependency-cruiser" depcruise --version
check "graphviz (wasm)" wasm-graphviz-cli --version
check "tach" tach --version
TSV=$(node -p "require('$(npm root -g)/typescript/package.json').version" 2>/dev/null)
case $TSV in 5.*) ok "typescript (global)" "$TSV, works with dependency-cruiser";; "") bad "typescript (global)" "missing";; *) bad "typescript (global)" "$TSV: dependency-cruiser needs < 7";; esac
DRAWIO=/Applications/draw.io.app/Contents/MacOS/draw.io
[ -x "$DRAWIO" ] && ok "draw.io desktop" "$("$DRAWIO" --version 2>/dev/null | tail -1)" || bad "draw.io desktop" "not in /Applications"
for c in diagram-render diagram-deps; do command -v $c >/dev/null && ok "command: $c" "on PATH" || bad "command: $c" "missing — run install.sh"; done

echo "Claude Code"
check "claude" claude --version
PLUGINS=$(claude plugin list 2>/dev/null)
for p in superpowers playwright context7 frontend-design figma claude-code-setup claude-mem headroom ponytail drawio; do
  if echo "$PLUGINS" | grep -A3 "❯ $p@" | grep -q "enabled"; then ok "plugin: $p" "enabled"; else bad "plugin: $p" "missing or disabled"; fi
done
MCPS=$(claude mcp list 2>/dev/null)
for m in ruflo github; do
  if echo "$MCPS" | grep -q "^$m:.*Connected"; then ok "MCP (user): $m" "connected"; else bad "MCP (user): $m" "not connected"; fi
done

echo "Skills (from skills/)"
for dir in "$REPO"/skills/*/; do
  s=$(basename "$dir")
  if [ ! -f "$HOME/.claude/skills/$s/SKILL.md" ]; then bad "skill: $s" "not installed — run install.sh"
  elif ! diff -rq --exclude .DS_Store "$dir" "$HOME/.claude/skills/$s" >/dev/null; then warn "skill: $s" "differs from repo — sync-skills.sh or install.sh --update-skills"
  else ok "skill: $s" "installed, matches repo"; fi
  grep -q "\`$s\`" "$REPO/docs/skills.md" || bad "docs: $s" "no entry in docs/skills.md"
done

echo "Session defaults"
GLOBAL="$HOME/.claude/CLAUDE.md"
grep -q "task-observer" "$GLOBAL" 2>/dev/null && ok "global: task-observer" "activated" || bad "global: task-observer" "line missing"
grep -q "initial_setup:start" "$GLOBAL" 2>/dev/null && ok "global: team defaults" "stop-slop, secure coding, model/effort" || bad "global: team defaults" "block missing — run install.sh"
EFFORT=$(python3 -c "import json;print(json.load(open('$HOME/.claude/settings.json')).get('effortLevel',''))" 2>/dev/null)
[ -n "$EFFORT" ] && ok "effortLevel" "$EFFORT" || bad "effortLevel" "not set"
if curl -sf -m 3 http://127.0.0.1:8787/readyz >/dev/null; then ok "headroom proxy" "healthy on :8787"; else bad "headroom proxy" "down — run: headroom deploy"; fi
grep -q 'ANTHROPIC_BASE_URL="http://127.0.0.1:8787"' "$HOME/.zshrc" 2>/dev/null && ok "headroom shell env" "ANTHROPIC_BASE_URL in ~/.zshrc" || bad "headroom shell env" "missing"
PORT=$(python3 -c "import json;print(json.load(open('$HOME/.claude-mem/settings.json')).get('CLAUDE_MEM_WORKER_PORT','37777'))" 2>/dev/null || echo 37777)
if curl -sf -m 3 "http://127.0.0.1:$PORT/health" >/dev/null; then ok "claude-mem worker" "healthy on :$PORT"; else warn "claude-mem worker" "not running (starts with the next session)"; fi

python3 "$REPO/statusline/statusline.py" --test >/dev/null 2>&1 && ok "status line" "self-check passed" || bad "status line" "self-check failed: python3 statusline/statusline.py --test"
python3 "$REPO/statusline/subagent-statusline.py" --test >/dev/null 2>&1 && ok "subagent status line" "self-check passed" || bad "subagent status line" "self-check failed"
python3 "$REPO/hooks/commit-msg" --test >/dev/null 2>&1 && ok "commit-msg hook" "self-check passed" || bad "commit-msg hook" "self-check failed: python3 hooks/commit-msg --test"
SL=$(python3 -c "import json;print(json.load(open('$HOME/.claude/settings.json')).get('statusLine',{}).get('command',''))" 2>/dev/null)
case "$SL" in *initial_setup/statusline*) ok "statusLine setting" "ours";; "") bad "statusLine setting" "not set — run install.sh";; *) warn "statusLine setting" "your own: $SL";; esac

echo "Session-start hooks (run each one like Claude Code does)"
HOOKS=$(python3 - <<'PY'
import json, os, subprocess, glob
home = os.path.expanduser("~")
enabled = json.load(open(f"{home}/.claude/settings.json")).get("enabledPlugins", {})
inp = json.dumps({"session_id": "verify", "hook_event_name": "SessionStart", "source": "startup", "cwd": os.getcwd()})
for pid, on in enabled.items():
    if not on: continue
    name, mkt = pid.split("@")
    vers = sorted(glob.glob(f"{home}/.claude/plugins/cache/{mkt}/{name}/*/"), key=os.path.getmtime)
    if not vers: continue
    root = vers[-1].rstrip("/")
    manifest = os.path.join(root, ".claude-plugin/plugin.json")
    hp = json.load(open(manifest)).get("hooks") if os.path.exists(manifest) else None
    hp = os.path.join(root, hp) if isinstance(hp, str) else os.path.join(root, "hooks/hooks.json")
    if not os.path.exists(hp): continue
    for m in json.load(open(hp)).get("hooks", {}).get("SessionStart", []):
        for h in m["hooks"]:
            try:
                p = subprocess.run(["bash", "-c", h["command"]], input=inp, capture_output=True, text=True,
                                   timeout=h.get("timeout", 60), env=dict(os.environ, CLAUDE_PLUGIN_ROOT=root))
                ok, msg = p.returncode == 0, (p.stderr.strip().splitlines() or ["exit %d" % p.returncode])[0][:70]
            except subprocess.TimeoutExpired:
                ok, msg = False, "timed out"
            print(("PASS" if ok else "FAIL") + "\t" + name + "\t" + ("ok" if ok else msg))
PY
)
while IFS=$'\t' read -r st name msg; do
  [ -z "$st" ] && continue
  if [ "$st" = PASS ]; then ok "hook: $name" "SessionStart ok"; else bad "hook: $name" "$msg"; fi
done <<< "$HOOKS"

if [ -n "$PROJECT" ]; then
  P=$(cd "$PROJECT" 2>/dev/null && pwd)
  echo "Project: ${P:-$PROJECT}"
  if [ "$P" = "$REPO" ]; then ok "project" "initial_setup repo itself, skipped"
  elif [ -z "$P" ]; then bad "project" "not found"
  else
    [ -d "$P/.git" ] && ok "git repo" "yes" || bad "git repo" "no .git"
    [ -f "$P/CLAUDE.md" ] && ok "CLAUDE.md" "present" || bad "CLAUDE.md" "missing"
    grep -q '"playwright-chrome"' "$P/.mcp.json" 2>/dev/null && ok ".mcp.json" "playwright-chrome" || bad ".mcp.json" "playwright-chrome missing"
    [ -f "$P/openspec/config.yaml" ] && ok "openspec" "initialized" || bad "openspec" "not initialized"
    [ -f "$P/.claude/commands/opsx/propose.md" ] && ok "openspec commands" "/opsx:* installed" || bad "openspec commands" "missing — run initial-setup"
    grep -q "## Specs (OpenSpec)" "$P/CLAUDE.md" 2>/dev/null && ok "CLAUDE.md: OpenSpec rule" "present" || bad "CLAUDE.md: OpenSpec rule" "missing — run initial-setup"
    grep -q "## Commits (Conventional Commits)" "$P/CLAUDE.md" 2>/dev/null && ok "CLAUDE.md: commits rule" "present" || bad "CLAUDE.md: commits rule" "missing — run initial-setup"
    grep -q "## Diagrams" "$P/CLAUDE.md" 2>/dev/null && ok "CLAUDE.md: diagrams rule" "present" || bad "CLAUDE.md: diagrams rule" "missing — run initial-setup"
    HK=$(git -C "$P" rev-parse --git-path hooks 2>/dev/null); case $HK in /*) ;; *) HK=$P/$HK;; esac
    if [ ! -f "$HK/commit-msg" ]; then bad "commit-msg hook" "missing — run initial-setup"
    elif grep -q "initial_setup commit-msg hook" "$HK/commit-msg"; then
      cmp -s "$REPO/hooks/commit-msg" "$HK/commit-msg" && ok "commit-msg hook" "Conventional Commits enforced" || bad "commit-msg hook" "outdated — run initial-setup"
    else warn "commit-msg hook" "your own hook is there, Conventional Commits not enforced"; fi
    [ -d "$P/.claude-flow" ] && ok "ruflo" "initialized" || bad "ruflo" "not initialized"
    if grep -q '"model"' "$P/.claude/settings.json" 2>/dev/null; then warn "project model pin" ".claude/settings.json overrides your model"; else ok "project model pin" "none (uses your default)"; fi
    grep -qxF ".playwright-mcp/" "$P/.gitignore" 2>/dev/null && ok ".gitignore" "Playwright output ignored" || bad ".gitignore" "Playwright output not ignored"
  fi
fi

if [ -n "$SMOKE" ]; then
  echo "Smoke tests"
  TMP=$(mktemp -d)
  # Playwright CLI driving real Google Chrome
  if (cd "$TMP" && playwright-cli open https://example.com --browser chrome >/dev/null 2>&1 \
      && playwright-cli eval "navigator.userAgent" 2>/dev/null | grep -q Chrome/ \
      && playwright-cli close >/dev/null 2>&1); then
    ok "CLI → Google Chrome" "opened example.com"
  else bad "CLI → Google Chrome" "failed"; fi
  # Playwright library driving bundled Chromium
  PW="$(npm root -g)/playwright/index.mjs"
  cat > "$TMP/t.mjs" <<EOF
import { chromium } from '$PW';
const b = await chromium.launch(); const p = await b.newPage();
await p.goto('https://example.com'); await p.click('a'); await p.waitForLoadState();
console.log(b.version() + ' → ' + p.url()); await b.close();
EOF
  if out=$(node "$TMP/t.mjs" 2>&1); then ok "Library → Chromium" "$out"; else bad "Library → Chromium" "$out"; fi
  # Diagrams: render Mermaid, render DOT, validate a LikeC4 model, graph a tiny TS project
  printf 'sequenceDiagram\n  A->>B: hello\n' > "$TMP/c.mmd"
  if diagram-render "$TMP/c.mmd" >/dev/null 2>&1 && [ -s "$TMP/c.png" ]; then ok "Mermaid → PNG" "rendered with Chrome"; else bad "Mermaid → PNG" "diagram-render failed"; fi
  printf 'digraph{a->b}' > "$TMP/c.dot"
  if wasm-graphviz-cli -K dot -T svg "$TMP/c.dot" 2>/dev/null | grep -q "<svg"; then ok "DOT → SVG" "Graphviz WASM"; else bad "DOT → SVG" "failed"; fi
  mkdir -p "$TMP/c4" && printf 'specification {\n  element system\n}\nmodel {\n  a = system "A"\n  b = system "B"\n  a -> b\n}\nviews {\n  view index {\n    include *\n  }\n}\n' > "$TMP/c4/m.c4"
  if (cd "$TMP/c4" && likec4 validate >/dev/null 2>&1); then ok "LikeC4 validate" "model ok"; else bad "LikeC4 validate" "failed"; fi
  mkdir -p "$TMP/ts/src/a" "$TMP/ts/src/b" && echo 'export const x = 1;' > "$TMP/ts/src/b/x.ts" && echo 'import { x } from "../b/x"; export const y = x;' > "$TMP/ts/src/a/y.ts" && echo '{}' > "$TMP/ts/package.json"
  if (cd "$TMP/ts" && diagram-deps >/dev/null 2>&1 && grep -q -- "-->" docs/diagrams/dependencies.mmd); then ok "diagram-deps (TS)" "dependency found"; else bad "diagram-deps (TS)" "empty graph"; fi
  rm -rf "$TMP"
fi

echo
echo "Passed: $PASS  Failed: $FAIL  Warnings: $WARN"
[ "$FAIL" -eq 0 ]
