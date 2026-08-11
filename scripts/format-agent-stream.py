#!/usr/bin/env python3
"""Follow a spawned-agent .output JSONL file and print it as readable activity.

Runs in a SEPARATE terminal tab (not inside Claude), so it can safely tail the
full transcript that Claude itself must not read into context.

Usage: format-agent-stream.py <path-to-agent.output> [label]
Waits for the file to appear, then follows it like `tail -f`.
"""
import sys, os, json, time

path = sys.argv[1]
label = sys.argv[2] if len(sys.argv) > 2 else os.path.basename(path)

C = {"user": "\033[36m", "assistant": "\033[32m", "tool": "\033[33m",
     "dim": "\033[2m", "reset": "\033[0m", "bold": "\033[1m"}


def show(role, text):
    text = text.strip()
    if not text:
        return
    color = C.get(role, "")
    print(f"{color}{C['bold']}{role.upper()}{C['reset']}{color} {text}{C['reset']}\n")


def render(content):
    if isinstance(content, str):
        return content.strip()
    out = []
    if isinstance(content, list):
        for b in content:
            if not isinstance(b, dict):
                continue
            t = b.get("type")
            if t == "text":
                out.append(b.get("text", "").strip())
            elif t == "thinking":
                out.append(f"{C['dim']}(thinking…){C['reset']}")
            elif t == "tool_use":
                name = b.get("name", "tool")
                inp = b.get("input", {})
                hint = ""
                for k in ("command", "file_path", "path", "pattern", "prompt", "description"):
                    if isinstance(inp, dict) and inp.get(k):
                        hint = str(inp[k]).replace("\n", " ")[:120]
                        break
                out.append(f"{C['tool']}▶ {name}{C['reset']} {C['dim']}{hint}{C['reset']}")
            elif t == "tool_result":
                out.append(f"{C['dim']}  ↳ (tool result received){C['reset']}")
    return "\n".join(x for x in out if x).strip()


print(f"{C['bold']}=== watching agent: {label} ==={C['reset']}")
print(f"{C['dim']}{path}{C['reset']}\n")

# wait for the file to be created
for _ in range(600):  # up to ~60s
    if os.path.exists(path):
        break
    time.sleep(0.1)
else:
    print(f"{C['dim']}(file never appeared — agent may not have started){C['reset']}")
    sys.exit(0)

with open(path, "r", encoding="utf-8", errors="replace") as f:
    while True:
        line = f.readline()
        if not line:
            time.sleep(0.4)
            continue
        line = line.strip()
        if not line:
            continue
        try:
            o = json.loads(line)
        except Exception:
            continue
        m = o.get("message")
        if not isinstance(m, dict):
            # surface completion/status records
            if o.get("type") in ("result", "status") and o.get("status"):
                print(f"{C['bold']}[{o.get('status')}]{C['reset']}\n")
            continue
        role = m.get("role")
        if role not in ("user", "assistant"):
            continue
        txt = render(m.get("content"))
        show(role if role == "assistant" else "tool" if txt.startswith(C["dim"]) else "user", txt)
