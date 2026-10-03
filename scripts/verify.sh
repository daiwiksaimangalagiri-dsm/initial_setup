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

echo "Claude Code"
check "claude" claude --version
PLUGINS=$(claude plugin list 2>/dev/null)
for p in superpowers playwright context7 frontend-design figma claude-code-setup claude-mem headroom ponytail; do
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
  rm -rf "$TMP"
fi

echo
echo "Passed: $PASS  Failed: $FAIL  Warnings: $WARN"
[ "$FAIL" -eq 0 ]
