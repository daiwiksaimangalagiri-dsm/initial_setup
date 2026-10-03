#!/usr/bin/env python3
"""Claude Code subagent rows: which model and effort each agent runs on, its tokens and run time.
Prints one JSON line per agent: {"id": ..., "content": ...}. Self-check: --test
"""
import json
import sys
import time

ICON = {"opus": "🧠", "sonnet": "🎵", "haiku": "🐇", "fable": "🐉", "mythos": "🐉"}
STATUS = {"running": "⏳", "completed": "✅", "failed": "❌", "killed": "🛑"}


def short_model(mid):
    # claude-haiku-4-5 -> haiku 4.5
    parts = (mid or "?").replace("claude-", "").split("-")
    return parts[0] + (" " + ".".join(parts[1:3]) if len(parts) > 1 else "")


def row(t, now_ms):
    model = t.get("model") or ""
    icon = next((i for k, i in ICON.items() if k in model), "🤖")
    bits = [f"{STATUS.get(t.get('status'), '•')} {t.get('description') or t.get('name') or 'agent'}",
            f"{icon} {short_model(model)}" + (f" · {t['effort']}" if t.get("effort") else "")]
    tokens, size = t.get("tokenCount") or 0, t.get("contextWindowSize")
    if tokens:
        bits.append(f"{tokens / 1000:.0f}k tok" + (f" ({tokens * 100 // size}%)" if size else ""))
    if t.get("startTime") is not None:
        s = int((now_ms - t["startTime"]) / 1000)
        bits.append(f"⏱️ {s // 60}:{s % 60:02d}")
    if t.get("label"):
        bits.append(f"\033[2m{t['label']}\033[0m")
    return " │ ".join(bits)


def main(d, now_ms):
    return "\n".join(json.dumps({"id": t["id"], "content": row(t, now_ms)}, ensure_ascii=False) for t in d.get("tasks", []))


if __name__ == "__main__":
    if sys.argv[1:] == ["--test"]:
        r = main({"tasks": [{"id": "a1", "status": "running", "description": "Search docs", "model": "claude-haiku-4-5",
                             "effort": "low", "tokenCount": 50_000, "contextWindowSize": 200_000, "startTime": 0}]}, 75_000)
        assert '"id": "a1"' in r and "haiku 4.5 · low" in r and "50k tok (25%)" in r and "1:15" in r, r
        print(r)
        print("subagent statusline self-check passed")
    else:
        print(main(json.load(sys.stdin), time.time() * 1000))
