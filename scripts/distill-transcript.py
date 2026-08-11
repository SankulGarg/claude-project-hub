#!/usr/bin/env python3
"""Extract a compact conversational digest from a Claude CLI .jsonl transcript.

Keeps user prompts and assistant natural-language text. Drops tool_use inputs and
tool_result payloads (the bulk), keeping only short markers so context is preserved
without the noise. Truncates any single block so one giant paste can't dominate.

Usage: distill-transcript.py <transcript.jsonl> [max_chars_per_block]
Prints the digest to stdout.
"""
import sys, json

MAXB = int(sys.argv[2]) if len(sys.argv) > 2 else 2000


def text_from_content(content):
    """content may be a string or a list of blocks."""
    out = []
    if isinstance(content, str):
        return content.strip()
    if isinstance(content, list):
        for b in content:
            if not isinstance(b, dict):
                continue
            t = b.get("type")
            if t == "text":
                out.append(b.get("text", "").strip())
            elif t == "thinking":
                pass  # skip reasoning
            elif t == "tool_use":
                name = b.get("name", "tool")
                out.append(f"[tool: {name}]")
            elif t == "tool_result":
                pass  # drop bulky results
    return "\n".join(x for x in out if x).strip()


def main():
    path = sys.argv[1]
    for line in open(path, encoding="utf-8", errors="replace"):
        line = line.strip()
        if not line:
            continue
        try:
            o = json.loads(line)
        except Exception:
            continue
        m = o.get("message")
        if not isinstance(m, dict):
            continue
        role = m.get("role")
        if role not in ("user", "assistant"):
            continue
        txt = text_from_content(m.get("content"))
        if not txt:
            continue
        # skip tool-only assistant turns and pure tool-result user turns
        if txt.startswith("[tool:") and txt.count("\n") == 0:
            continue
        if len(txt) > MAXB:
            txt = txt[:MAXB] + " …[truncated]"
        print(f"### {role.upper()}\n{txt}\n")


if __name__ == "__main__":
    main()
