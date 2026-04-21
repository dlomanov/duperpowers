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
| "Smoke test is optional, skip it" | Run it unconditionally — verifies the whole chain |

## Step 0: Platform and prerequisites

### Step 0.1: Network reachability to GitHub raw

```bash
curl -fsI --max-time 10 https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/spawn-worker/INSTALL.md >/dev/null 2>&1 && echo "github-raw-ok" || echo "github-raw-unreachable"
```

If `github-raw-unreachable` → STOP. Tell the user: "Cannot reach raw.githubusercontent.com. If on a corporate network, set HTTPS_PROXY and/or NODE_EXTRA_CA_CERTS, then re-run. If at home, check your connection."

### Step 0.2: ~/bin writability

```bash
mkdir -p ~/bin && touch ~/bin/.spawn-worker-writable-test && rm ~/bin/.spawn-worker-writable-test && echo "bin-writable-ok" || echo "bin-not-writable"
```

If `bin-not-writable` → STOP. Tell the user: "~/bin is not writable. If this is an MDM-managed work mac, ask IT to allow user-scope writes to ~/bin, or choose an alternative BIN_DIR and re-run (edit INSTALL.md locally)."

### Step 0.3: macOS Automation permissions for Ghostty

The first time osascript sends commands to Ghostty, macOS shows a privacy dialog. Trigger it now so the user can approve before the smoke test silently fails.

```bash
osascript -e 'tell application "Ghostty" to activate' 2>&1
```

If the agent running this is itself automated (no human to click), flag: "macOS may show an Automation permissions dialog. User must approve it for the smoke test to work. Re-run INSTALL once approved."

Run all remaining checks in parallel, report all failures before stopping:

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

**Before overwriting any file that already exists**, compare against upstream with an explicit diff. If unchanged, skip silently. If different AND a local-edit marker exists (see checksum sidecar below), ask the user. If different AND no local-edit marker, overwrite silently (it's an upstream update).

For each file, run:

```bash
curl -fsSL <url> -o ~/src/sand/docs/.spawn-worker-upstream
if cmp -s ~/src/sand/docs/.spawn-worker-upstream <local-path>; then
  echo "already up to date: <local-path>"
elif [ -f <local-path>.installed-sha ] && [ "$(shasum -a 256 <local-path> | cut -d' ' -f1)" != "$(cat <local-path>.installed-sha)" ]; then
  # Local modifications detected — ask user
  diff <local-path> ~/src/sand/docs/.spawn-worker-upstream | head -50
  # Ask: "Local modifications to <local-path>. Overwrite with upstream version?"
else
  cp ~/src/sand/docs/.spawn-worker-upstream <local-path>
  shasum -a 256 <local-path> | cut -d' ' -f1 > <local-path>.installed-sha
fi
rm -f ~/src/sand/docs/.spawn-worker-upstream
```

Replace `<url>` and `<local-path>` per file as listed in the numbered list below.

Files to install:

1. `~/bin/cc-run-worker` ← `https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/spawn-worker/cc-run-worker`
2. `~/bin/spawn-cc-worker` ← `https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/spawn-worker/spawn-cc-worker`
3. `~/.claude/skills/spawn-worker/SKILL.md` ← `https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/spawn-worker/SKILL.md`

After copying, the `.installed-sha` sidecars will be at:
- `~/bin/cc-run-worker.installed-sha`
- `~/bin/spawn-cc-worker.installed-sha`
- `~/.claude/skills/spawn-worker/SKILL.md.installed-sha`

These let re-runs tell apart upstream updates from local edits.

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

## Step 4: Smoke test

Run an automated smoke test that verifies the full chain end-to-end without user inspection.

Prepare the prompt and clear any prior sentinel:

```bash
mkdir -p ~/src/sand/docs/prompts
rm -f ~/src/sand/docs/spawn-worker-smoke.ok
cat > ~/src/sand/docs/prompts/smoke-test.md <<'SMOKE'
You are the spawn-worker smoke test. Execute these steps exactly:
1. Use Bash to run: touch ~/src/sand/docs/spawn-worker-smoke.ok
2. Reply with one line: "smoke test ok"
3. Stop. Wait for /exit.
SMOKE
~/bin/spawn-cc-worker smoke ~/src/sand/docs/prompts/smoke-test.md "$HOME" smoke-test
```

Then wait up to 30 seconds for the sentinel file:

```bash
for i in $(seq 1 30); do
  if [ -f ~/src/sand/docs/spawn-worker-smoke.ok ]; then
    echo "smoke test PASSED"
    rm ~/src/sand/docs/spawn-worker-smoke.ok
    break
  fi
  sleep 1
done
if [ ! -f ~/src/sand/docs/spawn-worker-smoke.ok ] && [ "$i" = "30" ]; then
  echo "smoke test FAILED: sentinel file did not appear within 30s"
fi
```

Interpret results:
- **PASSED** → the full chain works. Tell the user: "Smoke test passed. Close the 'smoke-test' Ghostty tab at your convenience."
- **FAILED** → STOP. Tell the user: "Smoke test failed — sentinel file did not appear. Check the Ghostty tab for error output. See Troubleshooting below."

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
