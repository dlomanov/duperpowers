---
name: spawn-worker
description: Spawn a parallel Claude Code worker session in a new Ghostty tab with a pre-filled prompt. Use when the current (main) session needs to delegate a self-contained subtask — especially when the current Claude cannot dispatch subagents itself, or when parallel execution is desired. Supports nesting (a worker can invoke this skill to spawn sub-workers).
---

# Spawn Worker

Delegate a subtask to a fresh Claude Code session running in a new Ghostty tab.
Prompt is pre-filled and auto-submitted on launch.

## When to use

- Main session planned work that can run in parallel
- Current session can't spawn internal subagents and needs a true separate session
- Want a fresh context window for a large self-contained subtask

## How to use

1. Pick a unique worker-id for this conversation: `w1`, `w2`, `w3`, ...
   (Increment per spawn within the current turn. No persistent counter needed —
   uniqueness only matters while workers are alive.)

2. Write the worker's prompt to `~/src/sand/docs/prompts/<worker-id>.md`.
   The prompt must be **self-contained** — the worker sees zero main context.
   Include: goal, relevant context pasted in, output location, finishing
   discipline ("when done, output a short summary and wait for user to /exit").

3. Spawn via Bash:
   ```
   ~/bin/spawn-cc-worker <worker-id> ~/src/sand/docs/prompts/<worker-id>.md [cwd] [name]
   ```
   - `cwd` defaults to main's current working directory. Pass an explicit cwd
     when the worker should operate on a different project.
   - `name` is a short human-readable label shown in the Ghostty tab title and
     the `/resume` picker. Defaults to `<worker-id>`. Pick something descriptive
     (e.g., `refactor-auth`, `research-pg-indexes`) so you can identify tabs
     at a glance.

4. Tell the user: "Worker `<id>` spawned in a new Ghostty tab. Let me know when
   it finishes and I'll read the result."

5. When user signals completion: read the worker's transcript from
   `~/.claude/projects/<project-slug>/<session-id>.jsonl`. Find it with
   `ls -t ~/.claude/projects/ | head` to get the right project dir, then
   `ls -t ~/.claude/projects/<dir>/*.jsonl | head -1` for the newest session.
   Extract the final assistant message for the answer.

## Nesting

A worker inherits this skill. If a worker needs to delegate further, it
invokes `spawn-worker` with its own worker-ids (e.g., `w1-a`, `w1-b`) and
writes its children's prompts to `~/src/sand/docs/prompts/`. All transcripts
live in `~/.claude/projects/` as usual.

## Limits (MVP)

- No push notification when a worker finishes — user signals completion verbally
- No automated result extraction — main reads the transcript file on demand
- No worker lifecycle management — if worker fails or hangs, user closes the tab
- No session-id tracking — main finds the transcript by recency
