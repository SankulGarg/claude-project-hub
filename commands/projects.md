---
description: List projects, or start a subagent scoped to one or two projects' memory
argument-hint: "[project] [project2]  (no args = list all)"
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/project-memory.sh:*), Bash(${CLAUDE_PLUGIN_ROOT}/scripts/watch-agent.sh:*), Agent, Read
---

You are the master hub. Handle the `/projects` command. The user invoked:
`/projects $ARGUMENTS`

## Determine the master directory (do this first)

The **master** is the directory this Claude session was launched in — i.e. your
**primary working directory** as shown in your environment context (the
`Primary working directory:` line). Its subdirectories are the projects. Call this
absolute path `MASTER`.

Do NOT rely on the shell's `$PWD` — a plugin command's bash may run elsewhere. Always
pass `MASTER` explicitly via the `HUB_ROOT` env var when invoking the scripts below.

## Get the live inventory

Run this via the Bash tool (substitute the real absolute path for `MASTER`):

    HUB_ROOT="MASTER" ${CLAUDE_PLUGIN_ROOT}/scripts/project-memory.sh $ARGUMENTS

- No args → it prints the full project list (SESSIONS / MEMORY columns).
- One or two names → it resolves each to its workdir + canonical memory path.

If the output lists only plugin internals (e.g. a lone `commands` row), you used the
wrong `HUB_ROOT` — re-run with your real primary working directory.

## What to do

**If `$ARGUMENTS` is empty** (list mode):
- Present the projects as a readable menu. Highlight which already have memory
  (MEMORY = yes) vs. those with none yet.
- Tell the user they can run `/projects <name>` for one project, or
  `/projects <name> <name2>` to start a subagent with access to BOTH projects' memory.
- Do NOT spawn any agent yet.

**If `$ARGUMENTS` names one or two projects** (use the resolved workdir + memory paths):
- Ask the user what task they want done (if they haven't said in this turn),
  UNLESS the task is already clear from context — then proceed.
- Spawn ONE `general-purpose` subagent. Its prompt MUST:
  - Pin its working directory to the project's workdir (from the resolved output).
  - List each project's workdir and canonical memory path (from the resolved output).
  - Instruct it FIRST to read every project's `MEMORY.md` + all files in each memory
    dir — that is its prior context. Do not skip it.
  - State the task.
  - For a SINGLE project: instruct it to write durable findings back to THAT project's
    memory dir and update that dir's `MEMORY.md` (one line per file). Write memory
    NOWHERE else.
  - For TWO projects: it may READ both memories, but must write new memory only to the
    project the finding belongs to (never mix a finding into the wrong project's memory).
    If a finding is genuinely cross-project, note it in the master memory (the
    `master_mem` path — run `${CLAUDE_PLUGIN_ROOT}/scripts/project-memory.sh` logic, or
    `~/.claude/projects/<dashified-MASTER>/memory`).
  - Ask for a concise self-contained report (done / changed / learned / open items).
- **Spawn the agent in the background** (run_in_background) so you get its `output_file` path.
- **Immediately open a watcher tab** for it (Warp), passing the same `HUB_ROOT`:
  `HUB_ROOT="MASTER" ${CLAUDE_PLUGIN_ROOT}/scripts/watch-agent.sh "<output_file>" "<label>"`
  where `<output_file>` is the path from the Agent tool result and `<label>` is
  `"<project> / <short task>"` (two projects: `"<a>+<b> / <short task>"`).
  Do this once per spawned agent.
- After it returns, relay a summary to the user (its full output is not shown to them).

If any named project showed a WARN (no working dir), surface that to the user before
spawning.
