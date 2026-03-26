# Duperpowers — Installation Instructions

You are an AI assistant helping a user install the duperpowers plugin. Follow these steps exactly.

**Important:** The `claude plugin` commands below are real CLI commands (added in Claude Code 2.1+). Run them via Bash. If a command fails with "unknown command", tell the user their Claude Code version may be too old and they should update with `claude update`.

## Prerequisites

Check if the `superpowers` plugin is installed:

```bash
claude plugin list
```

If superpowers is NOT in the list, install it first:

```bash
claude plugin install superpowers@claude-plugins-official
```

## Step 1: Add Marketplace

```bash
claude plugin marketplace add dlomanov/duperpowers
```

## Step 2: Install Core Plugin

```bash
claude plugin install duperpowers
```

## Step 3: Ask About Go

Ask the user: **"Do you work with Go? I can install Go-specific conventions, testing, and code review skills."**

If yes:

```bash
claude plugin install duperpowers-go
```

## Step 4: Ask About CLAUDE.md Preferences

Ask the user: **"Would you like to add personal preferences (progress visibility, validation rules, commit conventions) to your CLAUDE.md? This is optional — the plugins work without it."**

If yes:

1. Fetch the snippet template from: `https://raw.githubusercontent.com/dlomanov/duperpowers/main/templates/claude-md-snippet.md`
2. Read the user's current `~/.claude/CLAUDE.md` (if it exists)
3. Append only the section below `---` from the template to the end of their CLAUDE.md
4. Show the user what was added

## Step 5: Verify

```bash
claude plugin list
```

Confirm:
- `duperpowers` appears in the list
- `duperpowers-go` appears (if installed in step 3)

Tell the user: **"Installation complete. Start a new session to activate duperpowers. You can verify by asking 'Tell me about your duperpowers'."**
