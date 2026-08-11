#!/usr/bin/env bash
# Open a Warp tab that live-streams a spawned agent's activity.
#
#   watch-agent.sh <output-file> <label>
#
# Writes a one-shot Warp launch configuration and fires the warp:// URI so a new
# tab opens running the formatter against that agent's file. The formatter runs
# in that separate tab, never inside Claude's own context.
#
# Portable: formatter path and cwd are derived at runtime, nothing hardcoded.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/hub-lib.sh"

OUT="${1:-}"
LABEL="${2:-agent}"
FMT="$DIR/format-agent-stream.py"
LC_DIR="$HOME/.warp/launch_configurations"

if [ -z "$OUT" ]; then
  echo "usage: watch-agent.sh <output-file> <label>" >&2
  exit 1
fi

# sanitize label -> safe config name (Warp launch names + filenames)
safe="$(printf '%s' "$LABEL" | tr -c 'A-Za-z0-9._-' '-' | sed 's/-\{2,\}/-/g; s/^-//; s/-$//')"
[ -z "$safe" ] && safe="agent"
name="watch-${safe}"

mkdir -p "$LC_DIR"
cat > "$LC_DIR/$name.yaml" <<EOF
---
name: $name
windows:
  - tabs:
      - title: "▶ $LABEL"
        layout:
          cwd: $CODE_ROOT
          commands:
            - exec: python3 "$FMT" "$OUT" "$LABEL"
EOF

open "warp://launch/$name"
echo "opened Warp watcher tab for: $LABEL"
