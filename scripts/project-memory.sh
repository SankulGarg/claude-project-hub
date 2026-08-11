#!/usr/bin/env bash
# Resolve project -> canonical Claude memory path, or list all projects.
#
#   project-memory.sh              # list every project (subdir) + history/memory status
#   project-memory.sh <name>...    # resolve one or more projects to workdir + memory
#
# Moves/copies nothing. The master is $PWD (or $HUB_ROOT). Memory path is derived
# from the launch dir so it matches a direct `claude` session in that folder.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=hub-lib.sh
. "$DIR/hub-lib.sh"

if [ "$#" -eq 0 ]; then
  printf '%-34s %-9s %-7s\n' "PROJECT" "SESSIONS" "MEMORY"
  printf '%-34s %-9s %-7s\n' "-------" "--------" "------"
  for d in "$CODE_ROOT"/*/; do
    name="$(basename "$d")"
    case "$name" in scripts|node_modules|.*) continue;; esac
    sess_dir="$CLI_ROOT/$(slug_of "$name")"
    n="$(find "$sess_dir" -maxdepth 1 -name '*.jsonl' 2>/dev/null | wc -l | tr -d ' ')"
    if [ -d "$sess_dir/memory" ] && [ -n "$(ls -A "$sess_dir/memory" 2>/dev/null)" ]; then m="yes"; else m="-"; fi
    printf '%-34s %-9s %-7s\n' "$name" "$n" "$m"
  done
  exit 0
fi

for name in "$@"; do
  workdir="$CODE_ROOT/$name"
  mem="$(mem_of "$name")"
  if [ ! -d "$workdir" ]; then
    echo "WARN: $name has no working dir at $workdir (memory path still valid on first write)"
  fi
  echo "project : $name"
  echo "  workdir: $workdir"
  echo "  memory : $mem"
  if [ -f "$mem/MEMORY.md" ]; then echo "  status : has memory"; else echo "  status : no memory yet (created on first write)"; fi
done
