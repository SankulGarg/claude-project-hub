#!/usr/bin/env bash
# List every project (subdir of the master) that has prior Claude CLI history,
# with session counts and the canonical memory path. Moves/copies nothing.
#
# The master is $PWD (or $HUB_ROOT). Memory paths are derived from the launch dir.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/hub-lib.sh"

echo "Master: $CODE_ROOT"
echo "Projects with prior Claude history:"
echo

found=0
for d in "$CODE_ROOT"/*/; do
  name="$(basename "$d")"
  case "$name" in scripts|node_modules|.*) continue;; esac
  sess_dir="$CLI_ROOT/$(slug_of "$name")"
  n="$(find "$sess_dir" -maxdepth 1 -name '*.jsonl' 2>/dev/null | wc -l | tr -d ' ')"
  [ "$n" -eq 0 ] && continue
  found=$((found+1))
  if [ -d "$sess_dir/memory" ] && [ -n "$(ls -A "$sess_dir/memory" 2>/dev/null)" ]; then mem="memory: yes"; else mem="memory: none yet"; fi
  echo "- $name — $n session(s); $mem"
  echo "    memory: $sess_dir/memory"
done

if [ "$found" -eq 0 ]; then echo "(none yet — every subdir is a fresh project)"; fi
