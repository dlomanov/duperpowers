# Duperpowers — Installation Instructions

You are an AI assistant helping a user install the duperpowers plugin. Follow these steps exactly.

**Idempotency:** This installer is safe to run multiple times. Already-installed plugins are checked for updates. Existing CLAUDE.md sections are never duplicated. Standalone skill files require user approval before overwriting.

| Rationalization | Reality |
|----------------|---------|
| "Plugin is already installed, nothing to do" | Check for updates. Installed ≠ up to date |
| "User probably doesn't need standalone skills, I'll skip" | ALWAYS ask. Never skip optional steps — let the user decide |
| "The command failed but I can work around it" | STOP and report the error. User decides next step |
| "CLAUDE.md section looks similar, I'll overwrite it" | Check for exact heading match. Never duplicate |

## Platform Detection

Determine your platform:
- **Claude Code** — you have the `Bash` tool and can run `claude plugin` CLI commands
- **Cursor** — you have terminal access and the `/add-plugin` command

If unsure, ask the user: **"Are you using Claude Code or Cursor?"**

Follow the section matching your platform below. After installing plugins, both platforms share the same CLAUDE.md and standalone skills steps.

---

# Claude Code

**Important:** The `claude plugin` commands below are real CLI commands (added in Claude Code 2.1+). Run them via Bash. If a command fails with "unknown command", STOP and tell the user their Claude Code version may be too old — they should update with `claude update`.

## Prerequisites

```bash
claude plugin list
```

Check the output. Install only what is missing:

- If `superpowers` is NOT in the list:
```bash
claude plugin install superpowers@claude-plugins-official
```

- Add the marketplace (safe to run if already added):
```bash
claude plugin marketplace add dlomanov/duperpowers
```

## Step 1: Install or Update Core Plugin

Check `claude plugin list` output for `duperpowers`:
- **Not installed** → install:
```bash
claude plugin install duperpowers
```
- **Already installed** → reinstall to pick up latest version:
```bash
claude plugin install duperpowers
```
Report to the user what version was installed.

## Step 2: Ask About Go

Ask the user: **"Do you work with Go? I can install Go-specific conventions, testing, and code review skills."**

If yes, check `claude plugin list` output for `duperpowers-go`:
- **Not installed** → install:
```bash
claude plugin install duperpowers-go
```
- **Already installed** → reinstall to pick up latest version:
```bash
claude plugin install duperpowers-go
```
Report to the user what version was installed.

Also check if `gopls-lsp` is installed (Go language intelligence). If NOT in the list:

```bash
claude plugin install gopls-lsp@claude-plugins-official
```

Now proceed to **Common Steps** below.

---

# Cursor

## Prerequisites

Check if superpowers is installed. If not:

```
/add-plugin superpowers
```

## Step 1: Install Core Plugin

Check if duperpowers is installed. If not:

```
/add-plugin duperpowers
```

If already installed, check if an update is available and offer to update.

## Step 2: Ask About Go

Ask the user: **"Do you work with Go? I can install Go-specific conventions, testing, and code review skills."**

If yes, and duperpowers-go is NOT already installed:

```
/add-plugin duperpowers-go
```

If already installed, offer to reinstall for the latest version.

Now proceed to **Common Steps** below.

**Note:** Cursor does not have marketplace or gopls-lsp support. Anchor rules, preferences, and standalone skills are handled in Common Steps.

---

# Common Steps

These steps are the same for Claude Code and Cursor.

## Step 3: Ask About Anchor Rules

Ask the user: **"Would you like to add duperpowers anchor rules to your CLAUDE.md? This ensures Claude always invokes the right skills for Go code, reviews, and planning. Recommended."**

If yes:

1. Read the user's current `~/.claude/CLAUDE.md` (if it exists)
2. Check if `## Duperpowers — Anchor Rules` section already exists. **If it does — skip, tell the user it's already there.**
3. Insert the following block BEFORE the first line that consists solely of `@<filename>.md` (e.g. `@RTK.md`). If no such lines exist, append to the end. Ensure a blank line before and after the inserted block:

```markdown
## Duperpowers — Anchor Rules

- Go implementation → MUST invoke `duperpowers-go:go-writer` + `duperpowers-go:go-writer-test`
- Go code review → MUST invoke `duperpowers-go:go-reviewer`
- Any superpowers skill loads → MUST invoke `duperpowers:superpowers-overrides`
- Multi-step implementation → MUST invoke `duperpowers:plan-orchestrator`
- Model heuristic: think = opus, do = sonnet. Mixing in one step is an anti-pattern
- STOP and report BLOCKED after 3 failed attempts
```

4. Show the user what was added

**Note:** If duperpowers-go was NOT installed in step 2, omit lines containing `duperpowers-go:` from the block above.

## Step 4: Ask About CLAUDE.md Preferences

Ask the user: **"Would you like to add personal preferences to your CLAUDE.md? This is the author's template — review and adapt to your workflow. Not recommended for most users, but available if you want a starting point."**

If yes:

1. Fetch the snippet template from: `https://raw.githubusercontent.com/dlomanov/duperpowers/main/templates/claude-md-snippet.md`
2. Read the user's current `~/.claude/CLAUDE.md` (if it exists)
3. Check if `## Duperpowers — Personal Preferences` section already exists. **If it does — skip, tell the user it's already there.**
4. Insert only the section below `---` from the template BEFORE the first line that consists solely of `@<filename>.md`. If no such lines exist, append to the end. Ensure a blank line before and after the inserted block
5. Show the user what was added

## Step 5: Ask About Standalone Skills

Ask the user: **"Would you like to install any standalone skills? These are not part of the plugins — they install as local skill files."**

Present the list:

| Skill | Purpose | Scope |
|-------|---------|-------|
| `project-commands` | Make targets, test commands, go doc protocol — template to adapt per project | project or user |
| `prompt-engineering-rules` | Reference for writing CLAUDE.md, SKILL.md, AI instruction files | project or user |

For each skill the user wants, ask: **"Install as project-level (current repo only) or user-level (all repos)?"**

**Before installing, check if the SKILL.md already exists at the target path.** If it does, ask: **"[skill] is already installed at [path]. Overwrite with the latest version? Your customizations will be lost."** Only overwrite if user confirms.

Then fetch and install:

- **project-commands** (project-level):
```bash
mkdir -p .claude/skills/project-commands
```
Fetch `https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/project-commands/SKILL.md` and write to `.claude/skills/project-commands/SKILL.md`.

- **project-commands** (user-level):
```bash
mkdir -p ~/.claude/skills/project-commands
```
Fetch same URL, write to `~/.claude/skills/project-commands/SKILL.md`.

- **prompt-engineering-rules** (project-level):
```bash
mkdir -p .claude/skills/prompt-engineering-rules
```
Fetch `https://raw.githubusercontent.com/dlomanov/duperpowers/main/standalone/prompt-engineering-rules/SKILL.md` and write to `.claude/skills/prompt-engineering-rules/SKILL.md`.

- **prompt-engineering-rules** (user-level):
```bash
mkdir -p ~/.claude/skills/prompt-engineering-rules
```
Fetch same URL, write to `~/.claude/skills/prompt-engineering-rules/SKILL.md`.

Tell the user: **"project-commands is a template — edit it to match your project's actual Makefile targets."**

## Step 6: Verify

Run through each check and report results to the user:

**Plugins:**
- [ ] `superpowers` is installed
- [ ] `duperpowers` is installed
- [ ] `duperpowers-go` is installed (if chosen in step 2)
- [ ] `gopls-lsp` is installed (Claude Code only, if Go was chosen)

**CLAUDE.md** (if steps 3-4 were done):
- [ ] `## Duperpowers — Anchor Rules` section exists in `~/.claude/CLAUDE.md`
- [ ] `## Duperpowers — Personal Preferences` section exists in `~/.claude/CLAUDE.md`
- [ ] Sections are placed BEFORE `@<filename>.md` import lines (if any)

**Standalone skills** (if step 5 was done):
- [ ] SKILL.md exists at each chosen path

Report the checklist with pass/fail for each item. If anything failed, offer to fix it.

Tell the user: **"Installation complete. Start a new session to activate duperpowers. You can verify by asking 'Tell me about your duperpowers'."**
