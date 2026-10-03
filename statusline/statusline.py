#!/usr/bin/env python3
"""Claude Code status line. Reads the session JSON on stdin, prints three lines.

  1  model · effort │ repo ⎇ branch │ PR │ vibe
  2  context bar │ tokens │ cost │ time │ lines changed
  3  prompt cache │ money saved │ models used │ rate limits

Stdlib only. Any segment that can't be computed is left out, never faked.
Self-check: python3 statusline.py --test
"""
import glob
import json
import os
import subprocess
import sys
import tempfile
import time
import urllib.request

# $ per million tokens: (input, cache read). From the claude-api skill, 2026-09-25.
# ponytail: hardcoded table, unknown models are skipped in "saved"; add rows when the team uses them.
PRICES = {
    "claude-opus-5-5": (4.00, 0.20),
    "claude-sonnet-5-5": (2.00, 0.20),
    "claude-haiku-4-5": (1.00, 0.10),
}
# Cache writes cost extra: 1.25x input for the 5-minute cache, 2x for the 1-hour cache
WRITE_5M, WRITE_1H = 1.25, 2.0

STATE_DIR = os.path.join(tempfile.gettempdir(), "claude-statusline")
HEADROOM_STATS = "http://127.0.0.1:8787/stats"

R = "\033[0m"
DIM = "\033[2m"
BOLD = "\033[1m"


def c(code, text):
    return f"\033[38;5;{code}m{text}{R}"


def short_num(n):
    for unit, size in (("B", 1e9), ("M", 1e6), ("k", 1e3)):
        if n >= size:
            return f"{n / size:.1f}".rstrip("0").rstrip(".") + unit
    return str(int(n))


def duration(ms):
    s = int(ms / 1000)
    h, m = divmod(s // 60, 60)
    return f"{h}h {m:02d}m" if h else f"{m}m {s % 60:02d}s"


def money(usd):
    return f"${usd:,.2f}" if usd < 100 else f"${usd:,.0f}"


def cached(key, ttl, fn):
    """Run fn() at most once per ttl seconds, sharing the result across status line refreshes."""
    path = os.path.join(STATE_DIR, f"{key}.json")
    try:
        if time.time() - os.path.getmtime(path) < ttl:
            with open(path) as f:
                return json.load(f)
    except (OSError, ValueError):
        pass  # no cache yet or unreadable: recompute below
    value = fn()
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(path, "w") as f:
        json.dump(value, f)
    return value


# ---------- transcripts: cumulative tokens, cache savings, model mix ----------

def _empty_totals():
    return {"in": 0, "read": 0, "write": 0, "out": 0, "saved": 0.0, "models": {}}


def scan_transcripts(session_id, transcript_path):
    """Sum usage over the main transcript and its subagent transcripts, reading only new lines."""
    files = [transcript_path] + sorted(glob.glob(os.path.join(transcript_path[:-6], "subagents", "*.jsonl")))
    state_path = os.path.join(STATE_DIR, f"session-{session_id}.json")
    try:
        with open(state_path) as f:
            state = json.load(f)
    except (OSError, ValueError):
        state = {"files": {}, "totals": _empty_totals()}
    t = state["totals"]

    for path in files:
        fs = state["files"].setdefault(path, {"offset": 0, "seen": []})
        try:
            with open(path, "rb") as f:
                f.seek(fs["offset"])
                chunk = f.read()
        except OSError:
            continue
        end = chunk.rfind(b"\n") + 1  # only whole lines; a half-written line waits for next time
        fs["offset"] += end
        for raw in chunk[:end].splitlines():
            try:
                msg = json.loads(raw).get("message") or {}
            except ValueError:
                continue
            usage, mid = msg.get("usage"), msg.get("id")
            if not usage or mid in fs["seen"]:
                continue  # one API response is split across several transcript lines
            fs["seen"] = (fs["seen"] + [mid])[-50:]
            model = msg.get("model", "?")
            read = usage.get("cache_read_input_tokens") or 0
            write = usage.get("cache_creation_input_tokens") or 0
            t["in"] += (usage.get("input_tokens") or 0) + read + write
            t["read"] += read
            t["write"] += write
            t["out"] += usage.get("output_tokens") or 0
            t["models"][model] = t["models"].get(model, 0) + 1
            if model in PRICES:
                p_in, p_read = PRICES[model]
                cc = usage.get("cache_creation") or {}
                w1h = cc.get("ephemeral_1h_input_tokens", 0)
                w5m = cc.get("ephemeral_5m_input_tokens", write - w1h)
                # Net saving: cheap reads, minus the premium paid to write the cache
                t["saved"] += (read * (p_in - p_read) - w1h * p_in * (WRITE_1H - 1) - w5m * p_in * (WRITE_5M - 1)) / 1e6

    os.makedirs(STATE_DIR, exist_ok=True)
    with open(state_path, "w") as f:
        json.dump(state, f)
    return t


# ---------- segments ----------

MODEL_ICON = {"opus": "🧠", "sonnet": "🎵", "haiku": "🐇", "fable": "🐉", "mythos": "🐉"}


def model_icon(name):
    return next((i for k, i in MODEL_ICON.items() if k in name.lower()), "🤖")


def git_info(cwd):
    def run():
        def g(*args):
            p = subprocess.run(["git", "-C", cwd, *args], capture_output=True, text=True, timeout=2)
            return p.stdout.strip() if p.returncode == 0 else ""
        top = g("rev-parse", "--show-toplevel")
        if not top:
            return {}
        return {
            "top": top,
            "branch": g("symbolic-ref", "--short", "HEAD") or g("rev-parse", "--short", "HEAD"),
            "dirty": len([l for l in g("status", "--porcelain").splitlines() if l]),
        }
    return cached("git-" + cwd.replace("/", "_"), 5, run)


def headroom_saved():
    def run():
        try:
            with urllib.request.urlopen(HEADROOM_STATS, timeout=0.3) as r:
                return json.load(r)["summary"]["cost"]["total_saved_usd"]
        except (OSError, ValueError, KeyError):
            return None  # proxy not running: no headroom segment
    return cached("headroom", 30, run)


def bar(pct, width=10):
    filled = round(pct / 100 * width)
    color = 114 if pct < 50 else 221 if pct < 75 else 209 if pct < 90 else 196
    return c(color, "▰" * filled) + c(240, "▱" * (width - filled))


def vibe(d, ctx_pct, cost):
    hour = time.localtime().tm_hour
    lines = d.get("cost", {}).get("total_lines_added", 0)
    if ctx_pct >= 90:
        return "💀 /compact era"
    if ctx_pct >= 75:
        return "🫠 context kinda full"
    if 1 <= hour < 5:
        return "🌙 goblin hours"
    if lines >= 500:
        return "🧑‍🍳 cooking fr"
    if cost >= 20:
        return "💸 big spender"
    if d.get("fast_mode"):
        return "🏎️ speedrun"
    if ctx_pct < 10:
        return "✨ fresh session"
    return "😎 vibin"


def render(d):
    sep = c(240, " │ ")
    model = d.get("model", {})
    name = model.get("display_name") or model.get("id", "?")
    cwd = d.get("workspace", {}).get("current_dir") or d.get("cwd") or os.getcwd()
    cost = d.get("cost", {})
    cw = d.get("context_window", {})
    ctx_pct = cw.get("used_percentage") or 0

    # Line 1: who and where
    head = f"{model_icon(name)} {BOLD}{name}{R}"
    effort = (d.get("effort") or {}).get("level")
    if effort:
        head += c(245, f" · {effort}")
    if d.get("fast_mode"):
        head += c(214, " ⚡fast")
    l1 = [head]
    repo = (d.get("workspace", {}).get("repo") or {}).get("name")
    g = git_info(cwd)
    where = f"📂 {c(117, repo or os.path.basename(g.get('top') or cwd))}"
    if g.get("branch"):
        where += c(183, f" ⎇ {g['branch']}") + (c(209, f" ●{g['dirty']}") if g["dirty"] else c(114, " ✓"))
    wt = (d.get("worktree") or {}).get("name") or d.get("workspace", {}).get("git_worktree")
    if wt:
        where += c(180, f" 🌳 {wt}")
    l1.append(where)
    pr = d.get("pr") or {}
    if pr.get("number"):
        state = {"approved": "✅", "changes_requested": "🔧", "draft": "📝", "pending": "👀"}.get(pr.get("review_state"), "")
        l1.append(f"🔗 PR #{pr['number']} {state}".rstrip())
    if d.get("session_name"):
        l1.append(c(245, f"💬 {d['session_name'][:32].rstrip()}"))
    l1.append(vibe(d, ctx_pct, cost.get("total_cost_usd", 0)))

    # Line 2: how much
    size = cw.get("context_window_size") or 0
    l2 = [f"{bar(ctx_pct)} {ctx_pct}%" + (c(245, f" of {short_num(size)}") if size else "")]
    tp, sid = d.get("transcript_path"), d.get("session_id")
    t = scan_transcripts(sid, tp) if tp and sid and os.path.exists(tp) else None
    if t and t["in"]:
        l2.append(f"🪙 {short_num(t['in'])} in · {short_num(t['out'])} out")
    if "total_cost_usd" in cost:
        l2.append(f"💸 {money(cost['total_cost_usd'])}")
    if cost.get("total_duration_ms"):
        l2.append(f"⏱️ {duration(cost['total_duration_ms'])}" + c(245, f" (api {duration(cost.get('total_api_duration_ms', 0))})"))
    added, removed = cost.get("total_lines_added", 0), cost.get("total_lines_removed", 0)
    if added or removed:
        l2.append(c(114, f"+{added}") + " " + c(203, f"−{removed}"))

    # Line 3: cache, savings, models, limits
    l3 = []
    pc = d.get("prompt_cache") or {}
    if pc.get("caching_observed"):
        hit = round((pc.get("hit_ratio") or 0) * 100)
        seg = f"🧊 cache {c(114 if hit >= 80 else 221 if hit >= 50 else 203, f'{hit}%')} hit"
        left = (pc.get("expires_at") or 0) - time.time()
        if pc.get("warm") and left > 0:
            seg += c(209, f" 🔥 warm {int(left // 60)}m left")
        else:
            seg += c(117, " 🥶 cold")
        if pc.get("misses"):
            cause = ((pc.get("last_miss_cause") or {}).get("causes") or [""])[0].replace("_", " ")
            seg += c(245, f" · {pc['misses']} miss" + ("es" if pc["misses"] > 1 else "") + (f" ({cause})" if cause else ""))
        l3.append(seg)
    elif pc:
        l3.append(c(203, "🧊 cache off"))
    saved = []
    if t and t["saved"] > 0.005:
        saved.append(f"{money(t['saved'])} cache")
    hr = headroom_saved()
    if hr:
        saved.append(f"{money(hr)} headroom")
    if saved:
        l3.append("💰 saved " + c(114, " + ".join(saved)))
    if t and t["models"]:
        mix = sorted(t["models"].items(), key=lambda kv: -kv[1])
        l3.append(" ".join(f"{model_icon(m)}×{n}" for m, n in mix[:4]))
    rl = d.get("rate_limits") or {}
    limits = [f"{k} {round(rl[w]['used_percentage'])}%" for k, w in (("5h", "five_hour"), ("7d", "seven_day")) if rl.get(w)]
    if limits:
        l3.append("🔋 " + " · ".join(limits))

    return "\n".join(sep.join(x) for x in (l1, l2, l3) if x)


def _test():
    tmp = tempfile.mkdtemp()
    tp = os.path.join(tmp, "s.jsonl")
    line = {"message": {"id": "m1", "model": "claude-opus-5-5", "usage": {
        "input_tokens": 10, "cache_read_input_tokens": 1_000_000, "cache_creation_input_tokens": 0, "output_tokens": 500}}}
    with open(tp, "w") as f:
        f.write(json.dumps(line) + "\n" + json.dumps(line) + "\n")  # duplicate line = same response
    d = {"session_id": "test-" + str(os.getpid()), "transcript_path": tp, "cwd": tmp,
         "model": {"id": "claude-opus-5-5", "display_name": "Opus 5.5"}, "effort": {"level": "xhigh"},
         "cost": {"total_cost_usd": 1.5, "total_duration_ms": 3_723_000, "total_api_duration_ms": 60_000,
                  "total_lines_added": 12, "total_lines_removed": 3},
         "context_window": {"used_percentage": 42, "context_window_size": 1_000_000},
         "prompt_cache": {"caching_observed": True, "warm": True, "hit_ratio": 0.92, "expires_at": time.time() + 600, "misses": 0}}
    out = render(d)
    assert "Opus 5.5" in out and "xhigh" in out, out
    assert "42%" in out and "1h 02m" in out and "cache" in out and "92%" in out, out
    assert "$3.80 cache" in out, out  # 1M reads × ($4.00 − $0.20) / 1M, counted once despite the duplicate line
    assert "🧠×1" in out, out
    with open(tp, "a") as f:
        f.write(json.dumps({**line, "message": {**line["message"], "id": "m2"}}) + "\n")
    assert "$7.60 cache" in render(d), "incremental scan should add only the new response"
    assert render({}) , "empty input must still render"
    print(out)
    print("statusline self-check passed")


if __name__ == "__main__":
    if sys.argv[1:] == ["--test"]:
        _test()
    else:
        print(render(json.load(sys.stdin)))
