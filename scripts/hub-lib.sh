#!/usr/bin/env bash
# Shared helpers for the project-hub plugin. Source this; don't execute it.
#
# The master is whatever directory Claude was launched in ($PWD), unless
# HUB_ROOT overrides it. Every project is a subdirectory of the master.
#
# Memory lives at Claude Code's own per-directory store, so a delegated agent
# and a *direct* `claude` session in the same folder resolve to the SAME path
# and share/auto-resume memory. That path is derived — never hardcoded:
#
#   ~/.claude/projects/<slug>/memory      where
#   slug = the absolute path with every non-alphanumeric char replaced by '-'
#
# Verified empirically: a username of "sankul.garg" slugs to "sankul-garg"
# (the dot becomes '-'), so we must replace '.' too — not just '/'.

CODE_ROOT="${HUB_ROOT:-$PWD}"
CLI_ROOT="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"

# dashify <absolute-path> -> claude slug
dashify() { printf '%s' "$1" | sed 's/[^A-Za-z0-9]/-/g'; }

# slug_of <project-name> -> slug for <master>/<project-name>
slug_of() { dashify "$CODE_ROOT/$1"; }

# mem_of <project-name> -> canonical memory dir for that project
mem_of() { echo "$CLI_ROOT/$(slug_of "$1")/memory"; }

# master_mem -> the master's own memory dir (for cross-project notes)
master_mem() { echo "$CLI_ROOT/$(dashify "$CODE_ROOT")/memory"; }
