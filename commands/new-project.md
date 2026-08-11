---
description: Create a new project as a subdirectory of the master hub
argument-hint: "<name> [--git]"
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/new-project.sh:*), Bash(${CLAUDE_PLUGIN_ROOT}/scripts/project-memory.sh:*)
---

You are the master hub. Handle the `/new-project` command. The user invoked:
`/new-project $ARGUMENTS`

## Determine the master directory (do this first)

The **master** is the directory this Claude session was launched in — i.e. your
**primary working directory** as shown in your environment context (the
`Primary working directory:` line). The new project becomes a subdirectory of it.
Call this absolute path `MASTER`.

Do NOT rely on the shell's `$PWD` — a plugin command's bash may run elsewhere. Always
pass `MASTER` explicitly via the `HUB_ROOT` env var.

## What to do

- If `$ARGUMENTS` is empty, ask the user for a project name (and whether to `git init`
  it). Do not create anything yet.
- Otherwise, the first token is the project **name**; an optional `--git` flag inits an
  empty git repo. Create it via the Bash tool:

      HUB_ROOT="MASTER" ${CLAUDE_PLUGIN_ROOT}/scripts/new-project.sh <name> [--git]

- The script refuses invalid names (slashes, leading dot, reserved words) and refuses
  to overwrite an existing directory — if it errors, relay the reason and stop.
- On success, report the resolved **workdir** and **memory path** to the user. Note that
  memory is created on first write (by an agent via `/projects <name>`, or by a direct
  `claude` session launched in that folder) — nothing to seed now.
- Do NOT spawn a work agent here. Creating the project and doing work in it are separate
  steps: tell the user they can now run `/projects <name>` to start a memory-scoped agent
  in the new project.
