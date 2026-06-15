---
name: session-state
description: Per-session key/value store (kv.sh) - counters and flags in ~/.claude/session_state/*.state.
dependencies: []
platform: [all]
provides:
  scripts: [kv.sh]
---

# session-state

A tiny, dependency-free per-session key/value store. One TAB-delimited `.state` file
per session under `~/.claude/session_state/`. Single writer per session, atomic
temp+mv writes. This is the base primitive other features build on (e.g. `context`
uses it for a turn counter).

## Install / update / remove

Follow the generic protocol in the repo-root `INSTALL.md`. Summary for this feature:

- **provides** only `scripts/kv.sh` → symlinked to `~/.claude/scripts/kv.sh`.
- No skills, no agents, no hooks, no dependencies - nothing to wire, no dispatcher needed.
- **installed?** `~/.claude/features/session-state` exists.

## Verify after install

```sh
bash ~/.claude/features/session-state/scripts/test_kv.sh   # expect: Results: 17 passed, 0 failed
```

`test_kv.sh` ships in the feature dir for verification; it is not linked into `~/.claude`.

## API (kv.sh)

```
kv.sh --file <path.state> get  <key>
kv.sh --file <path.state> set  <key> <value>      # value must not contain TAB/newline
kv.sh --file <path.state> del  <key>
kv.sh --file <path.state> incr <key>              # integer counter; self-heals non-int to 0
```
