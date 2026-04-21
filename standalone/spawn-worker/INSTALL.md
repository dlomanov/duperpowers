# spawn-worker — Installation Instructions

You are an AI assistant helping a user install `spawn-worker` on their machine. Follow these steps exactly.

**What this installs:** a tool that lets a Claude Code (main) session spawn parallel worker Claude Code sessions in new Ghostty terminal tabs with a pre-filled prompt. Useful when the current session can't dispatch subagents itself, or when you want true parallel execution across separate sessions.

**What gets installed:**
- `~/bin/cc-run-worker` — zsh wrapper that launches `claude` with a pre-filled prompt
- `~/bin/spawn-cc-worker` — opens a new Ghostty tab and runs the wrapper
- `~/.claude/skills/spawn-worker/SKILL.md` — skill instructions for main Claude sessions
- `~/src/sand/docs/prompts/` — empty directory for worker prompts

**Idempotency:** Re-running overwrites the three files. Ask the user before overwriting if customized content is detected.

| Rationalization | Reality |
|----------------|---------|
| "The user probably already has it, skip" | Check each file; overwrite only what's stale |
| "Ghostty works on Linux too, no platform check needed" | The install uses macOS AppleScript. Non-macOS MUST stop |
| "Curl failed but I'll try again with a different URL" | STOP. Report the error. Do not guess alternative URLs |
| "Smoke test is optional, skip it" | Run it unless user declines — verifies the whole chain |

## Step 0: Platform and prerequisites

Run all checks in parallel, report all failures before stopping:

```bash
uname -s                                 # must be "Darwin" (macOS)
test -d /Applications/Ghostty.app && echo "ghostty-ok" || echo "ghostty-missing"
command -v claude >/dev/null 2>&1 && echo "claude-ok" || echo "claude-missing-in-path"
/bin/zsh -ic 'command -v claude >/dev/null 2>&1 && echo claude-ok-via-zsh || echo claude-missing-via-zsh'
echo "$SHELL"                            # should contain "zsh"
```

Decision logic:
- If `uname -s` is not `Darwin` → **STOP.** Tell the user: "spawn-worker requires macOS (uses AppleScript for Ghostty control). This machine is not supported."
- If Ghostty is missing → **STOP.** Tell the user: "Install Ghostty from https://ghostty.org/ first, then re-run."
- If claude is missing from both direct PATH and zsh-via-`-ic` → **STOP.** Tell the user: "Claude CLI not found. Install Claude Code first: https://docs.anthropic.com/claude-code"
- If claude is missing from direct PATH but works via zsh-ic → OK (there's a zsh alias, that's the supported setup).
- If `$SHELL` is not zsh → **WARN** but continue. Tell the user: "spawn-worker's wrapper uses `/bin/zsh -ic`. Should still work, but your zshrc aliases will be loaded regardless of your default shell."

## Step 1: Create directories

```bash
mkdir -p ~/bin ~/.claude/skills/spawn-worker ~/src/sand/docs/prompts
```

## Step 2: Download and install files

Use `curl` or the WebFetch tool to fetch each file from the repo, write to disk. All three files are at `https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/spawn-worker/`.

**Before overwriting any file that already exists**, diff the existing version against the upstream. If they match exactly, skip (print "already up to date"). If they differ, show the diff and ask: **"File exists and differs from upstream. Overwrite? (your local changes will be lost)"** Only overwrite if the user confirms.

Files to install:

1. `~/bin/cc-run-worker` ← `https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/spawn-worker/cc-run-worker`
2. `~/bin/spawn-cc-worker` ← `https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/spawn-worker/spawn-cc-worker`
3. `~/.claude/skills/spawn-worker/SKILL.md` ← `https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/spawn-worker/SKILL.md`

Then make the scripts executable:

```bash
chmod +x ~/bin/cc-run-worker ~/bin/spawn-cc-worker
```

## Step 3: Verify install

Run these checks and report each pass/fail:

```bash
test -x ~/bin/cc-run-worker && echo "cc-run-worker ok"
test -x ~/bin/spawn-cc-worker && echo "spawn-cc-worker ok"
test -f ~/.claude/skills/spawn-worker/SKILL.md && echo "SKILL.md ok"
test -d ~/src/sand/docs/prompts && echo "prompts dir ok"
head -1 ~/bin/cc-run-worker | grep -q bash && echo "shebang ok"
```

If any check fails, STOP and show the user what's wrong.

## Step 4: Smoke test (optional)

Ask the user: **"Run a smoke test? It opens a new Ghostty tab and spawns a tiny worker that replies with 'banana'. Takes ~5 seconds."**

If yes:

```bash
echo 'Reply with exactly one word: banana. Then stop and wait for /exit.' > /tmp/spawn-worker-smoke.md
~/bin/spawn-cc-worker smoke /tmp/spawn-worker-smoke.md "$PWD" smoke-test
```

Tell the user: **"Check the new Ghostty tab titled 'smoke-test'. The worker should reply 'banana'. Close the tab when done."**

Do NOT auto-verify the tab content — there's no programmatic way to read the worker's reply without reading its transcript file. The user visually confirms.

## Step 5: Report done

Tell the user:

> Installed. To use from a main Claude session: say "spawn a worker to do X". The `spawn-worker` skill will be invoked automatically.
>
> To use manually: `~/bin/spawn-cc-worker <worker-id> <prompt-file> [cwd] [name]`
>
> Prompt files live in `~/src/sand/docs/prompts/`. Worker transcripts live in `~/.claude/projects/<project-slug>/<session-id>.jsonl`.

## Troubleshooting

If the user reports the smoke test failed:

- **"command not found: claude"** in the spawned tab → zshrc alias didn't load. Ask the user to verify: `zsh -ic 'command -v claude'`. If empty, the alias is wrong or not in `~/.zshrc`.
- **No new tab opens** → Ghostty might not be running. Try launching Ghostty.app manually first, then re-spawn.
- **Permission denied on osascript** → macOS Automation privacy. System Settings → Privacy & Security → Automation → Terminal/iTerm → allow Ghostty.
- **Tab opens but prompt isn't submitted** → claude CLI version might not support positional prompt auto-submit. Ask: `claude --version`. File an issue upstream if below expected version.
