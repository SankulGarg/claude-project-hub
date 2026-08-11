# project-hub

A Claude Code plugin that turns **whatever directory you launch Claude in** into a
master orchestration hub over its project subdirectories. Install it once; it works
from any directory on any machine — nothing is hardcoded to a path or username.

## What it does

- **`/projects`** — lists every subdirectory as a project, showing which already have
  Claude memory and how many past sessions each has.
- **`/projects <name>`** — spawns a `general-purpose` subagent scoped to that project:
  it reads the project's existing memory first, does the task in the project's own
  working directory, and writes durable findings back to that project's memory.
- **`/projects <name> <name2>`** — one subagent with read access to **both** projects'
  memory (writes each finding back to the project it belongs to; cross-project notes
  go to the master's own memory).
- Every spawned agent runs in the background and **auto-opens a Warp tab** that
  live-streams its activity (tool calls, messages) via a formatter running in that
  separate tab — so watching the agent never pollutes the main session's context.

## Why memory "just works"

Claude Code stores per-directory memory at
`~/.claude/projects/<slug>/memory/`, where `<slug>` is the absolute launch path with
every non-alphanumeric character replaced by `-`. This plugin **derives that same
slug at runtime** from the launch directory. Result:

- A **direct** `claude` session inside `master/<project>` auto-recalls that memory.
- A **delegated** agent spawned from the master computes the identical slug and
  reads/writes the same directory.

Both routes converge on one memory store, so work is shared and auto-resumes — with
no hardcoded prefix and no configuration.

## Install

```
/plugin marketplace add <your-github-user>/claude-project-hub
/plugin install project-hub@project-hub
```

Then `cd` into any directory whose subdirectories are your projects, launch Claude,
and run `/projects`.

## Optional: master instructions

Copy `CLAUDE.md.template` from this repo into your master directory as `CLAUDE.md`
if you want the full delegation model documented for the session. The plugin works
without it — the `/projects` command is self-contained.

## Requirements

- Claude Code with plugin support.
- **Warp** terminal for the live agent-watcher tabs (the `open warp://launch/...`
  path). Everything else works in any terminal; without Warp, skip the watcher.
- `python3` for the stream formatter and transcript distiller.

## Config knobs (env vars, all optional)

- `HUB_ROOT` — override the master directory (defaults to `$PWD`).
- `CLAUDE_PROJECTS_DIR` — override where Claude stores project memory
  (defaults to `~/.claude/projects`).

## Scripts

- `scripts/hub-lib.sh` — shared slug/path derivation (sourced by the others).
- `scripts/project-memory.sh` — list projects, or resolve names to workdir+memory.
- `scripts/discover-projects.sh` — list projects that have prior Claude history.
- `scripts/watch-agent.sh` — open a Warp tab streaming a spawned agent's activity.
- `scripts/format-agent-stream.py` — the stream renderer (runs in the watcher tab).
- `scripts/distill-transcript.py` — mine a `.jsonl` transcript into a compact digest.
