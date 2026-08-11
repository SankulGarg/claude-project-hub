#!/usr/bin/env bash
# Create a new project as a subdirectory of the master.
#
#   new-project.sh <name> [--git]
#
# The master is $PWD (or $HUB_ROOT). Creates <master>/<name>/. Memory is NOT
# seeded here — it is created at the canonical path on first write, consistent
# with the rest of the hub. Prints the resolved workdir + memory path.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=hub-lib.sh
. "$DIR/hub-lib.sh"

name="${1:-}"
do_git=0
for a in "${@:2}"; do
  case "$a" in
    --git) do_git=1;;
    *) echo "unknown option: $a" >&2; exit 2;;
  esac
done

if [ -z "$name" ]; then
  echo "usage: new-project.sh <name> [--git]" >&2
  exit 2
fi

# Reject anything that isn't a single, safe directory name.
case "$name" in
  */*|.|..|.*)         echo "ERROR: '$name' is not a valid project name (no slashes, no leading dot)." >&2; exit 2;;
  scripts|commands|node_modules) echo "ERROR: '$name' is reserved." >&2; exit 2;;
esac

workdir="$CODE_ROOT/$name"
mem="$(mem_of "$name")"

if [ -e "$workdir" ]; then
  echo "ERROR: $workdir already exists — refusing to overwrite." >&2
  exit 1
fi

mkdir -p "$workdir"

if [ "$do_git" -eq 1 ]; then
  git -C "$workdir" init -q && echo "git   : initialized empty repo"
fi

echo "created project: $name"
echo "  workdir: $workdir"
echo "  memory : $mem"
echo "  status : no memory yet (created on first write by an agent or a direct session)"
